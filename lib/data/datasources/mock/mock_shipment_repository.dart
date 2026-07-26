import 'dart:math';
import '../../models/shipment.dart';
import '../../repositories/shipment_repository.dart';

class MockShipmentRepository implements ShipmentRepository {
  final List<Shipment> _shipments = [];
  final _random = Random();

  @override
  Future<Shipment> dispatchShipment({
    required String productId,
    required String productName,
    required int quantity,
    required String destinationWarehouseId,
    required String dispatchedByUserId,
  }) async {
    // Generate a unique barcode (e.g. SHP-XXXXX)
    final barcodeId = 'SHP-${_random.nextInt(90000) + 10000}';

    final shipment = Shipment(
      id: barcodeId,
      productId: productId,
      productName: productName,
      quantity: quantity,
      destinationWarehouseId: destinationWarehouseId,
      status: ShipmentStatus.pending,
      createdAt: DateTime.now(),
      dispatchedByUserId: dispatchedByUserId,
    );

    _shipments.add(shipment);
    return shipment;
  }

  @override
  Future<Shipment?> getShipmentById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _shipments.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> receiveShipment({
    required String shipmentId,
    required String receivedByUserId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _shipments.indexWhere((s) => s.id == shipmentId);
    if (index == -1) {
      throw Exception('Shipment not found');
    }

    final shipment = _shipments[index];
    if (shipment.status == ShipmentStatus.received) {
      throw Exception('Shipment is already received');
    }

    _shipments[index] = shipment.copyWith(
      status: ShipmentStatus.received,
      receivedAt: DateTime.now(),
      receivedByUserId: receivedByUserId,
    );
  }

  @override
  Future<List<Shipment>> getPendingShipmentsForWarehouse(
    String warehouseId,
  ) async {
    return _shipments
        .where(
          (s) =>
              s.destinationWarehouseId == warehouseId &&
              s.status == ShipmentStatus.pending,
        )
        .toList();
  }
}
