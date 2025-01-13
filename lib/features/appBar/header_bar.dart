// lib/features/header_bar/header_bar.dart

import 'package:flutter/material.dart';
import 'package:rostov_vpn/constants/colors.dart';
import 'package:rostov_vpn/features/appBar/my_menu_bar.dart';

/// Виджет для AppBar
class HeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const HeaderBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 4.0,
      shadowColor: Colors.white.withAlpha(60),
      backgroundColor: AppColors.darkPink,
      title: const Text(
        'Rostov VPN', // Или локализованная строка
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: MyMenuBar(),
        ),
      ],
    );
  }
}

// import 'package:fluentui_system_icons/fluentui_system_icons.dart';
// import 'package:flutter/material.dart';
// import 'package:rostov_vpn/constants/colors.dart';
// import 'package:rostov_vpn/core/localization/translations.dart';
// import 'package:rostov_vpn/core/router/routes.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart'
//     show ConsumerWidget, WidgetRef;

// /// Ваш кастомный HeaderBar, который вернёт готовый AppBar.
// ///
// /// Чтобы использовать его в Scaffold, нужно реализовать PreferredSizeWidget.
// /// Тогда мы сможем написать appBar: HeaderBar(...), и Flutter будет знать
// /// какую высоту должен занимать этот виджет.

// /// Ваш кастомный HeaderBar, который вернёт готовый AppBar.
// class HeaderBar extends ConsumerWidget implements PreferredSizeWidget {
//   const HeaderBar({
//     super.key,
//   });

//   /// Размер AppBar по высоте
//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);

//   /// Вместо `build(BuildContext context)`, у `ConsumerWidget` —
//   /// `build(BuildContext context, WidgetRef ref)`
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // Считываем переводы
//     final t = ref.watch(translationsProvider);

//     return AppBar(
//       // Говорим «всегда рисуй тень, даже если нет прокрутки»

//       // Классическая «статическая» тень
//       elevation: 4.0,

//       // Цвет тени (по умолчанию может быть не совсем заметен)
//       shadowColor: Colors.white.withAlpha(60),
//       backgroundColor: AppColors.darkPink,
//       title: Text(
//         t.general.appTitle,
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 32,
//         ),
//       ),
//       actions: const [
//         // Меню (прежний вариант)
//         Padding(
//           padding: EdgeInsets.only(right: 16.0),
//           child: MyMenuBar(message: 'asd'),
//         ),
//       ],
//     );
//   }
// }

// class MyMenuBar extends StatefulWidget {
//   const MyMenuBar({
//     super.key,
//     required this.message,
//   });

//   final String message;

//   @override
//   State<MyMenuBar> createState() => _MyMenuBarState();
// }

// class _MyMenuBarState extends State<MyMenuBar> {
//   ShortcutRegistryEntry? _shortcutsEntry;

//   /// Флаг, показывающий, «залогинен» ли пользователь
//   bool _isLogined = false;

//   bool get loginingUser => _isLogined;
//   set loginingUser(bool value) {
//     if (_isLogined != value) {
//       setState(() {
//         _isLogined = value;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _shortcutsEntry?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MenuBar(
//       // Сделаем фон прозрачным, чтобы не было лишней заливки
//       style: MenuStyle(
//         backgroundColor: WidgetStateProperty.all(Colors.transparent),
//         padding: WidgetStateProperty.all(EdgeInsets.zero),
//         shape: WidgetStateProperty.all(
//           RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
//         ),
//       ),
//       children: MenuEntry.build(_getMenus()),
//     );
//   }

//   /// Собираем список меню и подпунктов
//   List<MenuEntry> _getMenus() {
//     // Если имя слишком длинное, обрезаем для примера
//     const String userLabel = 'darkmen203123123123123123';
//     const String shortLabel =
//         userLabel.length > 10 ? 'darkmen203...' : userLabel;

//     return <MenuEntry>[
//       MenuEntry(
//         label: shortLabel,
//         menuChildren: <MenuEntry>[
//           MenuEntry(
//             label: loginingUser ? 'Войти' : 'Выйти',
//             onPressed: () {
//               setState(() {
//                 loginingUser = !loginingUser;
//               });
//             },
//           ),
//         ],
//       ),
//     ];
//   }
// }

// /// Вспомогательный класс для описания пунктов меню
// class MenuEntry {
//   const MenuEntry({
//     required this.label,
//     this.shortcut,
//     this.onPressed,
//     this.menuChildren,
//   }) : assert(
//           menuChildren == null || onPressed == null,
//           'onPressed игнорируется, если есть menuChildren',
//         );

//   final String label;
//   final MenuSerializableShortcut? shortcut;
//   final VoidCallback? onPressed;
//   final List<MenuEntry>? menuChildren;

//   /// Создаём виджеты (MenuItemButton или SubmenuButton) из списка MenuEntry
//   static List<Widget> build(List<MenuEntry> selections) {
//     Widget buildSelection(MenuEntry selection) {
//       if (selection.menuChildren != null) {
//         // "Корень" меню — SubmenuButton с иконкой и текстом
//         return SubmenuButton(
//           style: ButtonStyle(
//             backgroundColor: WidgetStateProperty.all(AppColors.pink),
//             shape: WidgetStateProperty.all(
//               RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20.0),
//               ),
//             ),
//           ),
//           menuChildren: MenuEntry.build(selection.menuChildren!),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.person, color: Colors.white),
//               const SizedBox(width: 8.0), // отступ между иконкой и текстом
//               Text(
//                 selection.label,
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ],
//           ),
//         );
//       }
//       // Пункты внутри выпадающего меню
//       return MenuItemButton(
//         style: ButtonStyle(
//           backgroundColor: WidgetStateProperty.all(AppColors.pink),
//           minimumSize: const WidgetStatePropertyAll(Size(150.0, 40.0)),
//         ),
//         shortcut: selection.shortcut,
//         onPressed: selection.onPressed,
//         child: Text(
//           selection.label,
//           style: const TextStyle(color: Colors.white),
//         ),
//       );
//     }

//     return selections.map<Widget>(buildSelection).toList();
//   }

//   /// Собираем карту хоткеев, чтобы ShortcutRegistry мог их зарегистрировать
//   static Map<MenuSerializableShortcut, Intent> shortcuts(
//     List<MenuEntry> selections,
//   ) {
//     final Map<MenuSerializableShortcut, Intent> result =
//         <MenuSerializableShortcut, Intent>{};
//     for (final MenuEntry selection in selections) {
//       if (selection.menuChildren != null) {
//         // Рекурсивно собираем хоткеи из подпунктов
//         result.addAll(MenuEntry.shortcuts(selection.menuChildren!));
//       } else {
//         // Если есть shortcut и onPressed, регистрируем его
//         if (selection.shortcut != null && selection.onPressed != null) {
//           result[selection.shortcut!] =
//               VoidCallbackIntent(selection.onPressed!);
//         }
//       }
//     }
//     return result;
//   }
// }
