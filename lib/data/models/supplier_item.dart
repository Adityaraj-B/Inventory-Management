import 'package:equatable/equatable.dart';

class SupplierItem extends Equatable {
  final String id;
  final String supplierId;
  final String name;
  final double costPrice;

  const SupplierItem({
    required this.id,
    required this.supplierId,
    required this.name,
    required this.costPrice,
  });

  @override
  List<Object?> get props => [id, supplierId, name, costPrice];
}
