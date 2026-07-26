import 'package:equatable/equatable.dart';

class SupplierInvoiceLineItem extends Equatable {
  final String? supplierItemId;
  final String itemName;
  final double costPrice;
  final int numBoxes;
  final int numUnits;
  final double costPerUnit;
  final double lineTotal;

  const SupplierInvoiceLineItem({
    this.supplierItemId,
    required this.itemName,
    required this.costPrice,
    required this.numBoxes,
    required this.numUnits,
    required this.costPerUnit,
    required this.lineTotal,
  });

  @override
  List<Object?> get props => [
    supplierItemId,
    itemName,
    costPrice,
    numBoxes,
    numUnits,
    costPerUnit,
    lineTotal,
  ];
}
