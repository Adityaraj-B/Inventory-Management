import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/shipment_repository.dart';
import 'stock_event.dart';
import 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final ProductRepository _productRepository;
  final ShipmentRepository _shipmentRepository;

  StockBloc({
    required ProductRepository productRepository,
    required ShipmentRepository shipmentRepository,
  }) : _productRepository = productRepository,
       _shipmentRepository = shipmentRepository,
       super(StockInitial()) {
    on<StockLoadRequested>(_onLoad);
    on<StockSearchChanged>(_onSearchChanged);
    on<AddProductRequested>(_onAddProduct);
    on<UpdateProductRequested>(_onUpdateProduct);
    on<StockHistoryLoadRequested>(_onLoadHistory);
    on<TransferStockRequested>(_onTransferStock);
  }

  Future<void> _onLoad(
    StockLoadRequested event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoading());
    try {
      final products = await _productRepository.getProducts(
        searchQuery: event.searchQuery,
        warehouseId: event.warehouseId,
      );
      final history = await _productRepository.getStockHistory();
      emit(
        StockLoaded(
          products: products,
          history: history,
          searchQuery: event.searchQuery ?? '',
        ),
      );
    } catch (e) {
      emit(StockError(e.toString()));
    }
  }

  Future<void> _onSearchChanged(
    StockSearchChanged event,
    Emitter<StockState> emit,
  ) async {
    try {
      final products = await _productRepository.getProducts(
        searchQuery: event.query,
        warehouseId: event.warehouseId,
      );
      final history = await _productRepository.getStockHistory();
      emit(
        StockLoaded(
          products: products,
          history: history,
          searchQuery: event.query,
        ),
      );
    } catch (e) {
      emit(StockError(e.toString()));
    }
  }

  Future<void> _onAddProduct(
    AddProductRequested event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoading());
    try {
      // 1. Create product with 0 quantity initially, as it's in transit
      final productToCreate = event.product.copyWith(quantityInStock: 0);
      await _productRepository.addProduct(productToCreate);

      // 2. Dispatch a shipment for the initial stock
      final shipment = await _shipmentRepository.dispatchShipment(
        productId: productToCreate.id,
        productName: productToCreate.name,
        quantity:
            event.product.quantityInStock, // The quantity Admin wants to add
        destinationWarehouseId: productToCreate.warehouseId,
        dispatchedByUserId:
            'admin', // Ideally fetched from auth state, but hardcoded admin for now
      );

      final products = await _productRepository.getProducts();
      final history = await _productRepository.getStockHistory();
      emit(
        StockOperationSuccess(
          'Stock dispatched successfully',
          shipment: shipment,
        ),
      );
      emit(StockLoaded(products: products, history: history));
    } catch (e) {
      emit(StockError(e.toString()));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProductRequested event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoading());
    try {
      await _productRepository.updateProduct(event.product);
      final products = await _productRepository.getProducts();
      final history = await _productRepository.getStockHistory();
      emit(const StockOperationSuccess('Product updated successfully'));
      emit(StockLoaded(products: products, history: history));
    } catch (e) {
      emit(StockError(e.toString()));
    }
  }

  Future<void> _onLoadHistory(
    StockHistoryLoadRequested event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoading());
    try {
      final products = await _productRepository.getProducts();
      final history = await _productRepository.getStockHistory(
        productId: event.productId,
      );
      emit(StockLoaded(products: products, history: history));
    } catch (e) {
      emit(StockError(e.toString()));
    }
  }

  Future<void> _onTransferStock(
    TransferStockRequested event,
    Emitter<StockState> emit,
  ) async {
    emit(StockLoading());
    try {
      await _productRepository.transferStock(
        sourceProductId: event.sourceProductId,
        sourceWarehouseId: event.sourceWarehouseId,
        targetWarehouseId: event.targetWarehouseId,
        quantity: event.quantity,
      );
      final products = await _productRepository.getProducts();
      final history = await _productRepository.getStockHistory();
      emit(const StockOperationSuccess('Stock transferred successfully'));
      emit(StockLoaded(products: products, history: history));
    } catch (e) {
      emit(StockError(e.toString()));
    }
  }
}
