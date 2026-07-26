import 'package:flutter/cupertino.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/core/theme/app_text_styles.dart';
import 'package:vishnu_enterprises/core/utils/formatters.dart';
import 'package:vishnu_enterprises/core/widgets/app_card.dart';
import 'package:vishnu_enterprises/data/models/product.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductTile({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: product.isLowStock
                  ? AppColors.errorBackground
                  : AppColors.successBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              product.isLowStock
                  ? CupertinoIcons.exclamationmark_triangle_fill
                  : CupertinoIcons.cube_box_fill,
              color: product.isLowStock ? AppColors.error : AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'SKU: ${product.sku} • Category: ${product.category}',
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      'Unit Price: ${Formatters.currency(product.unitPrice)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '(Cost: ${Formatters.currency(product.costPrice)})',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: product.isLowStock
                      ? AppColors.errorBackground
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${product.quantityInStock} in stock',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: product.isLowStock
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
