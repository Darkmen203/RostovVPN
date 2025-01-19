// lib/core/login/login_state.dart

import 'dart:convert';

/// Модель, которую сохраняем в JSON, похожа на Avalonia LoginState.
class LoginState {
  final String username;
  final bool isLoggedIn;
  final String? subscriptionLink;
  final String? dataExpire; // Можно хранить дату строкой (ISO)
  final String? lastCheckTime;
  final bool isLoading;
  final String? lastAlertTime;

  
  LoginState({
    required this.username,
    required this.isLoggedIn,
    this.subscriptionLink,
    this.dataExpire,
    this.lastCheckTime,
    this.isLoading = false,
    this.lastAlertTime,
  });

    /// Для удобства сделаем copyWith
  LoginState copyWith({
    String? username,
    bool? isLoggedIn,
    String? subscriptionLink,
    String? dataExpire,
    String? lastCheckTime,
    bool? isLoading,
    bool overrideDataExpire = false, 
    String? lastAlertTime,
  }) {
    return LoginState(
      username: username ?? this.username,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      subscriptionLink: subscriptionLink ?? this.subscriptionLink,
      dataExpire: overrideDataExpire ? dataExpire : (dataExpire ?? this.dataExpire),
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'isLoggedIn': isLoggedIn,
        'subscriptionLink': subscriptionLink,
        'dataExpire': dataExpire,
        'lastCheckTime': lastCheckTime,
      };

  factory LoginState.fromJson(Map<String, dynamic> map) => LoginState(
        username: map['username'] as String,
        isLoggedIn: map['isLoggedIn'] as bool,
        subscriptionLink: map['subscriptionLink'] as String?,
        dataExpire: map['dataExpire'] as String?,
        lastCheckTime: map['lastCheckTime'] as String?,
      );

  /// Преобразуем в JSON-строку
  String toJsonString() => jsonEncode(toJson());

  /// Создаём объект из JSON-строки
  static LoginState? fromJsonString(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return LoginState.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
