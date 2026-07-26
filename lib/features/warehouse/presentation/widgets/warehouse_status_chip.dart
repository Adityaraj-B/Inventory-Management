import 'package:flutter/material.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';

class WarehouseStatusChip extends StatelessWidget {
  final bool isActive;

  const WarehouseStatusChip({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successBackground : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive
              ? AppColors.activeChip.withValues(alpha: 0.3)
              : AppColors.inactiveChip.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.activeChip : AppColors.inactiveChip,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.activeChip : AppColors.inactiveChip,
            ),
          ),
        ],
      ),
    );
  }
}
