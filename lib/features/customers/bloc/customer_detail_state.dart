import 'package:equatable/equatable.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/invoice.dart';
import '../../../data/models/payment.dart';

abstract class CustomerDetailState extends Equatable {
  const CustomerDetailState();

  @override
  List<Object?> get props => [];
}

class CustomerDetailInitial extends CustomerDetailState {}

class CustomerDetailLoading extends CustomerDetailState {}

class CustomerDetailLoaded extends CustomerDetailState {
  final Customer customer;
  final List<Invoice> invoices;
  final List<Payment> payments;

  const CustomerDetailLoaded({
    required this.customer,
    required this.invoices,
    required this.payments,
  });

  @override
  List<Object?> get props => [customer, invoices, payments];
}

class CustomerDetailError extends CustomerDetailState {
  final String message;

  const CustomerDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
