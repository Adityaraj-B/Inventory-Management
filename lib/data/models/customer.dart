import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String? gstin;
  final double previousBalance;
  final String? warehouseId;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    this.gstin,
    required this.previousBalance,
    this.warehouseId,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? gstin,
    double? previousBalance,
    String? warehouseId,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      gstin: gstin ?? this.gstin,
      previousBalance: previousBalance ?? this.previousBalance,
      warehouseId: warehouseId ?? this.warehouseId,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      gstin: json['gstin'] as String?,
      previousBalance: (json['previous_balance'] as num?)?.toDouble() ?? 0.0,
      warehouseId: json['warehouse_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'gstin': gstin,
      'previous_balance': previousBalance,
      'warehouse_id': warehouseId,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    email,
    address,
    city,
    gstin,
    previousBalance,
    warehouseId,
  ];
}
