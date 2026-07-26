import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/warehouse_repository.dart';
import 'warehouse_event.dart';
import 'warehouse_state.dart';

class WarehouseBloc extends Bloc<WarehouseEvent, WarehouseState> {
  final WarehouseRepository _warehouseRepository;

  WarehouseBloc({required WarehouseRepository warehouseRepository})
    : _warehouseRepository = warehouseRepository,
      super(WarehouseInitial()) {
    on<WarehouseLoadRequested>(_onLoad);
    on<AddWarehouseRequested>(_onAddWarehouse);
    on<UpdateWarehouseRequested>(_onUpdateWarehouse);
  }

  Future<void> _onLoad(
    WarehouseLoadRequested event,
    Emitter<WarehouseState> emit,
  ) async {
    emit(WarehouseLoading());
    try {
      final warehouses = await _warehouseRepository.getWarehouses(
        activeOnly: event.activeOnly,
        searchQuery: event.searchQuery,
      );
      emit(
        WarehouseLoaded(
          warehouses: warehouses,
          activeOnlyFilter: event.activeOnly,
        ),
      );
    } catch (e) {
      emit(WarehouseError(e.toString()));
    }
  }

  Future<void> _onAddWarehouse(
    AddWarehouseRequested event,
    Emitter<WarehouseState> emit,
  ) async {
    emit(WarehouseLoading());
    try {
      await _warehouseRepository.addWarehouse(event.warehouse);
      final warehouses = await _warehouseRepository.getWarehouses();
      emit(const WarehouseOperationSuccess('Warehouse created successfully'));
      emit(WarehouseLoaded(warehouses: warehouses));
    } catch (e) {
      emit(WarehouseError(e.toString()));
    }
  }

  Future<void> _onUpdateWarehouse(
    UpdateWarehouseRequested event,
    Emitter<WarehouseState> emit,
  ) async {
    emit(WarehouseLoading());
    try {
      await _warehouseRepository.updateWarehouse(event.warehouse);
      final warehouses = await _warehouseRepository.getWarehouses();
      emit(const WarehouseOperationSuccess('Warehouse details saved'));
      emit(WarehouseLoaded(warehouses: warehouses));
    } catch (e) {
      emit(WarehouseError(e.toString()));
    }
  }
}
