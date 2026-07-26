import 'package:equatable/equatable.dart';
import '../../../data/models/product.dart';

abstract class StockEvent extends Equatable {
  const StockEvent();

  @override
  List<Object?> get props => [];
}

class StockLoadRequested extends StockEvent {
  final String? searchQuery;
  final String? warehouseId;

  const StockLoadRequested({this.searchQuery, this.warehouseId});

  @override
  List<Object?> get props => [searchQuery, warehouseId];
}

class StockSearchChanged extends StockEvent {
  final String query;
  final String? warehouseId;

  const StockSearchChanged(this.query, {this.warehouseId});

  @override
  List<Object?> get props => [query, warehouseId];
}

class AddProductRequested extends StockEvent {
  final Product product;

  const AddProductRequested(this.product);

  @override
  List<Object?> get props => [product];
}

class UpdateProductRequested extends StockEvent {
  final Product product;

  const UpdateProductRequested(this.product);

  @override
  List<Object?> get props => [product];
}

class StockHistoryLoadRequested extends StockEvent {
  final String? productId;

  const StockHistoryLoadRequested({this.productId});

  @override
  List<Object?> get props => [productId];
}

class TransferStockRequested extends StockEvent {
  final String sourceProductId;
  final String sourceWarehouseId;
  final String targetWarehouseId;
  final int quantity;

  const TransferStockRequested({
    required this.sourceProductId,
    required this.sourceWarehouseId,
    required this.targetWarehouseId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [
    sourceProductId,
    sourceWarehouseId,
    targetWarehouseId,
    quantity,
  ];
}
