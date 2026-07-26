import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/core/theme/app_text_styles.dart';
import 'package:vishnu_enterprises/core/utils/formatters.dart';
import 'package:vishnu_enterprises/core/widgets/app_card.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_ledger_cubit.dart';

class LedgerEntryTile extends StatelessWidget {
  final LedgerEntry entry;

  const LedgerEntryTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isInvoice =
        entry.type == LedgerEntryType.invoice ||
        entry.type == LedgerEntryType.openingBalance;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isInvoice
                ? AppColors.errorBackground
                : AppColors.successBackground,
            radius: 18,
            child: Icon(
              isInvoice
                  ? CupertinoIcons.doc_text_fill
                  : CupertinoIcons.arrow_down_left,
              size: 16,
              color: isInvoice ? AppColors.error : AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.description, style: AppTextStyles.titleSmall),
                const SizedBox(height: 2),
                Text(
                  Formatters.dateTime(entry.date),
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Running Balance: ', style: AppTextStyles.labelSmall),
                    Text(
                      Formatters.currency(entry.runningBalance),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: entry.runningBalance > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isInvoice
                    ? '+ ${Formatters.currency(entry.debit)}'
                    : '- ${Formatters.currency(entry.credit)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isInvoice ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isInvoice
                      ? AppColors.errorBackground
                      : AppColors.successBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isInvoice ? 'DEBIT' : 'CREDIT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isInvoice ? AppColors.error : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
