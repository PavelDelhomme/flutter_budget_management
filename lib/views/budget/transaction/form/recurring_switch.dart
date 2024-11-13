import 'package:flutter/material.dart';

class RecurringSwitch extends StatelessWidget {
  final bool isRecurring;
  final ValueChanged<bool> onRecurringChange;

  const RecurringSwitch({
    Key? key,
    required this.isRecurring,
    required this.onRecurringChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Récurrente"),
        Switch(
          value: isRecurring,
          onChanged: onRecurringChange,
        ),
      ],
    );
  }
}
