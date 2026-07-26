import 'package:equatable/equatable.dart';
import '../../../data/models/warehouse.dart';

abstract class WarehouseEvent extends Equatable {
  const WarehouseEvent();

  @override
  List<Object?> get props => [];
}

class WarehouseLoadRequested extends WarehouseEvent {
  final bool? activeOnly;
  final String? searchQuery;

  const WarehouseLoadRequested({this.activeOnly, this.searchQuery});

  @override
  List<Object?> get props => [activeOnly, searchQuery];
}

class AddWarehouseRequested extends WarehouseEvent {
  final Warehouse warehouse;

  const AddWarehouseRequested(this.warehouse);

  @override
  List<Object?> get props => [warehouse];
}

class UpdateWarehouseRequested extends WarehouseEvent {
  final Warehouse warehouse;

  const UpdateWarehouseRequested(this.warehouse);

  @override
  List<Object?> get props => [warehouse];
}
