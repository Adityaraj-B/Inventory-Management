import '../../models/warehouse.dart';
import '../../repositories/warehouse_repository.dart';

class MockWarehouseRepository implements WarehouseRepository {
  final List<Warehouse> _warehouses = [
    Warehouse(
      id: 'wh-1',
      name: 'Main Central Depot',
      address: 'Plot 45, Industrial Area Phase II, New Delhi',
      isActive: true,
      contactPerson: 'Suresh Patel (+91 98765 43210)',
      productCount: 42,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
    Warehouse(
      id: 'wh-2',
      name: 'North Logistics Hub',
      address: 'Sector 18, Transport Nagar, Gurugram',
      isActive: true,
      contactPerson: 'Vikram Singh (+91 98123 88990)',
      productCount: 28,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    ),
    Warehouse(
      id: 'wh-3',
      name: 'South Distribution Center',
      address: 'Block C, Ring Road, Faridabad',
      isActive: false,
      contactPerson: 'Ramesh Verma (+91 97111 22334)',
      productCount: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
  ];

  @override
  Future<List<Warehouse>> getWarehouses({
    bool? activeOnly,
    String? searchQuery,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _warehouses.where((w) {
      if (activeOnly == true && !w.isActive) return false;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return w.name.toLowerCase().contains(q) ||
            w.address.toLowerCase().contains(q) ||
            w.contactPerson.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Future<Warehouse?> getWarehouseById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _warehouses.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Warehouse> addWarehouse(Warehouse warehouse) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _warehouses.add(warehouse);
    return warehouse;
  }

  @override
  Future<Warehouse> updateWarehouse(Warehouse warehouse) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _warehouses.indexWhere((w) => w.id == warehouse.id);
    if (index != -1) {
      _warehouses[index] = warehouse;
    }
    return warehouse;
  }
}
