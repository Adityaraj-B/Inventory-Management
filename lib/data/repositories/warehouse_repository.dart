import '../models/warehouse.dart';

abstract class WarehouseRepository {
  Future<List<Warehouse>> getWarehouses({
    bool? activeOnly,
    String? searchQuery,
  });
  Future<Warehouse?> getWarehouseById(String id);
  Future<Warehouse> addWarehouse(Warehouse warehouse);
  Future<Warehouse> updateWarehouse(Warehouse warehouse);
}
