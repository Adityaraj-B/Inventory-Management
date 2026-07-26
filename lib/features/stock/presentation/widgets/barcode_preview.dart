import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/core/theme/app_text_styles.dart';
import 'package:vishnu_enterprises/core/utils/barcode_generator.dart';

class BarcodePreview extends StatelessWidget {
  final String productName;
  final String sku;

  const BarcodePreview({
    super.key,
    required this.productName,
    required this.sku,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Barcode Preview (Code128)',
                style: AppTextStyles.labelMedium,
              ),
              IconButton(
                icon: const Icon(
                  CupertinoIcons.printer_fill,
                  size: 20,
                  color: AppColors.accent,
                ),
                onPressed: () => BarcodeGenerator.printProductBarcodePdf(
                  productName: productName.isEmpty
                      ? 'New Product'
                      : productName,
                  sku: sku.isEmpty ? 'SKU-TEMP' : sku,
                ),
                tooltip: 'Print / Export Barcode PDF',
              ),
            ],
          ),
          const SizedBox(height: 12),
          BarcodeWidget(
            barcode: Barcode.code128(),
            data: sku.isEmpty ? 'SKU-PREVIEW-123' : sku,
            width: 220,
            height: 70,
            drawText: true,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
