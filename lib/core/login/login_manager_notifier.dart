// lib/core/login/login_manager_notifier.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:rostov_vpn/core/login/login_state.dart';
import 'package:rostov_vpn/core/model/environment.dart';
import 'package:rostov_vpn/features/profile/data/profile_repository.dart';
import 'package:rostov_vpn/features/profile/model/profile_entity.dart';
import 'package:uuid/uuid.dart';

class LoginManagerNotifier extends StateNotifier<LoginState?> {
  final ProfileRepository _profileRepo;
  LoginManagerNotifier(this._profileRepo) : super(null);

  Future<void> init() async {
    // читаем файл
    final loaded = await _loadLoginStateFromFile();
    state = loaded;
  }

  bool get isLoggedIn => state?.isLoggedIn ?? false;
  String get username => state?.username ?? 'войдите';

  Future<File> _getLoginFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/loginState.json');
  }

  Future<LoginState?> _loadLoginStateFromFile() async {
    try {
      final file = await _getLoginFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        return LoginState.fromJsonString(content);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка чтения loginState.json: $e');
      }
    }
    return null;
  }

  Future<void> _saveLoginStateToFile(LoginState newState) async {
    try {
      final file = await _getLoginFile();
      await file.writeAsString(newState.toJsonString());
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка записи loginState.json: $e');
      }
    }
  }

  Future<void> _clearLoginStateFile() async {
    try {
      final file = await _getLoginFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка удаления loginState.json: $e');
      }
    }
  }

  Future<bool> login(String username, String password) async {
    // Ставим isLoading = true
    final old = state;
    state = (old == null)
        ? LoginState(username: '', isLoggedIn: false, isLoading: true)
        : old.copyWith(isLoading: true);

    try {
      final user = await _authenticateWithRetry(username, password);

      // Пока что не сбрасываем isLoading, пусть оно остаётся true,
      // пока мы не закончим логику добавления профиля.
      // Создадим промежуточное состояние (без изменения isLoading).
      final newState = LoginState(
        username: user.username,
        isLoggedIn: true,
        subscriptionLink: user.subscriptionLink,
        dataExpire: user.dataExpire?.toIso8601String(),
        isLoading: true, // <-- оставим true
      );
      state = newState;
      await _saveLoginStateToFile(newState);

      // Если есть subscriptionLink => добавляем профиль
      if (user.subscriptionLink != null && user.subscriptionLink!.isNotEmpty) {
        final newProfile = RemoteProfileEntity(
          id: const Uuid().v4(),
          active: true,
          name: 'my',
          url: user.subscriptionLink!,
          lastUpdate: DateTime.now(),
        );
        final failureOrSuccess = await _profileRepo.add(newProfile).run();
        if (failureOrSuccess.isLeft()) {
          if (kDebugMode) {
            print('Ошибка при добавлении профиля: ${failureOrSuccess.swap()}');
          }
          return false;
        } else {
          if (kDebugMode) {
            print('Профиль добавлен');
          }
        }
      }

      // Вот теперь, когда всё завершилось, сбрасываем isLoading => false
      final finalState = state?.copyWith(isLoading: false);
      state = finalState;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Login failed: $e');
      }
      return false;
    } finally {
      // Если хотите, можно не трогать `finally`,
      // либо оставить на всякий случай «защиту»:
      state = state?.copyWith(isLoading: false);
    }
  }

  Future<void> logout() async {
    state = null; // сбрасываем
    final failureOrSuccess = await _profileRepo.deleteAll().run();
    if (failureOrSuccess.isLeft()) {
      if (kDebugMode) {
        print('Ошибка при удалении всех профилей: ${failureOrSuccess.swap()}');
      }
    }
    await _clearLoginStateFile();
  }

  Future<ServerUser> _authenticateUserFromServer(
    String username,
    String plainPassword,
  ) async {
    const apiUrl = Environment.apiUrl;

    final url = Uri.parse(
      '$apiUrl?filters[username][\$eq]=$username',
    );
    const token = Environment.apiToken;

    http.Response response;
    try {
      // таймаут 10 сек
      response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
    } on SocketException catch (_) {
      throw LoginException(
        'Нет сети или сервер недоступен',
        type: LoginExceptionType.connectionError,
      );
    } on http.ClientException catch (_) {
      throw LoginException(
        'Ошибка HTTP-клиента',
        type: LoginExceptionType.connectionError,
      );
    } on TimeoutException catch (_) {
      throw LoginException(
        'Превышен таймаут ожидания',
        type: LoginExceptionType.connectionError,
      );
    } catch (e) {
      throw LoginException(
        'Неизвестная ошибка при запросе: $e',
        type: LoginExceptionType.unknown,
      );
    }

    if (response.statusCode == 401) {
      // Например, токен недействителен
      throw LoginException('Unauthorized',
          type: LoginExceptionType.unauthorized);
    } else if (response.statusCode >= 400 && response.statusCode < 600) {
      throw LoginException(
        'Сервер вернул ошибку [${response.statusCode}]',
        type: LoginExceptionType.serverError,
      );
    }

    // Теперь предполагаем, что statusCode == 200
    // Парсим тело
    Map<String, dynamic> jsonBody;
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw LoginException(
        'Некорректный формат (ожидался объект)',
        type: LoginExceptionType.serverError,
      );
    }
    jsonBody = data;

