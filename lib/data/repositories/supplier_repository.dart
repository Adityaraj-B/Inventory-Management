import '../models/supplier.dart';
import '../models/supplier_item.dart';
import '../models/supplier_invoice.dart';

abstract class SupplierRepository {
  Future<List<Supplier>> getSuppliers({
    String? warehouseId,
    String? searchQuery,
  });
  Future<Supplier?> getSupplierById(String id);
  Future<Supplier> addSupplier(Supplier supplier);
  Future<Supplier> updateSupplier(Supplier supplier);

  Future<List<SupplierItem>> getSupplierItems(String supplierId);
  Future<SupplierItem> addSupplierItem(SupplierItem item);
  Future<List<SupplierInvoice>> getSupplierInvoices(String warehouseId);
  Future<SupplierInvoice> createSupplierInvoice(SupplierInvoice invoice);
}
