import '../models/product.dart';
import '../models/stock_movement.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({String? searchQuery, String? warehouseId});
  Future<Product?> getProductById(String id);
  Future<Product> addProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<List<StockMovement>> getStockHistory({String? productId});
  Future<void> recordStockMovement(StockMovement movement);
  Future<void> transferStock({
    required String sourceProductId,
    required String sourceWarehouseId,
    required String targetWarehouseId,
    required int quantity,
  });
}
