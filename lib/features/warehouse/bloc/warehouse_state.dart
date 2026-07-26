import 'package:equatable/equatable.dart';
import '../../../data/models/warehouse.dart';

abstract class WarehouseState extends Equatable {
  const WarehouseState();

  @override
  List<Object?> get props => [];
}

class WarehouseInitial extends WarehouseState {}

class WarehouseLoading extends WarehouseState {}

class WarehouseLoaded extends WarehouseState {
  final List<Warehouse> warehouses;
  final bool? activeOnlyFilter;

  const WarehouseLoaded({required this.warehouses, this.activeOnlyFilter});

  @override
  List<Object?> get props => [warehouses, activeOnlyFilter];
}

class WarehouseOperationSuccess extends WarehouseState {
  final String message;

  const WarehouseOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class WarehouseError extends WarehouseState {
  final String message;

  const WarehouseError(this.message);

  @override
  List<Object?> get props => [message];
}
