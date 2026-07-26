import 'package:equatable/equatable.dart';

enum StockMovementType { inStock, outStock, adjustment }

class StockMovement extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final StockMovementType type;
  final int delta;
  final DateTime timestamp;
  final String reason;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.delta,
    required this.timestamp,
    required this.reason,
  });

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    type,
    delta,
    timestamp,
    reason,
  ];
}
