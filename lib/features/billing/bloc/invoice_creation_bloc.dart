import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/invoice.dart';
import '../../../data/models/invoice_line_item.dart';
import '../../../data/models/payment.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/product_repository.dart';
import 'cart_item.dart';
import 'invoice_creation_event.dart';
import 'invoice_creation_state.dart';

class InvoiceCreationBloc
    extends Bloc<InvoiceCreationEvent, InvoiceCreationState> {
  final InvoiceRepository _invoiceRepository;
  final PaymentRepository _paymentRepository;
  final CustomerRepository _customerRepository;
  final ProductRepository _productRepository;

  InvoiceCreationBloc({
    required InvoiceRepository invoiceRepository,
    required PaymentRepository paymentRepository,
    required CustomerRepository customerRepository,
    required ProductRepository productRepository,
  }) : _invoiceRepository = invoiceRepository,
       _paymentRepository = paymentRepository,
       _customerRepository = customerRepository,
       _productRepository = productRepository,
       super(const InvoiceCreationInitial()) {
    on<AddProductToCart>(_onAddProduct);
    on<UpdateCartItem>(_onUpdateCartItem);
    on<RemoveCartItem>(_onRemoveCartItem);
    on<SelectCustomerForInvoice>(_onSelectCustomer);
    on<SetInvoiceDiscount>(_onSetDiscount);
    on<SetPaymentDetails>(_onSetPaymentDetails);
    on<GenerateInvoiceRequested>(_onGenerateInvoice);
    on<ClearCartRequested>(_onClearCart);
  }

  void _onAddProduct(
    AddProductToCart event,
    Emitter<InvoiceCreationState> emit,
  ) {
    final product = event.product;
    final price = event.unitPrice ?? product.unitPrice;

    // 1. MRP Validation rule: non-admin underpricing check
    if (price < product.mrp && !event.currentUser.isAdmin) {
      emit(
        InvoiceCartState(
          cartItems: state.cartItems,
          selectedCustomer: state.selectedCustomer,
          discountAmount: state.discountAmount,
          paymentMethod: state.paymentMethod,
          amountPaid: state.amountPaid,
          errorMessage:
              'Cannot set unit price below MRP (₹${product.mrp}) for non-admin users',
        ),
      );
      return;
    }

    final totalUnits = event.sellMode == SellMode.innerBox
        ? event.quantity * product.unitsPerBarcode
        : event.quantity;

    // 2. Stock Validation rule: oversell check
    if (totalUnits > product.quantityInStock) {
      emit(
        InvoiceCartState(
          cartItems: state.cartItems,
          selectedCustomer: state.selectedCustomer,
          discountAmount: state.discountAmount,
          paymentMethod: state.paymentMethod,
          amountPaid: state.amountPaid,
          errorMessage:
              'Cannot add $totalUnits units. Only ${product.quantityInStock} units available in stock.',
        ),
      );
      return;
    }

    final existingIndex = state.cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );
    final updatedList = List<CartItem>.from(state.cartItems);

    if (existingIndex != -1) {
      final existingItem = updatedList[existingIndex];
      final newRawQty = existingItem.rawQuantity + event.quantity;
      final newTotalUnits = existingItem.sellMode == SellMode.innerBox
          ? newRawQty * product.unitsPerBarcode
          : newRawQty;

      if (newTotalUnits > product.quantityInStock) {
        emit(
          InvoiceCartState(
            cartItems: state.cartItems,
            selectedCustomer: state.selectedCustomer,
            discountAmount: state.discountAmount,
            paymentMethod: state.paymentMethod,
            amountPaid: state.amountPaid,
            errorMessage:
                'Cannot add $newTotalUnits units. Only ${product.quantityInStock} units available in stock.',
          ),
        );
        return;
      }

      updatedList[existingIndex] = existingItem.copyWith(
        rawQuantity: newRawQty,
        customUnitPrice: price,
      );
    } else {
      updatedList.add(
        CartItem(
          product: product,
          rawQuantity: event.quantity,
          sellMode: event.sellMode,
          customUnitPrice: price,
        ),
      );
    }

    emit(
      InvoiceCartState(
        cartItems: updatedList,
        selectedCustomer: state.selectedCustomer,
        discountAmount: state.discountAmount,
        paymentMethod: state.paymentMethod,
        amountPaid: state.amountPaid,
        errorMessage: null,
      ),
    );
  }

  void _onUpdateCartItem(
    UpdateCartItem event,
    Emitter<InvoiceCreationState> emit,
  ) {
    final index = state.cartItems.indexWhere(
      (item) => item.product.id == event.productId,
    );
    if (index == -1) return;

    final existing = state.cartItems[index];
    final sellMode = event.sellMode ?? existing.sellMode;
    final price = event.unitPrice ?? existing.customUnitPrice;

    // MRP validation
    if (price < existing.product.mrp && !event.currentUser.isAdmin) {
      emit(
        InvoiceCartState(
          cartItems: state.cartItems,
          selectedCustomer: state.selectedCustomer,
          discountAmount: state.discountAmount,
          paymentMethod: state.paymentMethod,
          amountPaid: state.amountPaid,
          errorMessage:
              'Cannot set unit price below MRP (₹${existing.product.mrp}) for non-admin users',
        ),
      );
      return;
    }

    final totalUnits = sellMode == SellMode.innerBox
        ? event.quantity * existing.product.unitsPerBarcode
        : event.quantity;

    // Stock validation
    if (totalUnits > existing.product.quantityInStock) {
      emit(
        InvoiceCartState(
          cartItems: state.cartItems,
          selectedCustomer: state.selectedCustomer,
          discountAmount: state.discountAmount,
          paymentMethod: state.paymentMethod,
          amountPaid: state.amountPaid,
          errorMessage:
              'Cannot add $totalUnits units. Only ${existing.product.quantityInStock} units available in stock.',
        ),
      );
      return;
    }

    final updatedList = List<CartItem>.from(state.cartItems);
    if (event.quantity <= 0) {
      updatedList.removeAt(index);
    } else {
      updatedList[index] = existing.copyWith(
        rawQuantity: event.quantity,
        sellMode: sellMode,
        customUnitPrice: price,
      );
    }

    emit(
      InvoiceCartState(
        cartItems: updatedList,
        selectedCustomer: state.selectedCustomer,
        discountAmount: state.discountAmount,
        paymentMethod: state.paymentMethod,
        amountPaid: state.amountPaid,
        errorMessage: null,
      ),
    );
  }

  void _onRemoveCartItem(
    RemoveCartItem event,
    Emitter<InvoiceCreationState> emit,
  ) {
    final updatedList = state.cartItems
        .where((item) => item.product.id != event.productId)
        .toList();
    emit(
      InvoiceCartState(
        cartItems: updatedList,
        selectedCustomer: state.selectedCustomer,
        discountAmount: state.discountAmount,
        paymentMethod: state.paymentMethod,
        amountPaid: state.amountPaid,
        errorMessage: null,
      ),
    );
  }

  void _onSelectCustomer(
    SelectCustomerForInvoice event,
    Emitter<InvoiceCreationState> emit,
  ) {
    emit(
      InvoiceCartState(
        cartItems: state.cartItems,
        selectedCustomer: event.customer,
        discountAmount: state.discountAmount,
        paymentMethod: state.paymentMethod,
        amountPaid: state.amountPaid,
        errorMessage: null,
      ),
    );
  }

  void _onSetDiscount(
    SetInvoiceDiscount event,
    Emitter<InvoiceCreationState> emit,
  ) {
    emit(
      InvoiceCartState(
        cartItems: state.cartItems,
        selectedCustomer: state.selectedCustomer,
        discountAmount: event.discountAmount,
        paymentMethod: state.paymentMethod,
        amountPaid: state.amountPaid,
        errorMessage: null,
      ),
    );
  }

  void _onSetPaymentDetails(
    SetPaymentDetails event,
    Emitter<InvoiceCreationState> emit,
  ) {
    emit(
      InvoiceCartState(
        cartItems: state.cartItems,
        selectedCustomer: state.selectedCustomer,
        discountAmount: state.discountAmount,
        paymentMethod: event.paymentMethod,
        amountPaid: event.amountPaid,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onGenerateInvoice(
    GenerateInvoiceRequested event,
    Emitter<InvoiceCreationState> emit,
  ) async {
    if (state.cartItems.isEmpty) {
      emit(
        InvoiceCreationError(
          message: 'Cart is empty. Add products before generating an invoice.',
          cartItems: state.cartItems,
          selectedCustomer: state.selectedCustomer,
          discountAmount: state.discountAmount,
          paymentMethod: state.paymentMethod,
          amountPaid: state.amountPaid,
        ),
      );
      return;
    }

    if (state.selectedCustomer == null) {
      emit(
        InvoiceCreationError(
          message: 'Please select a customer before generating invoice.',
          cartItems: state.cartItems,
          selectedCustomer: state.selectedCustomer,
          discountAmount: state.discountAmount,
          paymentMethod: state.paymentMethod,
          amountPaid: state.amountPaid,
        ),
      );
      return;
    }

    emit(
      InvoiceCreationSubmitting(
        cartItems: state.cartItems,
        selectedCustomer: state.selectedCustomer,
        discountAmount: state.discountAmount,
        paymentMethod: state.paymentMethod,
        amountPaid: state.amountPaid,
      ),
    );

    try {
      final lineItems = state.cartItems.map((item) {
        return InvoiceLineItem(
          productId: item.product.id,
          productName: item.product.name,
          quantity: item.totalUnits,
          rate: item.rate,
          lineTotal: item.subtotal,
        );
      }).toList();

      final invoiceId = 'inv-${const Uuid().v4().substring(0, 8)}';
      final invoiceNum =
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final invoice = Invoice(
        id: invoiceId,
        invoiceNumber: invoiceNum,
        customerId: state.selectedCustomer!.id,
        date: DateTime.now(),
        lineItems: lineItems,
        grandTotal: state.grandTotal,
        amountPaid: state.amountPaid,
        outstandingAmount: state.outstandingAmount,
        paymentMethod: state.paymentMethod,
      );

      final createdInvoice = await _invoiceRepository.createInvoice(invoice);

      // Record payment if any
      if (state.amountPaid > 0) {
        final payment = Payment(
          id: 'pay-${const Uuid().v4().substring(0, 8)}',
          customerId: state.selectedCustomer!.id,
          invoiceId: createdInvoice.id,
          amount: state.amountPaid,
          paymentMethod: state.paymentMethod,
          date: DateTime.now(),
          balanceBefore: state.selectedCustomer!.previousBalance,
          balanceAfter:
              state.selectedCustomer!.previousBalance + state.outstandingAmount,
          notes: 'Invoice $invoiceNum Payment',
        );
        await _paymentRepository.recordPayment(payment);
      }

      // Deduct stock from products
      for (final item in state.cartItems) {
        final updatedQty = item.product.quantityInStock - item.totalUnits;
        await _productRepository.updateProduct(
          item.product.copyWith(
            quantityInStock: updatedQty < 0 ? 0 : updatedQty,
          ),
        );
      }

      emit(
        InvoiceCreationSuccess(
          generatedInvoice: createdInvoice,
          cartItems: state.cartItems,
          selectedCustomer: state.selectedCustomer,
          discountAmount: state.discountAmount,
          paymentMethod: state.paymentMethod,
          amountPaid: state.amountPaid,
        ),
      );
    } catch (e) {
      emit(
        InvoiceCreationError(
          message: 'Failed to generate invoice: ${e.toString()}',
          cartItems: state.cartItems,
          selectedCustomer: state.selectedCustomer,
          discountAmount: state.discountAmount,
          paymentMethod: state.paymentMethod,
          amountPaid: state.amountPaid,
        ),
      );
    }
  }

  void _onClearCart(
    ClearCartRequested event,
    Emitter<InvoiceCreationState> emit,
  ) {
    emit(const InvoiceCreationInitial());
  }
}
