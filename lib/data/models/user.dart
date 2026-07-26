import 'package:equatable/equatable.dart';
import '../../core/constants.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' | 'billing_staff'
  final String? linkedWarehouseId;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.linkedWarehouseId,
  });

  bool get isAdmin => role == AppConstants.roleAdmin;
  bool get isBillingStaff => role == AppConstants.roleBillingStaff;

  String? get warehouseId => linkedWarehouseId;

  bool get canManageProducts => isAdmin;
  bool get canAccessStockIn => true;
  bool get canManageCustomers => isAdmin;
  bool get canAccessBilling => true;

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? linkedWarehouseId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      linkedWarehouseId: linkedWarehouseId ?? this.linkedWarehouseId,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email:
          json['email'] as String? ??
          '', // not strictly in profiles but good to have fallback
      role: json['role'] as String,
      linkedWarehouseId: json['warehouse_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'warehouse_id': linkedWarehouseId,
    };
  }

  @override
  List<Object?> get props => [id, name, email, role, linkedWarehouseId];
}
