import 'package:equatable/equatable.dart';

enum ShipmentStatus { pending, received }

class Shipment extends Equatable {
  final String id; // Represents the unique barcode e.g., SHP-XXXX
  final String productId;
  final String productName;
  final int quantity;
  final String destinationWarehouseId;
  final ShipmentStatus status;
  final DateTime createdAt;
  final DateTime? receivedAt;
  final String dispatchedByUserId;
  final String? receivedByUserId;

  const Shipment({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.destinationWarehouseId,
    required this.status,
    required this.createdAt,
    this.receivedAt,
    required this.dispatchedByUserId,
    this.receivedByUserId,
  });

  Shipment copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    String? destinationWarehouseId,
    ShipmentStatus? status,
    DateTime? createdAt,
    DateTime? receivedAt,
    String? dispatchedByUserId,
    String? receivedByUserId,
  }) {
    return Shipment(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      destinationWarehouseId:
          destinationWarehouseId ?? this.destinationWarehouseId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      receivedAt: receivedAt ?? this.receivedAt,
      dispatchedByUserId: dispatchedByUserId ?? this.dispatchedByUserId,
      receivedByUserId: receivedByUserId ?? this.receivedByUserId,
    );
  }

  factory Shipment.fromJson(Map<String, dynamic> json) {
    // Assuming join with stock_entry_items
    String pId = '';
    String pName = '';
    int qty = 0;

    if (json['stock_entry_items'] != null) {
      final items = json['stock_entry_items'] as List;
      if (items.isNotEmpty) {
        pId = items.first['product_id'] as String;
        pName = items.first['product_name'] as String? ?? 'Unknown Product';
        qty = (items.first['barcode_unit_qty'] as num?)?.toInt() ?? 0;
      }
    }

    return Shipment(
      id: json['id'] as String,
      productId: pId,
      productName: pName,
      quantity: qty,
      destinationWarehouseId: json['destination_warehouse_id'] as String? ?? '',
      status: json['status'] == 'received'
          ? ShipmentStatus.received
          : ShipmentStatus.pending,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      dispatchedByUserId: json['user_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destination_warehouse_id': destinationWarehouseId,
      'status': status == ShipmentStatus.received ? 'received' : 'pending',
      'user_id': dispatchedByUserId,
    };
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    quantity,
    destinationWarehouseId,
    status,
    createdAt,
    receivedAt,
    dispatchedByUserId,
    receivedByUserId,
  ];
}
