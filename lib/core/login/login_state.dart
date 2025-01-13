// lib/core/login/login_state.dart

import 'dart:convert';

/// Модель, которую сохраняем в JSON, похожа на Avalonia LoginState.
class LoginState {
  final String username;
  final bool isLoggedIn;
  final String? subscriptionLink;
  final String? dataExpire; // Можно хранить дату строкой (ISO)
  final bool isLoading; 

  LoginState({
    required this.username,
    required this.isLoggedIn,
    this.subscriptionLink,
    this.dataExpire,
    this.isLoading = false,
  });

    /// Для удобства сделаем copyWith
  LoginState copyWith({
    String? username,
    bool? isLoggedIn,
    String? subscriptionLink,
    String? dataExpire,
    bool? isLoading,
  }) {
    return LoginState(
      username: username ?? this.username,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      subscriptionLink: subscriptionLink ?? this.subscriptionLink,
      dataExpire: dataExpire ?? this.dataExpire,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'isLoggedIn': isLoggedIn,
        'subscriptionLink': subscriptionLink,
        'dataExpire': dataExpire,
      };

  factory LoginState.fromJson(Map<String, dynamic> map) => LoginState(
        username: map['username'] as String,
        isLoggedIn: map['isLoggedIn'] as bool,
        subscriptionLink: map['subscriptionLink'] as String?,
        dataExpire: map['dataExpire'] as String?,
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
