import 'package:equatable/equatable.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/invoice.dart';
import 'cart_item.dart';

abstract class InvoiceCreationState extends Equatable {
  final List<CartItem> cartItems;
  final Customer? selectedCustomer;
  final double discountAmount;
  final String paymentMethod;
  final double amountPaid;

  const InvoiceCreationState({
    this.cartItems = const [],
    this.selectedCustomer,
    this.discountAmount = 0.0,
    this.paymentMethod = 'Cash',
    this.amountPaid = 0.0,
  });

  double get subtotal =>
      cartItems.fold(0.0, (sum, item) => sum + item.subtotal);
  double get grandTotal =>
      (subtotal - discountAmount) < 0 ? 0.0 : (subtotal - discountAmount);
  double get outstandingAmount =>
      (grandTotal - amountPaid) < 0 ? 0.0 : (grandTotal - amountPaid);

  @override
  List<Object?> get props => [
    cartItems,
    selectedCustomer,
    discountAmount,
    paymentMethod,
    amountPaid,
  ];
}

class InvoiceCreationInitial extends InvoiceCreationState {
  const InvoiceCreationInitial() : super();
}

class InvoiceCartState extends InvoiceCreationState {
  final String? errorMessage;

  const InvoiceCartState({
    super.cartItems,
    super.selectedCustomer,
    super.discountAmount,
    super.paymentMethod,
    super.amountPaid,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [...super.props, errorMessage];
}

class InvoiceCreationSubmitting extends InvoiceCreationState {
  const InvoiceCreationSubmitting({
    required super.cartItems,
    super.selectedCustomer,
    super.discountAmount,
    super.paymentMethod,
    super.amountPaid,
  });
}

class InvoiceCreationSuccess extends InvoiceCreationState {
  final Invoice generatedInvoice;

  const InvoiceCreationSuccess({
    required this.generatedInvoice,
    required super.cartItems,
    super.selectedCustomer,
    super.discountAmount,
    super.paymentMethod,
    super.amountPaid,
  });

  @override
  List<Object?> get props => [...super.props, generatedInvoice];
}

class InvoiceCreationError extends InvoiceCreationState {
  final String message;

  const InvoiceCreationError({
    required this.message,
    required super.cartItems,
    super.selectedCustomer,
    super.discountAmount,
    super.paymentMethod,
    super.amountPaid,
  });

  @override
  List<Object?> get props => [...super.props, message];
}
