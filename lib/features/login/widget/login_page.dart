// import 'package:flutter/material.dart';
// import 'package:rostov_vpn/constants/colors.dart';
// import 'package:rostov_vpn/core/localization/translations.dart';
// import 'package:rostov_vpn/core/login/login_manager_provider.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';

// class LoginPage extends ConsumerStatefulWidget {
//   const LoginPage({super.key});

//   @override
//   ConsumerState<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends ConsumerState<LoginPage> {
//   final _usernameCtrl = TextEditingController();
//   final _passwordCtrl = TextEditingController();

//   bool _showPassword = false;

//   @override
//   Widget build(BuildContext context) {
//     final t = ref.watch(translationsProvider);

//     // Читаем состояние для isLoading
//     final loginState = ref.watch(loginManagerProvider);
//     final isLoading = loginState?.isLoading ?? false;

//     return Material(
//       child: Scaffold(
//         backgroundColor: AppColors.darkGray,
//         appBar: AppBar(
//           backgroundColor: AppColors.darkGray,
//           title: Text(t.general.loginTitle),
//           centerTitle: true,
//           automaticallyImplyLeading: false, // убираем кнопку "Назад"
//         ),
//         body: Stack(
//           alignment: Alignment.center,
//           fit: StackFit.expand,
//           children: [
//             // Основная форма
//             _buildForm(),

//             // Оверлей, если isLoading=true
//             if (isLoading)
//               const ColoredBox(
//                 color: AppColors.darkGray,
//                 child: Center(
//                   child: CircularProgressIndicator(),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildForm() {
//     final t = ref.watch(translationsProvider);

//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         children: [
//           TextField(
//             controller: _usernameCtrl,
//             decoration: InputDecoration(labelText: t.general.username),
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: _passwordCtrl,
//             obscureText: !_showPassword,
//             decoration: InputDecoration(
//               labelText: t.general.password,
//               suffixIcon: IconButton(
//                 icon: Icon(
//                   _showPassword ? Icons.visibility_off : Icons.visibility,
//                 ),
//                 onPressed: () {
//                   setState(() => _showPassword = !_showPassword);
//                 },
//               ),
//             ),
//           ),
//           const SizedBox(height: 32),
//           ElevatedButton(
//             style: const ButtonStyle(
//               backgroundColor: WidgetStatePropertyAll(AppColors.pink),
//             ),
//             onPressed: _onLoginPressed,
//             child: Text(t.general.login),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _onLoginPressed() async {
//     final t = ref.watch(translationsProvider);

//     final username = _usernameCtrl.text.trim();
//     final password = _passwordCtrl.text.trim();
//     if (username.isEmpty || password.isEmpty) {
//       _showErrorDialog(t.general.inputLoginAndPassword);
//       return;
//     }

//     final success =
//         await ref.read(loginManagerProvider.notifier).login(username, password);

//     if (!success && mounted) {
//       _showErrorDialog(t.general.errorLogin);
//     }
//   }

//   void _showErrorDialog(String msg) {
//     final t = ref.watch(translationsProvider);

//     showDialog<void>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text(t.general.errorLoginTitle),
//         content: Text(msg),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:rostov_vpn/constants/colors.dart';
import 'package:rostov_vpn/core/localization/translations.dart';
import 'package:rostov_vpn/core/login/login_manager_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final loginState = ref.watch(loginManagerProvider);
    final isLoading = loginState?.isLoading ?? false;

    return Material(
      child: Scaffold(
        backgroundColor: AppColors.darkGray,
        appBar: AppBar(
          backgroundColor: AppColors.darkGray,
          title: Text(t.general.loginTitle),
          centerTitle: true,
          automaticallyImplyLeading: false, // Убираем кнопку "Назад"
        ),
        body: Stack(
          children: [
            // Этот виджет растянется на весь экран
            Positioned.fill(
              bottom: 150.0,
              // При желании можно использовать Center + SingleChildScrollView
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildForm(),
                ),
              ),
            ),

            // Если isLoading == true, показываем полупрозрачный фон + прогресс
            if (isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final t = ref.watch(translationsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min, // чтобы сжаться по высоте
      children: [
        TextField(
          controller: _usernameCtrl,
          decoration: InputDecoration(labelText: t.general.username),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordCtrl,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: t.general.password,
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _showPassword = !_showPassword);
              },
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          style: const ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(AppColors.pink),
          ),
          onPressed: _onLoginPressed,
          child: Text(t.general.login),
        ),
      ],
    );
  }

  Future<void> _onLoginPressed() async {
    final t = ref.watch(translationsProvider);

    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog(t.general.inputLoginAndPassword);
      return;
    }

    final success =
        await ref.read(loginManagerProvider.notifier).login(username, password);

    if (!success && mounted) {
      _showErrorDialog(t.general.errorLogin);
    }
  }

  void _showErrorDialog(String msg) {
    final t = ref.watch(translationsProvider);

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.general.errorLoginTitle),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
