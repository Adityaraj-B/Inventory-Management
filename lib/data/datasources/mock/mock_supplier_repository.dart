import '../../models/supplier.dart';
import '../../models/supplier_item.dart';
import '../../models/supplier_invoice.dart';
import '../../repositories/supplier_repository.dart';

class MockSupplierRepository implements SupplierRepository {
  final List<Supplier> _suppliers = [
    Supplier(
      id: 'sup-1',
      name: 'National Cement Corporation',
      phone: '+91 98220 11223',
      balanceRemaining: 150000.0,
      warehouseId: 'wh-1',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Supplier(
      id: 'sup-2',
      name: 'Steel Authority Supply Ltd',
      phone: '+91 98111 44556',
      balanceRemaining: 75000.0,
      warehouseId: 'wh-1',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    Supplier(
      id: 'sup-3',
      name: 'Apex Electricals Distributors',
      phone: '+91 98990 77889',
      balanceRemaining: 32000.0,
      warehouseId: 'wh-2',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Supplier(
      id: 'sup-4',
      name: 'Global Hardware & Tools',
      phone: '+91 97112 33445',
      balanceRemaining: 0.0,
      warehouseId: 'wh-3',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  @override
  Future<List<Supplier>> getSuppliers({
    String? warehouseId,
    String? searchQuery,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _suppliers.where((s) {
      if (warehouseId != null &&
          warehouseId.isNotEmpty &&
          s.warehouseId != warehouseId) {
        return false;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return s.name.toLowerCase().contains(q) ||
            s.phone.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Future<Supplier?> getSupplierById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Supplier> addSupplier(Supplier supplier) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _suppliers.insert(0, supplier);
    return supplier;
  }

  @override
  Future<Supplier> updateSupplier(Supplier supplier) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (index != -1) {
      _suppliers[index] = supplier;
    }
    return supplier;
  }

  final List<SupplierItem> _supplierItems = [
    const SupplierItem(
      id: 'item-1',
      supplierId: 'sup-1',
      name: 'Cement Bag (50kg)',
      costPrice: 350.0,
    ),
    const SupplierItem(
      id: 'item-2',
      supplierId: 'sup-1',
      name: 'White Cement (5kg)',
      costPrice: 120.0,
    ),
    const SupplierItem(
      id: 'item-3',
      supplierId: 'sup-2',
      name: 'TMT Bar 12mm',
      costPrice: 85.0,
    ),
  ];

  final List<SupplierInvoice> _supplierInvoices = [];

  @override
  Future<List<SupplierItem>> getSupplierItems(String supplierId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _supplierItems
        .where((item) => item.supplierId == supplierId)
        .toList();
  }

  @override
  Future<SupplierItem> addSupplierItem(SupplierItem item) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _supplierItems.add(item);
    return item;
  }

  @override
  Future<List<SupplierInvoice>> getSupplierInvoices(String warehouseId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _supplierInvoices
        .where((inv) => inv.warehouseId == warehouseId)
        .toList();
  }

  @override
  Future<SupplierInvoice> createSupplierInvoice(SupplierInvoice invoice) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _supplierInvoices.insert(0, invoice);

    // Optionally update supplier balance
    final supplierIndex = _suppliers.indexWhere(
      (s) => s.id == invoice.supplierId,
    );
    if (supplierIndex != -1) {
      final old = _suppliers[supplierIndex];
      _suppliers[supplierIndex] = old.copyWith(
        balanceRemaining: old.balanceRemaining + invoice.totalAmount,
      );
    }

    return invoice;
  }
}
