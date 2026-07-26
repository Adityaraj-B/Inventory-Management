import 'package:equatable/equatable.dart';

class Warehouse extends Equatable {
  final String id;
  final String name;
  final String address;
  final bool isActive;
  final String contactPerson;
  final int productCount;
  final DateTime createdAt;

  const Warehouse({
    required this.id,
    required this.name,
    required this.address,
    required this.isActive,
    required this.contactPerson,
    required this.productCount,
    required this.createdAt,
  });

  Warehouse copyWith({
    String? id,
    String? name,
    String? address,
    bool? isActive,
    String? contactPerson,
    int? productCount,
    DateTime? createdAt,
  }) {
    return Warehouse(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      contactPerson: contactPerson ?? this.contactPerson,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      contactPerson: json['contact_person'] as String? ?? '',
      productCount: 0, // Computed from relations if needed
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'is_active': isActive,
      'contact_person': contactPerson,
      'code': name.substring(0, 3).toUpperCase(), // mock code
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    address,
    isActive,
    contactPerson,
    productCount,
    createdAt,
  ];
}