// Предположим, сервер кладёт массив юзеров в "Data"
    final dataField = jsonBody["data"];
    if (dataField is! List) {
      throw LoginException(
        'Пользователь $username не найден (Data отсутствует или не является списком)',
        type: LoginExceptionType.userNotFound,
      );
    }

    final List dataList = dataField;
    if (dataList.isEmpty) {
      throw LoginException(
        'Пользователь $username не найден (Data пустой)',
        type: LoginExceptionType.userNotFound,
      );
    }
    final firstObj = jsonBody["data"][0];
    if (firstObj["attributes"] == null) {
      throw LoginException(
        'Нет поля Attributes',
        type: LoginExceptionType.serverError,
      );
    }

    final userAttr = firstObj["attributes"] as Map<String, dynamic>;
    final serverUsername = userAttr["username"] as String?;
    final hashedPassword = userAttr["password"] as String?;
    final subscriptionLink = userAttr["subscription_link"] as String?;
    final dataExpireStr = userAttr["data_expire"];

    if (serverUsername == null || hashedPassword == null) {
      throw LoginException(
        'Пользователь или пароль не указаны на сервере',
        type: LoginExceptionType.serverError,
      );
    }

    // Сверяем bcrypt
    final passwordOk = BCrypt.checkpw(plainPassword, hashedPassword);
    if (!passwordOk) {
      throw LoginException(
        'Неверный пароль',
        type: LoginExceptionType.invalidCredentials,
      );
    }

    // Парсим дату (если она не null)
    DateTime? expireDate;
    if (dataExpireStr != null) {
      if (dataExpireStr is String && dataExpireStr.isNotEmpty) {
        expireDate = DateTime.tryParse(dataExpireStr);
        // Если не смогли распарсить, можно оставить null
      }
    }

    // Возвращаем ServerUser
    return ServerUser(
      username: serverUsername,
      subscriptionLink: subscriptionLink,
      dataExpire: expireDate,
    );
  }

  /// Refreshes subscriptions and dataExpire on app startup.
  /// - Always fetches latest data_expire from server and stores it in LoginState
  /// - Tries to update remote subscription profile content (profile named 'my')
  Future<void> refreshOnStartup() async {
    final current = state;
    if (current == null || !current.isLoggedIn) return;

    // Update dataExpire regardless of lastCheckTime
    try {
      final updatedExpire =
          await _fetchLatestDataExpireFromServer(current.username);
      if (updatedExpire != null) {
        final updatedState = current.copyWith(
          dataExpire: updatedExpire == "null" ? "null" : updatedExpire,
          overrideDataExpire: true,
          lastCheckTime: DateTime.now().toIso8601String(),
        );
        state = updatedState;
        await _saveLoginStateToFile(updatedState);
      }
    } catch (_) {}

    // Update subscription profile if exists
    try {
      if (state?.subscriptionLink?.isNotEmpty == true) {
        final existing = await _profileRepo.getByName('my');
        if (existing is RemoteProfileEntity) {
          // Обновляем URL и качаем свежий профиль
          await _profileRepo
              .updateSubscription(
                existing.copyWith(url: state!.subscriptionLink!),
                patchBaseProfile: true,
              )
              .run();
        } else {
          // Создаём новый удалённый профиль c именем "my"
          final newProfile = RemoteProfileEntity(
            id: const Uuid().v4(),
            active: true,
            name: 'my', // как вы хотели
            url: state!.subscriptionLink!,
            lastUpdate: DateTime.now(),
          );
          await _profileRepo.add(newProfile).run();
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('Subscription sync failed: $e\n$st');
      }
    }
  }

  Future<ServerUser> _authenticateWithRetry(
    String username,
    String password,
  ) async {
    final delays = <Duration>[
      const Duration(milliseconds: 400),
      const Duration(seconds: 1),
      const Duration(seconds: 2),
    ];
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        if (kDebugMode) {
          print('[LOGIN] authenticate attempt ' +
              attempt.toString() +
              ' for ' +
              username);
        }
        final user = await _authenticateUserFromServer(username, password);
        return user;
      } on LoginException catch (e) {
        if (e.type == LoginExceptionType.invalidCredentials ||
            e.type == LoginExceptionType.unauthorized ||
            e.type == LoginExceptionType.userNotFound) {
          rethrow;
        }
        if (attempt >= 3) rethrow;
        final delay = delays[(attempt - 1).clamp(0, delays.length - 1)];
        await Future.delayed(delay);
      }
    }
  }

  Future<void> checkSubscriptionExpiry() async {
    final current = state;
    if (current == null || !current.isLoggedIn) {
      return; // Не залогинен — не проверяем
    }
    // 1) Проверяем, прошло ли 24 часа с lastCheckTime
    final now = DateTime.now();
    DateTime? lastCheck;
    if (current.lastCheckTime != null) {
      lastCheck = DateTime.tryParse(current.lastCheckTime!);
    }
    if (lastCheck != null) {
      final diff = now.difference(lastCheck);
      if (diff.inHours < 24) {
        // Не прошло ещё 24 часа с момента последней проверки
        return;
      }
    }

    // 2) Обновляем lastCheckTime в loginState, чтобы не проверять повторно
    final newState = current.copyWith(
      lastCheckTime: now.toIso8601String(),
    );
    state = newState;
    await _saveLoginStateToFile(newState);

    // 3) Дёргаем сервер (Strapi) за свежим data_expire
    //    Напишем вспомогательный метод:
    final updatedExpire =
        await _fetchLatestDataExpireFromServer(current.username);
    if (updatedExpire != null) {
      // Если дата изменилась — сохраняем
      if (updatedExpire == "null") {
        final updatedState = state?.copyWith(
          dataExpire: "null",
          overrideDataExpire: true,
        );
        state = updatedState;
        if (updatedState != null) {
          await _saveLoginStateToFile(updatedState);
        }
      } else if (updatedExpire != current.dataExpire) {
        final updatedState = state?.copyWith(dataExpire: updatedExpire);
        state = updatedState;
        if (updatedState != null) {
          await _saveLoginStateToFile(updatedState);
        }
      }
    }

    // 4) Проверяем, сколько осталось дней
    final expiryStr = state?.dataExpire;
    if (expiryStr == null || expiryStr.isEmpty) {
      return; // Нет даты истечения
    }
    final expiryDate = DateTime.tryParse(expiryStr);
    if (expiryDate == null) {
      return; // Парсинг не удался
    }
  }

  /// Пример метода, который ходит на сервер, чтобы получить новую data_expire
  Future<String?> _fetchLatestDataExpireFromServer(String username) async {
    try {
      // Просто повтор используем _authenticateUserFromServer,
      // но без сверки пароля.  Или делаем отдельный endpoint
      // get by username
      const apiUrl = Environment.apiUrl;
      final url = Uri.parse(
        '$apiUrl?filters[username][\$eq]=$username',
      );
      const token = Environment.apiToken;

      http.Response response;
      int attempt = 0;
      final delays = <Duration>[
        const Duration(milliseconds: 400),
        const Duration(seconds: 1),
        const Duration(seconds: 2),
      ];
      while (true) {
        attempt++;
        try {
          if (kDebugMode) {
            print('[HTTP] dataExpire GET attempt ' +
                attempt.toString() +
                ' ' +
                url.toString());
          }
          response = await http.get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
            },
          ).timeout(const Duration(seconds: 10));
          if (kDebugMode) {
            print('[HTTP] dataExpire <= ' + response.statusCode.toString());
          }
        } on SocketException catch (_) {
          if (attempt >= 3) return null;
          await Future.delayed(
              delays[(attempt - 1).clamp(0, delays.length - 1)]);
          continue;
        } on http.ClientException catch (_) {
          if (attempt >= 3) return null;
          await Future.delayed(
              delays[(attempt - 1).clamp(0, delays.length - 1)]);
          continue;
        } on TimeoutException catch (_) {
          if (attempt >= 3) return null;
          await Future.delayed(
              delays[(attempt - 1).clamp(0, delays.length - 1)]);
          continue;
        }
        if (response.statusCode < 400) {
          break;
        }
        if (response.statusCode == 401 ||
            response.statusCode == 403 ||
            response.statusCode == 404 ||
            response.statusCode == 400) {
          break;
        }
        if (attempt >= 3) {
          break;
        }
        // 429: respect Retry-After if present
        Duration delay = delays[(attempt - 1).clamp(0, delays.length - 1)];
        if (response.statusCode == 429) {
          final ra = response.headers['retry-after'];
          final s = ra != null ? int.tryParse(ra) : null;
          if (s != null) delay = Duration(seconds: s);
        }
        await Future.delayed(delay);
      }
      // If request didn't succeed with 200, proceed to return null below
      if (response.statusCode != 200) {
        return null;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final dataField = data["data"];
          if (dataField is List && dataField.isNotEmpty) {
            final firstObj = dataField[0];
            final attr = firstObj["attributes"] as Map<String, dynamic>?;
            if (attr != null) {
              final dataExpireStr = attr["data_expire"] as String?;
              if (dataExpireStr == null) {
                return "null";
              }
              return dataExpireStr; // Может быть null
            }
          }
        }
      }
      // Иначе null
      return null;
    } catch (e) {
      // Игнорировать или логировать
      return null;
    }
  }

  Future<void> setLastAlertTime(DateTime newTime) async {
    final s = state;
    if (s == null) return;

    final updated = s.copyWith(lastAlertTime: newTime.toIso8601String());
    state = updated;
    await _saveLoginStateToFile(updated);
  }
}

class ServerUser {
  final String username;
  final String? subscriptionLink;
  final DateTime? dataExpire;
  ServerUser({
    required this.username,
    this.subscriptionLink,
    this.dataExpire,
  });
}

class LoginException implements Exception {
  final String message;
  final LoginExceptionType type;
  LoginException(this.message, {this.type = LoginExceptionType.unknown});
}

enum LoginExceptionType {
  invalidCredentials,
  userNotFound,
  serverError,
  connectionError,
  unauthorized,
  unknown,
}
