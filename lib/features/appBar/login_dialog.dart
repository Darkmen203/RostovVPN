import 'package:flutter/material.dart';
import 'package:rostov_vpn/constants/colors.dart';
import 'package:rostov_vpn/core/localization/translations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Результат диалога, возвращаемый при нажатии на "Войти"
class LoginDialogResult {
  final String username;
  final String password;
  LoginDialogResult(this.username, this.password);
}

/// Диалог ввода логина и пароля.
/// Теперь унаследован от ConsumerStatefulWidget, чтобы иметь доступ к `ref`.
class LoginDialog extends ConsumerStatefulWidget {
  const LoginDialog({super.key});

  @override
  ConsumerState<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends ConsumerState<LoginDialog> {
  /// Текстовые контроллеры для полей ввода
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    // Не забываем освобождать ресурсы
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);

    return AlertDialog(
      backgroundColor: AppColors.darkGray,
      title: Text(t.general.loginTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameCtrl,
            decoration: InputDecoration(labelText: t.general.username),
          ),
          TextField(
            controller: _passwordCtrl,
            decoration: InputDecoration(labelText: t.general.password),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.general.cancel),
        ),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(AppColors.pink),
          ),
          onPressed: () {
            final name = _usernameCtrl.text.trim();
            final pass = _passwordCtrl.text.trim();

            // Простая проверка на пустоту
            if (name.isEmpty || pass.isEmpty) {
              // Можно показать SnackBar или AlertDialog c ошибкой
              return;
            }

            // Возвращаем результат
            Navigator.pop(context, LoginDialogResult(name, pass));
          },
          child: Text(t.general.login),
        ),
      ],
    );
  }
}
