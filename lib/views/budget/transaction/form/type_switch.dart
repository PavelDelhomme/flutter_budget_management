import 'package:flutter/material.dart';

class TypeSwitch extends StatelessWidget {
  final bool isDebit;
  final bool isTransactionExisting;
  final ValueChanged<bool> onTypeChange;

  const TypeSwitch({
    Key? key,
    required this.isDebit,
    required this.isTransactionExisting,
    required this.onTypeChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Type: "),
        const Text("Credit"),
        Tooltip(
          message: isTransactionExisting ? "Type non modifiable pour une transaction existante" : "",
          child: Switch(
            value: isDebit,
            onChanged: isTransactionExisting ? null : onTypeChange,
          ),
        ),
        const Text("Debit"),
      ],
    );
  }
}
