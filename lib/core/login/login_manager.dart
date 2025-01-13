// lib/core/login/login_manager.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:rostov_vpn/core/login/login_state.dart';
import 'package:rostov_vpn/features/profile/data/profile_repository.dart';
import 'package:rostov_vpn/features/profile/model/profile_entity.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Исключение, если логин не удался
class LoginException implements Exception {
  final String message;
  final LoginExceptionType type;
  LoginException(this.message, {this.type = LoginExceptionType.unknown});
}

enum LoginExceptionType {
  invalidCredentials, // Неверный логин/пароль
  userNotFound, // Пользователь не найден в базе
  serverError, // Ошибка на сервере
  connectionError, // Нет ответа, таймаут, и т. д.
  unauthorized, // Например, токен недействителен
  unknown,
}

/// Структура ответа сервера (при удачной сверке)
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

/// Менеджер для логина/логаута + хранение локального состояния
class LoginManager {
  final ProfileRepository _profileRepo;
  LoginState? _cachedState;
  LoginManager(this._profileRepo);

  /// Возвращает текущее состояние залогиненности
  LoginState? get currentLogin => _cachedState;

  /// Удобный getter
  bool get isLoggedIn => _cachedState?.isLoggedIn ?? false;

  String get username => _cachedState?.username ?? 'darkmen203';

  /// Инициализация при старте приложения
  Future<void> init() async {
    _cachedState = await _loadLoginStateFromFile();
  }

  /// Локальный файл (DocumentsDirectory/loginState.json)
  Future<File> _getLoginFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/loginState.json');
  }

  /// Чтение loginState.json
  Future<LoginState?> _loadLoginStateFromFile() async {
    try {
      final file = await _getLoginFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        return LoginState.fromJsonString(content);
      }
    } catch (e) {
      print('Ошибка чтения loginState.json: $e');
    }
    return null;
  }

  /// Запись
  Future<void> _saveLoginStateToFile(LoginState state) async {
    try {
      final file = await _getLoginFile();
      await file.writeAsString(state.toJsonString());
    } catch (e) {
      print('Ошибка записи loginState.json: $e');
    }
  }

  /// Удаление
  Future<void> _clearLoginStateFile() async {
    try {
      final file = await _getLoginFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Ошибка удаления loginState.json: $e');
    }
  }

  /// Основной метод логина
  /// - Возвращает true, если успех
  /// - Ловит LoginException и возвращает false
  Future<bool> login(String username, String password) async {
    try {
      final user = await _authenticateUserFromServer(username, password);
      // Успех
      final newState = LoginState(
        username: user.username,
        isLoggedIn: true,
        subscriptionLink: user.subscriptionLink,
        dataExpire: user.dataExpire?.toIso8601String(),
      );
      _cachedState = newState;
      await _saveLoginStateToFile(newState);

      // *** Новая логика: если есть subscriptionLink, добавляем профиль
      if (user.subscriptionLink != null && user.subscriptionLink!.isNotEmpty) {
        final newProfile = RemoteProfileEntity(
          id: const Uuid().v4(),
          active: true,
          name: 'my', // как вы хотели
          url: user.subscriptionLink!,
          lastUpdate: DateTime.now(),
        );

        final failureOrSuccess = await _profileRepo.add(newProfile).run();

        if (failureOrSuccess.isLeft()) {
          // Если произошла ошибка, можно решить, что делать
          if (kDebugMode) {
            print(
              'Ошибка при добавлении профиля: ${failureOrSuccess.swap()}',
            );
          }
          return false;
        } else {
          if (kDebugMode) {
            print('Профиль с subscriptionLink добавлен');
          }
        }
      }

      return true;
    } on LoginException catch (ex) {
      if (kDebugMode) {
        print('Login failed: ${ex.message}');
      }
      return false;
    }
  }

  /// Выход
  Future<void> logout() async {
    _cachedState = null;
    final failureOrSuccess = await _profileRepo.deleteAll().run();
    if (failureOrSuccess.isLeft()) {
      if (kDebugMode) {
        print(
          'Ошибка при удалении всех профилей: ${failureOrSuccess.swap()}',
        );
      }
      // Можно решить, нужно ли прерывать процесс
    }

    await _clearLoginStateFile();
  }

  /// Запрос к серверу, парсинг JSON, сверка bcrypt
  ///  - Если всё ок, возвращаем ServerUser
  ///  - Иначе бросаем LoginException
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
      response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
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
// // lib/core/login/login_manager.dart

// import 'dart:io';

// import 'package:bcrypt/bcrypt.dart';
// import 'package:flutter/foundation.dart';
// import 'package:rostov_vpn/core/login/login_state.dart';
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';

// /// Простая структура «ответа сервера»
// class ServerUser {
//   final String username;
//   final String? subscriptionLink;
//   final DateTime? dataExpire;

//   ServerUser({
//     required this.username,
//     this.subscriptionLink,
//     this.dataExpire,
//   });
// }

// /// LoginManager отвечает за:
// /// 1) Чтение/запись loginState.json
// /// 2) Проверку пользователя на сервере
// class LoginManager {
//   LoginState? _cachedState;

//   LoginManager();

