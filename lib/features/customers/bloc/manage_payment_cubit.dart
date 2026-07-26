import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/payment.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/payment_repository.dart';

class ManagePaymentState extends Equatable {
  final double inputAmount;
  final String paymentMethod;
  final String notes;
  final bool isOverpaying;
  final double excessAmount;
  final bool isSubmitting;
  final String? successMessage;
  final String? error;

  const ManagePaymentState({
    this.inputAmount = 0.0,
    this.paymentMethod = 'UPI / Bank Transfer',
    this.notes = '',
    this.isOverpaying = false,
    this.excessAmount = 0.0,
    this.isSubmitting = false,
    this.successMessage,
    this.error,
  });

  ManagePaymentState copyWith({
    double? inputAmount,
    String? paymentMethod,
    String? notes,
    bool? isOverpaying,
    double? excessAmount,
    bool? isSubmitting,
    String? successMessage,
    String? error,
  }) {
    return ManagePaymentState(
      inputAmount: inputAmount ?? this.inputAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      isOverpaying: isOverpaying ?? this.isOverpaying,
      excessAmount: excessAmount ?? this.excessAmount,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: successMessage,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    inputAmount,
    paymentMethod,
    notes,
    isOverpaying,
    excessAmount,
    isSubmitting,
    successMessage,
    error,
  ];
}

class ManagePaymentCubit extends Cubit<ManagePaymentState> {
  final PaymentRepository _paymentRepository;
  final CustomerRepository _customerRepository;

  ManagePaymentCubit({
    required PaymentRepository paymentRepository,
    required CustomerRepository customerRepository,
  }) : _paymentRepository = paymentRepository,
       _customerRepository = customerRepository,
       super(const ManagePaymentState());

  void onAmountChanged(String val, double currentOutstanding) {
    final amount = double.tryParse(val) ?? 0.0;
    final isOver = amount > currentOutstanding && currentOutstanding > 0;
    final excess = isOver ? amount - currentOutstanding : 0.0;

    emit(
      state.copyWith(
        inputAmount: amount,
        isOverpaying: isOver,
        excessAmount: excess,
      ),
    );
  }

  void onMethodChanged(String method) {
    emit(state.copyWith(paymentMethod: method));
  }

  void onNotesChanged(String notes) {
    emit(state.copyWith(notes: notes));
  }

  Future<void> submitPayment(Customer customer) async {
    if (state.inputAmount <= 0) {
      emit(
        state.copyWith(
          error: 'Please enter a valid payment amount greater than zero',
        ),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true));
    try {
      final before = customer.previousBalance;
      // Cap balance at 0 on confirm
      final after = (before - state.inputAmount).clamp(0.0, double.infinity);

      final payment = Payment(
        id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
        customerId: customer.id,
        amount: state.inputAmount,
        paymentMethod: state.paymentMethod,
        date: DateTime.now(),
        balanceBefore: before,
        balanceAfter: after,
        notes: state.notes.isEmpty ? null : state.notes,
      );

      await _paymentRepository.recordPayment(payment);
      await _customerRepository.updateCustomerBalance(customer.id, after);

      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage:
              'Payment of ₹${state.inputAmount.toStringAsFixed(2)} recorded successfully',
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.toString()));
    }
  }
}
