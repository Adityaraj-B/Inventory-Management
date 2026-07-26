import '../../models/product.dart';
import '../../models/stock_movement.dart';
import '../../repositories/product_repository.dart';

class MockProductRepository implements ProductRepository {
  final List<Product> _products = [
    Product(
      id: 'prod-101',
      name: 'Ultratech Cement (50kg Bag)',
      sku: 'CEM-UT-50KG',
      category: 'Construction Materials',
      unitPrice: 380.0,
      costPrice: 320.0,
      quantityInStock: 250,
      warehouseId: 'wh-1',
      lowStockThreshold: 50,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    Product(
      id: 'prod-102',
      name: 'TMT Steel Bar 12mm (per kg)',
      sku: 'STL-TMT-12MM',
      category: 'Steel & Metals',
      unitPrice: 65.0,
      costPrice: 52.0,
      quantityInStock: 1200,
      warehouseId: 'wh-1',
      lowStockThreshold: 200,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    Product(
      id: 'prod-103',
      name: 'Asian Paints Royale White 20L',
      sku: 'PNT-AP-20L',
      category: 'Paints & Finishes',
      unitPrice: 4200.0,
      costPrice: 3500.0,
      quantityInStock: 18,
      warehouseId: 'wh-2',
      lowStockThreshold: 25,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Product(
      id: 'prod-104',
      name: 'Havells Copper Wire 2.5sqmm (90m)',
      sku: 'ELE-HV-25MM',
      category: 'Electricals',
      unitPrice: 1850.0,
      costPrice: 1480.0,
      quantityInStock: 65,
      warehouseId: 'wh-2',
      lowStockThreshold: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Product(
      id: 'prod-105',
      name: 'Supreme PVC Pipe 4 inch (10ft)',
      sku: 'PLM-SUP-4IN',
      category: 'Plumbing',
      unitPrice: 450.0,
      costPrice: 360.0,
      quantityInStock: 80,
      warehouseId: 'wh-1',
      lowStockThreshold: 20,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
  ];

  final List<StockMovement> _movements = [
    StockMovement(
      id: 'sm-1',
      productId: 'prod-101',
      productName: 'Ultratech Cement (50kg Bag)',
      type: StockMovementType.inStock,
      delta: 100,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      reason: 'Bulk stock arrival from supplier',
    ),
    StockMovement(
      id: 'sm-2',
      productId: 'prod-103',
      productName: 'Asian Paints Royale White 20L',
      type: StockMovementType.outStock,
      delta: -10,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      reason: 'Dispatch to Retail Order #INV-1002',
    ),
    StockMovement(
      id: 'sm-3',
      productId: 'prod-104',
      productName: 'Havells Copper Wire 2.5sqmm (90m)',
      type: StockMovementType.adjustment,
      delta: 5,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      reason: 'Inventory audit count adjustment',
    ),
  ];

  @override
  Future<List<Product>> getProducts({
    String? searchQuery,
    String? warehouseId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _products.where((p) {
      if (warehouseId != null &&
          warehouseId.isNotEmpty &&
          p.warehouseId != warehouseId) {
        return false;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Product> addProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final existingIndex = _products.indexWhere(
      (p) =>
          p.warehouseId == product.warehouseId &&
          (p.sku.toLowerCase() == product.sku.toLowerCase() ||
              p.name.toLowerCase() == product.name.toLowerCase()),
    );

    if (existingIndex != -1) {
      final existing = _products[existingIndex];
      final updated = existing.copyWith(
        quantityInStock: existing.quantityInStock + product.quantityInStock,
        updatedAt: DateTime.now(),
      );
      _products[existingIndex] = updated;
      _movements.insert(
        0,
        StockMovement(
          id: 'sm-${DateTime.now().millisecondsSinceEpoch}',
          productId: existing.id,
          productName: existing.name,
          type: StockMovementType.inStock,
          delta: product.quantityInStock,
          timestamp: DateTime.now(),
          reason: 'Stock in intake (${product.quantityInStock} units added)',
        ),
      );
      return updated;
    } else {
      _products.insert(0, product);
      _movements.insert(
        0,
        StockMovement(
          id: 'sm-${DateTime.now().millisecondsSinceEpoch}',
          productId: product.id,
          productName: product.name,
          type: StockMovementType.inStock,
          delta: product.quantityInStock,
          timestamp: DateTime.now(),
          reason: 'New stock added to warehouse (HSN: ${product.sku})',
        ),
      );
      return product;
    }
  }

  @override
  Future<Product> updateProduct(Product product) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      final old = _products[index];
      final delta = product.quantityInStock - old.quantityInStock;
      if (delta != 0) {
        _movements.insert(
          0,
          StockMovement(
            id: 'sm-${DateTime.now().millisecondsSinceEpoch}',
            productId: product.id,
            productName: product.name,
            type: delta > 0
                ? StockMovementType.inStock
                : StockMovementType.outStock,
            delta: delta,
            timestamp: DateTime.now(),
            reason: 'Manual stock update',
          ),
        );
      }
      _products[index] = product;
    }
    return product;
  }

  @override
  Future<List<StockMovement>> getStockHistory({String? productId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (productId != null && productId.isNotEmpty) {
      return _movements.where((sm) => sm.productId == productId).toList();
    }
    return List.from(_movements);
  }

  @override
  Future<void> recordStockMovement(StockMovement movement) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _movements.insert(0, movement);
  }

  @override
  Future<void> transferStock({
    required String sourceProductId,
    required String sourceWarehouseId,
    required String targetWarehouseId,
    required int quantity,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final sourceIndex = _products.indexWhere((p) => p.id == sourceProductId);
    if (sourceIndex == -1) {
      throw Exception('Source product not found');
    }

    final sourceProduct = _products[sourceIndex];
    if (sourceProduct.quantityInStock < quantity) {
      throw Exception('Insufficient stock in source warehouse');
    }

    // Deduct quantity from source product
    _products[sourceIndex] = sourceProduct.copyWith(
      quantityInStock: sourceProduct.quantityInStock - quantity,
      updatedAt: DateTime.now(),
    );

    // Look for matching SKU in target warehouse
    final targetIndex = _products.indexWhere(
      (p) => p.warehouseId == targetWarehouseId && p.sku == sourceProduct.sku,
    );

    String targetProductId;
    if (targetIndex != -1) {
      final existingTarget = _products[targetIndex];
      _products[targetIndex] = existingTarget.copyWith(
        quantityInStock: existingTarget.quantityInStock + quantity,
        updatedAt: DateTime.now(),
      );
      targetProductId = existingTarget.id;
    } else {
      targetProductId = '${sourceProduct.id}-$targetWarehouseId';
      final newTargetProduct = Product(
        id: targetProductId,
        name: sourceProduct.name,
        sku: sourceProduct.sku,
        category: sourceProduct.category,
        unitPrice: sourceProduct.unitPrice,
        mrp: sourceProduct.mrp,
        costPrice: sourceProduct.costPrice,
        quantityInStock: quantity,
        warehouseId: targetWarehouseId,
        lowStockThreshold: sourceProduct.lowStockThreshold,
        unitsPerBarcode: sourceProduct.unitsPerBarcode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _products.add(newTargetProduct);
    }

    // Record out stock movement from source
    _movements.insert(
      0,
      StockMovement(
        id: 'sm-${DateTime.now().millisecondsSinceEpoch}-out',
        productId: sourceProduct.id,
        productName: sourceProduct.name,
        type: StockMovementType.outStock,
        delta: -quantity,
        timestamp: DateTime.now(),
        reason: 'Transferred out to Warehouse $targetWarehouseId',
      ),
    );

    // Record in stock movement to destination
    _movements.insert(
      0,
      StockMovement(
        id: 'sm-${DateTime.now().millisecondsSinceEpoch}-in',
        productId: targetProductId,
        productName: sourceProduct.name,
        type: StockMovementType.inStock,
        delta: quantity,
        timestamp: DateTime.now(),
        reason: 'Transferred in from Warehouse $sourceWarehouseId',
      ),
    );
  }
}
