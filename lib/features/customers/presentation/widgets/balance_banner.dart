import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/core/theme/app_text_styles.dart';
import 'package:vishnu_enterprises/core/utils/formatters.dart';

class BalanceBanner extends StatelessWidget {
  final double balance;

  const BalanceBanner({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final hasOutstanding = balance > 0;
    final bgColor = hasOutstanding
        ? AppColors.errorBackground
        : AppColors.successBackground;
    final textColor = hasOutstanding ? AppColors.error : AppColors.success;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasOutstanding
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasOutstanding
                  ? CupertinoIcons.exclamationmark_circle_fill
                  : CupertinoIcons.checkmark_seal_fill,
              color: textColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount Remaining to Come',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.currency(balance),
                  style: AppTextStyles.currencyLarge.copyWith(color: textColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              hasOutstanding ? 'DUE' : 'CLEAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
