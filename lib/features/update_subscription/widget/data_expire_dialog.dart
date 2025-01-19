import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DataExpireDialog extends HookConsumerWidget {
  DataExpireDialog({
    required this.daysLeft,
    Key? key,
    this.canIgnore = true,
  }) : super(key: key);

  final int daysLeft;
  final bool canIgnore;

  // Можно сделать static key, чтобы проверять «уже открыт или нет»
  static final _dialogKey = GlobalKey(debugLabel: 'data-expire-dialog');

  /// Показывает диалог (если не открыт)
  Future<void> show(BuildContext context) async {
    if (_dialogKey.currentContext == null) {
      return showDialog(
        context: context,
        builder: (_) => this,
      );
    } else {
      debugPrint("DataExpireDialog is already open");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Здесь можно подключить любую локализацию/тексты
    // или просто «зашить» строки
    final theme = Theme.of(context);

    return AlertDialog(
      key: _dialogKey,
      title: Text(
        'Оплата подписки',
        style: theme.textTheme.titleLarge,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('До окончания подписки осталось $daysLeft дней.'),
          const Gap(8),
          Text(
            'Пожалуйста, оплатите по реквизитам:',
            style: theme.textTheme.bodyMedium,
          ),
          const Gap(8),
          Text(
            'Номер телефона: +7 (908) 185-18-07\n'
            'Банк: Альфа-банк\n'
            'Получатель: Дмитрий П.',
            style: theme.textTheme.bodyMedium,
          ),
          const Gap(8),
          Text(
            'Иначе доступ будет отключён.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent),
          ),
        ],
      ),
      actions: [
        if (canIgnore)
          TextButton(
            onPressed: () {
              // например, просто закрыть диалог
              // (или сохранить в SharedPreferences, что «больше не показывать»)
              Navigator.of(context).pop();
            },
            child: const Text('Закрыть'),
          ),
        TextButton(
          onPressed: () {
            // «Напомнить позже» —
            // можно просто закрыть диалог: 
            // логика «показать ещё раз через X часов» будет в вашем checkSubscriptionExpiry
            Navigator.of(context).pop();
          },
          child: const Text('Напомнить позже'),
        ),
        TextButton(
          onPressed: () {
            // «Оплатить сейчас» —
            // Можно открыть ссылку, или показать какой-то экран оплаты
            // или просто закрыть диалог.
            Navigator.of(context).pop();
          },
          child: const Text('Оплатить'),
        ),
      ],
    );
  }
}
