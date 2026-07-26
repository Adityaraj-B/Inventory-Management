import '../models/shipment.dart';

abstract class ShipmentRepository {
  Future<Shipment> dispatchShipment({
    required String productId,
    required String productName,
    required int quantity,
    required String destinationWarehouseId,
    required String dispatchedByUserId,
  });

  Future<Shipment?> getShipmentById(String id);

  Future<void> receiveShipment({
    required String shipmentId,
    required String receivedByUserId,
  });

  Future<List<Shipment>> getPendingShipmentsForWarehouse(String warehouseId);
}
