// lib/features/appBar/my_menu_bar.dart

import 'package:flutter/material.dart';
import 'package:rostov_vpn/constants/colors.dart';
import 'package:rostov_vpn/core/localization/translations.dart';
import 'package:rostov_vpn/core/login/login_manager_provider.dart';
import 'package:rostov_vpn/features/appBar/login_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyMenuBar extends ConsumerWidget {
  const MyMenuBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final loginState = ref.watch(loginManagerProvider);

    final isLoggedIn = loginState?.isLoggedIn ?? false;
    final userName = isLoggedIn ? (loginState?.username ?? "???") : t.general.gologin;

    final shortLabel =
        (userName.length > 10) ? '${userName.substring(0, 10)}...' : userName;

    return MenuBar(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.pink),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        alignment: Alignment.center,
        // Можно добавить выравнивание для всей MenuBar, но обычно не нужно.
      ),
      children: [
        // SubmenuButton - «корневая» кнопка
        SubmenuButton(
          alignmentOffset: const Offset(20, 2),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(AppColors.pink),
            alignment: Alignment.center,
            minimumSize: const WidgetStatePropertyAll(Size(50.0, 40.0)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
          // А это раскрывающееся меню внутри:
          menuChildren: [
            MenuItemButton(
              // Центрируем сам элемент меню
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(AppColors.pink),
                alignment: Alignment.center,
                minimumSize: const WidgetStatePropertyAll(Size(80.0, 40.0)),
              ),
              child: Text(
                isLoggedIn ? t.general.logout : t.general.login,
                textAlign: TextAlign.center, // текст по центру
              ),
              onPressed: () async {
                if (!isLoggedIn) {
                  final result = await showDialog<LoginDialogResult>(
                    context: context,
                    builder: (_) => const LoginDialog(),
                  );
                  if (result != null) {
                    final success = await ref
                        .read(loginManagerProvider.notifier)
                        .login(result.username, result.password);

                    if (!success && context.mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(t.general.errorLoginTitle),
                          content: Text(t.general.errorLogin),
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
                } else {
                  await ref.read(loginManagerProvider.notifier).logout();
                }
              },
            ),
          ],
          // Это то, что отображается «снаружи»
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person, color: Colors.white),
              const SizedBox(width: 8.0),
              Text(
                shortLabel,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center, // центр текста по горизонтали
              ),
              const SizedBox(width: 8.0),
            ],
          ),
        ),
      ],
    );
  }
}

// // // lib/features/appBar/my_menu_bar.dart

// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:rostov_vpn/core/login/login_manager.dart';

// // import 'login_dialog.dart';
// // import 'package:rostov_vpn/core/login/login_manager_provider.dart'; // <-- наш провайдер

// // class MyMenuBar extends ConsumerWidget {
// //   const MyMenuBar({super.key});

// //   @override
// //   Widget build(BuildContext context, WidgetRef ref) {
// //     // Берём наш LoginManager
// //     final manager = ref.watch(loginManagerProvider);

// //     return MenuBar(
// //       style: MenuStyle(
// //         backgroundColor: WidgetStateProperty.all(Colors.transparent),
// //         padding: WidgetStateProperty.all(EdgeInsets.zero),
// //       ),
// //       children: _buildMenus(context, manager),
// //     );
// //   }

// //   List<Widget> _buildMenus(BuildContext context, LoginManager manager) {
// //     final userName = manager.isLoggedIn ? manager.username : 'войдите';

// //     final shortLabel = (userName.length > 10)
// //         ? '${userName.substring(0, 10)}...'
// //         : userName;

