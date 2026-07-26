import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/core/theme/app_text_styles.dart';
import 'package:vishnu_enterprises/core/widgets/app_card.dart';
import 'package:vishnu_enterprises/data/models/warehouse.dart';
import 'warehouse_status_chip.dart';

class WarehouseCard extends StatelessWidget {
  final Warehouse warehouse;
  final VoidCallback? onTap;

  const WarehouseCard({super.key, required this.warehouse, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.building_2_fill,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(warehouse.name, style: AppTextStyles.titleSmall),
                ],
              ),
              WarehouseStatusChip(isActive: warehouse.isActive),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            warehouse.address,
            style: AppTextStyles.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Contact: ${warehouse.contactPerson}',
                style: AppTextStyles.labelSmall,
              ),
              Text(
                '${warehouse.productCount} Products',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
