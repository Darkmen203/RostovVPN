// lib/features/update_subscription/data/data_expire_alert.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rostov_vpn/core/localization/translations.dart';
import 'package:rostov_vpn/core/login/login_manager_provider.dart';
import 'package:rostov_vpn/core/login/login_state.dart';

/// Аналог виджета UpgradeAlert, но для проверки подписки
class DataExpireAlert extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  const DataExpireAlert({
    super.key,
    required this.child,
    this.navigatorKey,
  });

  @override
  ConsumerState<DataExpireAlert> createState() => _DataExpireAlertState();
}

class _DataExpireAlertState extends ConsumerState<DataExpireAlert> {
  bool _dialogShown = false;

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   // Вместо непосредственного вызова — откладываем на следующий фрейм:
  //   // WidgetsBinding.instance.addPostFrameCallback((_) {
  //   //   _checkAndShowDialogIfNeeded();
  //   // });
  //   ref.listen<LoginState?>(loginManagerProvider, (previous, next) {
  //     if (mounted) {
  //       _checkAndShowDialogIfNeeded();
  //     }
  //   });
  // }
  @override
  Widget build(BuildContext context) {
    // Здесь разрешено ref.listen(...)
    ref.listen<LoginState?>(loginManagerProvider, (previous, next) {
      // При любом изменении loginManagerProvider
      if (!mounted) {
        return; // чтобы избежать лишних вызовов, если виджет dispose
      }

      _checkAndShowDialogIfNeeded();
    });

    return widget.child;
  }

  Future<void> _checkAndShowDialogIfNeeded() async {
    if (_dialogShown) return;

    // 1) Смотрим dataExpire
    final login = ref.read(loginManagerProvider);
    if (login == null) return;
    final dataExpireStr = login.dataExpire;
    if (dataExpireStr == null) return;
    final expireDate = DateTime.tryParse(dataExpireStr);
    final lastAlertTime = login.lastAlertTime;
    if (expireDate == null) return;

    // 2) daysLeft
    final daysLeft = expireDate.difference(DateTime.now()).inDays;
    if (daysLeft > 3) return; // только если <=3 => показываем диалог
    // 1) Проверяем, прошло ли 24 часа с lastAlertTime
    final now = DateTime.now();
    DateTime? lastCheck;
    if (lastAlertTime != null) {
      lastCheck = DateTime.tryParse(lastAlertTime);
    }
    if (lastCheck != null && now.difference(lastCheck).inHours < 24) {
      return;
    }

    _dialogShown = true;
    ref.read(loginManagerProvider.notifier).setLastAlertTime(DateTime.now());
    // 3) Получаем контекст настоящего Navigator
    final navigatorState = widget.navigatorKey?.currentState;
    final navContext = navigatorState?.overlay?.context;
    if (navContext == null) {
      if (kDebugMode) {
        print('** navContext == null => cannot show');
      }
      // fallback
      return;
    }

    // 4) showDialog с этим контекстом
    await showDialog(
      context: navContext,
      builder: (dialogContext) => _buildDialog(daysLeft, dialogContext),
    );
  }

  Widget _buildDialog(int daysLeft, BuildContext dialogContext) {
    final t = ref.watch(translationsProvider);
    return AlertDialog(
      title: Text(t.general.title_alert_pay),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.general.content_alert_pay),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: Theme.of(dialogContext).textTheme.bodyMedium,
              children: [
                TextSpan(text: t.general.pay_message_alert_pay),
                TextSpan(
                  text: '${t.general.number_alert_pay} +7 (996) 613-08-01\n',
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      // Копируем в буфер
                      await Clipboard.setData(
                        const ClipboardData(text: '+7 (996) 613-08-01'),
                      );
                      // Покажем SnackBar «Скопировано»
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Номер скопирован')),
                      );
                    },
                ),
                TextSpan(text: '${t.general.bank_alert_pay} Альфа-банк\n'),
                TextSpan(text: '${t.general.recipient_alert_pay} Дмитрий П.'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop(); // Напомнить позже
          },
          child: Text(t.general.remind_later_alert_pay),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            // Здесь какая-то логика «Оплатить»
          },
          child: Text(t.general.pay_alert_pay),
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:rostov_vpn/core/login/login_manager_provider.dart';

// /// Аналог виджета UpgradeAlert, но для проверки подписки
// class DataExpireAlert extends ConsumerStatefulWidget {
//   final Widget child;

//   /// Например, ключ для Navigator, если нужно
//   final GlobalKey<NavigatorState>? navigatorKey;

//   const DataExpireAlert({
//     Key? key,
//     required this.child,
//     this.navigatorKey,
//   }) : super(key: key);

//   @override
//   ConsumerState<DataExpireAlert> createState() => _DataExpireAlertState();
// }

// class _DataExpireAlertState extends ConsumerState<DataExpireAlert> {
//   bool _dialogShown = false;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     _checkAndShowDialogIfNeeded();
//   }

//   Future<void> _checkAndShowDialogIfNeeded() async {
//     if (_dialogShown) return;

//     // Допустим, мы получаем из loginManagerProvider
//     // текущее количество дней до истечения
//     final login = ref.watch(loginManagerProvider);
//     final dataExpireStr = login?.dataExpire;
//     if (dataExpireStr == null) return;

//     final expireDate = DateTime.tryParse(dataExpireStr);
//     if (expireDate == null) return;

//     final daysLeft = expireDate.difference(DateTime.now()).inDays;
//     if (daysLeft <= 3) {
//       // Показываем диалог
//       _dialogShown = true;

//       final nav = widget.navigatorKey?.currentState ?? Navigator.of(context);
//       await showDialog(
//         context: nav.context,
//         builder: (_) => _buildDialog(daysLeft),
//       );
//     }
//   }

//   Widget _buildDialog(int daysLeft) {
//     return AlertDialog(
//       title: const Text('Оплата подписки'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Осталось всего $daysLeft дней до отключения.'),
//           const SizedBox(height: 8),
//           const Text('Оплатите по реквизитам:\n'
//               'Номер: +7 ...\n'
//               'Банк: Альфа-банк\n'
//               'Получатель: Дмитрий П.'),
//         ],
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.of(context).pop(); 
//             // «Закрыть» — просто скрываем
//           },
//           child: const Text('Закрыть'),
//         ),
//         TextButton(
//           onPressed: () {
//             Navigator.of(context).pop();
//             // «Напомнить позже» — тоже скрываем,
//             // checkAndShowDialogIfNeeded не появится до перезапуска, 
//             // если _dialogShown=true (или вы сами решите логику).
//           },
//           child: const Text('Напомнить позже'),
//         ),
//         TextButton(
//           onPressed: () {
//             Navigator.of(context).pop();
//             // Здесь можете открыть ссылку, показать экран оплаты и т.д.
//           },
//           child: const Text('Оплатить'),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return widget.child;
//   }
// }
