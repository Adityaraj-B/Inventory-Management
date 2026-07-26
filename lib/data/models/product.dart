import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String sku;
  final String category;
  final double unitPrice;
  final double costPrice;
  final int quantityInStock;
  final String warehouseId;
  final int lowStockThreshold;
  final double mrp;
  final int unitsPerBarcode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.unitPrice,
    double? mrp,
    required this.costPrice,
    required this.quantityInStock,
    required this.warehouseId,
    required this.lowStockThreshold,
    this.unitsPerBarcode = 10,
    required this.createdAt,
    required this.updatedAt,
  }) : mrp = mrp ?? unitPrice;

  bool get isLowStock => quantityInStock <= lowStockThreshold;

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    double? unitPrice,
    double? costPrice,
    int? quantityInStock,
    String? warehouseId,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      unitPrice: unitPrice ?? this.unitPrice,
      costPrice: costPrice ?? this.costPrice,
      quantityInStock: quantityInStock ?? this.quantityInStock,
      warehouseId: warehouseId ?? this.warehouseId,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Determine quantity from joined warehouse_stock array (if available)
    int stockQty = 0;
    String wId = '';
    int unitsPerBc = 10;

    if (json['warehouse_stock'] != null) {
      final stockList = json['warehouse_stock'] as List;
      if (stockList.isNotEmpty) {
        final stock = stockList.first;
        stockQty = (stock['barcode_unit_qty'] ?? 0) as int;
        wId = (stock['warehouse_id'] ?? '') as String;
        unitsPerBc = (stock['units_per_barcode'] ?? 10) as int;
      }
    }

    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['master_sku'] as String,
      category: json['category'] as String? ?? 'General',
      unitPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      mrp: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      quantityInStock: stockQty,
      warehouseId: wId,
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt() ?? 50,
      unitsPerBarcode: unitsPerBc,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt:
          DateTime.now(), // Supabase doesn't have updated_at on products currently
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'master_sku': sku,
      'category': category,
      'selling_price': unitPrice,
      'cost_price': costPrice,
      'low_stock_threshold': lowStockThreshold,
      'brand': 'Default', // required by schema
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    sku,
    category,
    unitPrice,
    mrp,
    costPrice,
    quantityInStock,
    warehouseId,
    lowStockThreshold,
    unitsPerBarcode,
    createdAt,
    updatedAt,
  ];
}
