// lib/core/login/login_manager_notifier.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:rostov_vpn/core/login/login_state.dart';
import 'package:rostov_vpn/features/profile/data/profile_repository.dart';
import 'package:rostov_vpn/features/profile/model/profile_entity.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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
    final dir = await getApplicationDocumentsDirectory();
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

  // Future<bool> login(String username, String password) async {
  //   // Включаем isLoading
  //   final oldState = state;
  //   state = (oldState == null)
  //       ? LoginState(username: '', isLoggedIn: false, isLoading: true)
  //       : oldState.copyWith(isLoading: true);

  //   try {
  //     final user = await _authenticateUserFromServer(username, password);
  //     // Успех
  //     final newState = LoginState(
  //       username: user.username,
  //       isLoggedIn: true,
  //       subscriptionLink: user.subscriptionLink,
  //       dataExpire: user.dataExpire?.toIso8601String(),
  //     );
  //     state = newState;
  //     await _saveLoginStateToFile(newState);

  //     // Если есть subscriptionLink => add profile
  //     if (user.subscriptionLink != null && user.subscriptionLink!.isNotEmpty) {
  //       final newProfile = RemoteProfileEntity(
  //         id: const Uuid().v4(),
  //         active: true,
  //         name: 'my',
  //         url: user.subscriptionLink!,
  //         lastUpdate: DateTime.now(),
  //       );
  //       final failureOrSuccess = await _profileRepo.add(newProfile).run();
  //       if (kDebugMode) {
  //         print(
  //           'Я тут',
  //         );
  //       }
  //       if (failureOrSuccess.isLeft()) {
  //         if (kDebugMode) {
  //           print('Ошибка при добавлении профиля: ${failureOrSuccess.swap()}');
  //         }
  //         return false;
  //       } else {
  //         state = state?.copyWith(isLoading: false);
  //         if (kDebugMode) {
  //           print('Профиль добавлен');
  //         }
  //       }
  //     }
  //     state = state?.copyWith(isLoading: false);
  //     return true;
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Login failed: $e');
  //     }
  //     state = state?.copyWith(isLoading: false);
  //     return false;
  //   }
  // }
  Future<bool> login(String username, String password) async {
    // Ставим isLoading = true
    final old = state;
    state = (old == null)
        ? LoginState(username: '', isLoggedIn: false, isLoading: true)
        : old.copyWith(isLoading: true);

    try {
      final user = await _authenticateUserFromServer(username, password);

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
    final url = Uri.parse(
      'http://88.218.66.251:1337/api/vpn-users?filters[username][\$eq]=$username',
    );

    const token =
        'cc1c7a3f7dc62520422547f76d9913ddb8daac8ff64faeb4561fa3fb3944e38bc5fb634171ddb7589e9c21b2c0d8d79581859a2470eddcbfa56817d6bb577c1ea76321ae3f08e28562be86b589b2f1c92d10ad7f1ddef285de669076e330815425b4f74b1d195affe280b3d92a2d4430bbcef8ff3c3d4588f2361b1a94910ee8';

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
