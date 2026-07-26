class Supplier {
  final String id;
  final String warehouseId;
  final String name;
  final String phone;
  final double balanceRemaining;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Supplier({
    required this.id,
    required this.warehouseId,
    required this.name,
    required this.phone,
    this.balanceRemaining = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  Supplier copyWith({
    String? id,
    String? warehouseId,
    String? name,
    String? phone,
    double? balanceRemaining,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      warehouseId: warehouseId ?? this.warehouseId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      balanceRemaining: balanceRemaining ?? this.balanceRemaining,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Supplier.fromSupabase(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      warehouseId: json['warehouse_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      balanceRemaining: _toDouble(json['balance_remaining']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'warehouse_id': warehouseId,
      'name': name,
      'phone': phone,
      'balance_remaining': balanceRemaining,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return (value as num).toDouble();
  }
}
