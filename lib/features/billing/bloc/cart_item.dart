import 'package:equatable/equatable.dart';
import '../../../data/models/product.dart';

enum SellMode { piece, innerBox }

class CartItem extends Equatable {
  final Product product;
  final int rawQuantity;
  final SellMode sellMode;
  final double customUnitPrice;

  const CartItem({
    required this.product,
    required this.rawQuantity,
    this.sellMode = SellMode.piece,
    required this.customUnitPrice,
  });

  int get totalUnits => sellMode == SellMode.innerBox
      ? rawQuantity * product.unitsPerBarcode
      : rawQuantity;

  double get rate => customUnitPrice;

  double get subtotal => totalUnits * rate;

  CartItem copyWith({
    Product? product,
    int? rawQuantity,
    SellMode? sellMode,
    double? customUnitPrice,
  }) {
    return CartItem(
      product: product ?? this.product,
      rawQuantity: rawQuantity ?? this.rawQuantity,
      sellMode: sellMode ?? this.sellMode,
      customUnitPrice: customUnitPrice ?? this.customUnitPrice,
    );
  }

  @override
  List<Object?> get props => [product, rawQuantity, sellMode, customUnitPrice];
}
