import 'package:equatable/equatable.dart';
import '../../../data/models/product.dart';
import '../../../data/models/stock_movement.dart';
import '../../../data/models/shipment.dart';

abstract class StockState extends Equatable {
  const StockState();

  @override
  List<Object?> get props => [];
}

class StockInitial extends StockState {}

class StockLoading extends StockState {}

class StockLoaded extends StockState {
  final List<Product> products;
  final List<StockMovement> history;
  final String searchQuery;

  const StockLoaded({
    required this.products,
    required this.history,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [products, history, searchQuery];
}

class StockOperationSuccess extends StockState {
  final String message;
  final Shipment? shipment;

  const StockOperationSuccess(this.message, {this.shipment});

  @override
  List<Object?> get props => [message, shipment];
}

class StockError extends StockState {
  final String message;

  const StockError(this.message);

  @override
  List<Object?> get props => [message];
}
