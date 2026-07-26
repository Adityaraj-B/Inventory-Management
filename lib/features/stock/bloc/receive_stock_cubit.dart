import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/shipment.dart';
import '../../../data/repositories/shipment_repository.dart';
import '../../../data/repositories/product_repository.dart';

abstract class ReceiveStockState extends Equatable {
  const ReceiveStockState();

  @override
  List<Object?> get props => [];
}

class ReceiveStockInitial extends ReceiveStockState {}

class ReceiveStockLoading extends ReceiveStockState {}

class ReceiveStockShipmentFound extends ReceiveStockState {
  final Shipment shipment;

  const ReceiveStockShipmentFound(this.shipment);

  @override
  List<Object?> get props => [shipment];
}

class ReceiveStockSuccess extends ReceiveStockState {
  final String message;

  const ReceiveStockSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ReceiveStockError extends ReceiveStockState {
  final String message;

  const ReceiveStockError(this.message);

  @override
  List<Object?> get props => [message];
}

class ReceiveStockCubit extends Cubit<ReceiveStockState> {
  final ShipmentRepository _shipmentRepository;
  final ProductRepository _productRepository;

  ReceiveStockCubit({
    required ShipmentRepository shipmentRepository,
    required ProductRepository productRepository,
  }) : _shipmentRepository = shipmentRepository,
       _productRepository = productRepository,
       super(ReceiveStockInitial());

  Future<void> scanShipment(String barcode) async {
    emit(ReceiveStockLoading());
    try {
      final shipment = await _shipmentRepository.getShipmentById(barcode);
      if (shipment == null) {
        emit(const ReceiveStockError('Shipment not found for this barcode.'));
      } else if (shipment.status == ShipmentStatus.received) {
        emit(
          const ReceiveStockError('This shipment has already been received.'),
        );
      } else {
        emit(ReceiveStockShipmentFound(shipment));
      }
    } catch (e) {
      emit(ReceiveStockError(e.toString()));
    }
  }

  Future<void> confirmReceipt(
    String shipmentId,
    String receivedByUserId,
  ) async {
    emit(ReceiveStockLoading());
    try {
      final shipment = await _shipmentRepository.getShipmentById(shipmentId);
      if (shipment == null) throw Exception('Shipment not found');

      // 1. Receive shipment in repo
      await _shipmentRepository.receiveShipment(
        shipmentId: shipmentId,
        receivedByUserId: receivedByUserId,
      );

      // 2. Add stock to warehouse
      final products = await _productRepository.getProducts();
      final product = products.firstWhere((p) => p.id == shipment.productId);

      final updatedProduct = product.copyWith(
        quantityInStock: product.quantityInStock + shipment.quantity,
      );
      await _productRepository.updateProduct(updatedProduct);

      emit(const ReceiveStockSuccess('Stock received successfully.'));
    } catch (e) {
      emit(ReceiveStockError(e.toString()));
    }
  }
}
