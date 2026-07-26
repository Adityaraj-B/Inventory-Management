import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class CurrencyText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final bool isNegativeColor;

  const CurrencyText({
    super.key,
    required this.amount,
    this.style,
    this.isNegativeColor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(Formatters.currency(amount), style: style);
  }
}