// //     return [
// //       SubmenuButton(
// //         menuChildren: [
// //           MenuItemButton(
// //             child: Text(manager.isLoggedIn ? 'Выйти' : 'Войти'),
// //             onPressed: () async {
// //               if (!manager.isLoggedIn) {
// //                 // показать диалог логина
// //                 final result = await showDialog<LoginDialogResult>(
// //                   context: context,
// //                   builder: (_) => const LoginDialog(),
// //                 );
// //                 if (result != null) {
// //                   final ok = await manager.login(result.username, result.password);
// //                   if (ok) {
// //                     // Успешно
// //                     // setState() уже не нужен, т.к. ConsumerWidget перерисуется сам
// //                     // Но если хотим сразу отобразить, можно вызвать context.refresh(...) (в Riverpod 2.x)
// //                   } else {
// //                     // Ошибка
// //                     if (context.mounted) {
// //                       showDialog(
// //                         context: context,
// //                         builder: (_) => AlertDialog(
// //                           title: const Text('Ошибка'),
// //                           content: const Text('Неверный логин или пароль'),
// //                           actions: [
// //                             TextButton(
// //                               onPressed: () => Navigator.pop(context),
// //                               child: const Text('OK'),
// //                             ),
// //                           ],
// //                         ),
// //                       );
// //                     }
// //                   }
// //                 }
// //               } else {
// //                 // Выйти
// //                 await manager.logout();
// //               }
// //             },
// //           ),
// //         ],
// //         child: Row(
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             const Icon(Icons.person, color: Colors.white),
// //             const SizedBox(width: 8.0),
// //             Text(
// //               shortLabel,
// //               style: const TextStyle(color: Colors.white),
// //             ),
// //           ],
// //         ),
// //       ),
// //     ];
// //   }
// // }
// // lib/features/appBar/my_menu_bar.dart

// import 'package:flutter/material.dart';
// import 'package:rostov_vpn/constants/colors.dart';
// import 'package:rostov_vpn/core/login/login_manager_provider.dart';
// import 'package:rostov_vpn/features/appBar/login_dialog.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';

// class MyMenuBar extends ConsumerWidget {
//   const MyMenuBar({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // Вместо LoginManager, читаем непосредственно LoginState? из провайдера
//     final loginState = ref.watch(loginManagerProvider);

//     final isLoggedIn = loginState?.isLoggedIn ?? false;
//     final userName = isLoggedIn ? (loginState?.username ?? "???") : "войдите";

//     final shortLabel =
//         (userName.length > 10) ? '${userName.substring(0, 10)}...' : userName;

//     return MenuBar(
//       style: MenuStyle(
//         backgroundColor: WidgetStateProperty.all(Colors.transparent),
//         padding: WidgetStateProperty.all(EdgeInsets.zero),
//         shape: WidgetStateProperty.all(
//           RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
//         ),
//       ),
//       children: [
//         SubmenuButton(
//           style: ButtonStyle(
//             backgroundColor: WidgetStateProperty.all(AppColors.pink),
//             shape: WidgetStateProperty.all(
//               RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20.0),
//               ),
//             ),
//           ),
//           menuChildren: [
//             MenuItemButton(
//               style: ButtonStyle(
//                 backgroundColor: WidgetStateProperty.all(AppColors.pink),
//               ),
//               child: Text(isLoggedIn ? 'Выйти' : 'Войти'),
//               onPressed: () async {
//                 if (!isLoggedIn) {
//                   // показать диалог логина
//                   final result = await showDialog<LoginDialogResult>(
//                     context: context,
//                     builder: (_) => const LoginDialog(),
//                   );
//                   if (result != null) {
//                     final success = await ref
//                         .read(loginManagerProvider.notifier)
//                         .login(result.username, result.password);

//                     if (!success && context.mounted) {
//                       showDialog(
//                         context: context,
//                         builder: (_) => AlertDialog(
//                           title: const Text('Ошибка'),
//                           content: const Text('Неверный логин или пароль'),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Navigator.pop(context),
//                               child: const Text('OK'),
//                             ),
//                           ],
//                         ),
//                       );
//                     }
//                   }
//                 } else {
//                   await ref.read(loginManagerProvider.notifier).logout();
//                 }
//               },
//             ),
//           ],
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.person, color: Colors.white),
//               const SizedBox(width: 8.0),
//               Text(shortLabel, style: const TextStyle(color: Colors.white)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