//   /// Возвращает LoginState, если пользователь авторизован,
//   /// иначе null
//   LoginState? get currentLogin => _cachedState;

//   /// true, если пользователь залогинен
//   bool get isLoggedIn => _cachedState?.isLoggedIn ?? false;

//   /// Имя пользователя
//   String get username => _cachedState?.username ?? 'darkmen203';

//   /// Пусть этот метод инициализируется при старте приложения
//   Future<void> init() async {
//     _cachedState = await _loadLoginStateFromFile();
//   }

//   /// Локальный файл, где хранится loginState.json
//   Future<File> _getLoginFile() async {
//     final dir = await getApplicationDocumentsDirectory();
//     return File('${dir.path}/loginState.json');
//   }

//   /// Прочитать loginState.json
//   Future<LoginState?> _loadLoginStateFromFile() async {
//     try {
//       final file = await _getLoginFile();
//       if (await file.exists()) {
//         final content = await file.readAsString();
//         return LoginState.fromJsonString(content);
//       }
//     } catch (e) {
//       // Логируем ошибку
//       if (kDebugMode) {
//         print('Ошибка при чтении loginState.json: $e');
//       }
//     }
//     return null;
//   }

//   /// Сохранить loginState.json
//   Future<void> _saveLoginStateToFile(LoginState state) async {
//     try {
//       final file = await _getLoginFile();
//       await file.writeAsString(state.toJsonString());
//     } catch (e) {
//       if (kDebugMode) {
//         print('Ошибка при записи loginState.json: $e');
//       }
//     }
//   }

//   /// Удалить loginState.json (при Logout)
//   Future<void> _clearLoginStateFile() async {
//     try {
//       final file = await _getLoginFile();
//       if (await file.exists()) {
//         await file.delete();
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Ошибка при удалении loginState.json: $e');
//       }
//     }
//   }

//   /// Попытка логина: делаем запрос на сервер, проверяем пароль, если ок —
//   /// сохраняем LoginState и возвращаем true, иначе false
//   Future<bool> login(String username, String password) async {
//     final user = await _authenticateUserFromServer(username, password);
//     if (user == null) {
//       // Неверные данные
//       return false;
//     }
//     // Успех:
//     final newState = LoginState(
//       username: user.username,
//       isLoggedIn: true,
//       subscriptionLink: user.subscriptionLink,
//       dataExpire: user.dataExpire?.toIso8601String(),
//     );
//     _cachedState = newState;
//     await _saveLoginStateToFile(newState);
//     return true;
//   }

//   /// Выход
//   Future<void> logout() async {
//     _cachedState = null;
//     await _clearLoginStateFile();
//     // Если нужно удалить подписи/configs, делаем тут
//   }

//   /// Пример запроса к серверу
//   Future<ServerUser?> _authenticateUserFromServer(
//       String username, String password,) async {
//     try {
//       final url = Uri.parse(
//           'http://88.218.66.251:1337/api/vpn-users?filters[username][\$eq]=$username',);
//       const token = 'cc1c7a3f7dc62520422547f76d9913ddb8daac8ff64faeb4561fa3fb3944e38bc5fb634171ddb7589e9c21b2c0d8d79581859a2470eddcbfa56817d6bb577c1ea76321ae3f08e28562be86b589b2f1c92d10ad7f1ddef285de669076e330815425b4f74b1d195affe280b3d92a2d4430bbcef8ff3c3d4588f2361b1a94910ee8'; // демонстрационный токен
//       final response = await http.get(url, headers: {
//         'Authorization': 'Bearer $token',
//       },);
//       if (response.statusCode == 200) {
//         // 4. Парсим JSON
//         final Map<String, dynamic> data = jsonDecode(response.body);

//         // Предположим, сервер кладёт список пользователей в поле "Data"
//         if (data["Data"] is List && data["Data"].isNotEmpty) {
//           final userAttributes = data["Data"][0]["Attributes"];

//           final serverUsername = userAttributes["Username"] as String?;
//           final hashedPassword = userAttributes["Password"] as String?;
//           final subscriptionLink = userAttributes["Subscription_link"] as String?;
//           final dataExpireStr = userAttributes["Data_expire"] as String?;

//           if (serverUsername == null || hashedPassword == null) {
//             return null;
//           }

//           // 5. Сверка bcrypt
//           // plaintext = plainPassword (то, что пользователь ввёл)
//           // hashedPassword = строка с bcrypt-хэшем, полученная с сервера
//           final passwordOk = BCrypt.checkpw(password, hashedPassword);

//           if (passwordOk) {
//             // 6. Преобразуем дату (если сервер возвращает ISO8601)
//             DateTime? expireDate;
//             if (dataExpireStr != null && dataExpireStr.isNotEmpty) {
//               expireDate = DateTime.tryParse(dataExpireStr);
//             }

//             // 7. Возвращаем ServerUser
//             return ServerUser(
//               username: serverUsername,
//               subscriptionLink: subscriptionLink,
//               dataExpire: expireDate,
//             );
//           }
//         }
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Ошибка при запросе: $e');
//       }
//     }
//     return null; // null => неверный логин/пароль
//   }
// }
