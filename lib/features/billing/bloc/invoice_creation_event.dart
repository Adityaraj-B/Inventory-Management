import 'package:equatable/equatable.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/product.dart';
import '../../../data/models/user.dart';
import 'cart_item.dart';

abstract class InvoiceCreationEvent extends Equatable {
  const InvoiceCreationEvent();

  @override
  List<Object?> get props => [];
}

class AddProductToCart extends InvoiceCreationEvent {
  final Product product;
  final int quantity;
  final SellMode sellMode;
  final double? unitPrice;
  final User currentUser;

  const AddProductToCart({
    required this.product,
    this.quantity = 1,
    this.sellMode = SellMode.piece,
    this.unitPrice,
    required this.currentUser,
  });

  @override
  List<Object?> get props => [
    product,
    quantity,
    sellMode,
    unitPrice,
    currentUser,
  ];
}

class UpdateCartItem extends InvoiceCreationEvent {
  final String productId;
  final int quantity;
  final SellMode? sellMode;
  final double? unitPrice;
  final User currentUser;

  const UpdateCartItem({
    required this.productId,
    required this.quantity,
    this.sellMode,
    this.unitPrice,
    required this.currentUser,
  });

  @override
  List<Object?> get props => [
    productId,
    quantity,
    sellMode,
    unitPrice,
    currentUser,
  ];
}

class RemoveCartItem extends InvoiceCreationEvent {
  final String productId;

  const RemoveCartItem(this.productId);

  @override
  List<Object?> get props => [productId];
}

class SelectCustomerForInvoice extends InvoiceCreationEvent {
  final Customer customer;

  const SelectCustomerForInvoice(this.customer);

  @override
  List<Object?> get props => [customer];
}

class SetInvoiceDiscount extends InvoiceCreationEvent {
  final double discountAmount;

  const SetInvoiceDiscount(this.discountAmount);

  @override
  List<Object?> get props => [discountAmount];
}

class SetPaymentDetails extends InvoiceCreationEvent {
  final String paymentMethod;
  final double amountPaid;

  const SetPaymentDetails({
    required this.paymentMethod,
    required this.amountPaid,
  });

  @override
  List<Object?> get props => [paymentMethod, amountPaid];
}

class GenerateInvoiceRequested extends InvoiceCreationEvent {
  final User currentUser;

  const GenerateInvoiceRequested(this.currentUser);

  @override
  List<Object?> get props => [currentUser];
}

class ClearCartRequested extends InvoiceCreationEvent {}
