import 'package:equatable/equatable.dart';
import 'package:vishnu_enterprises/data/models/supplier_invoice.dart';

abstract class SupplierInvoiceState extends Equatable {
  const SupplierInvoiceState();

  @override
  List<Object?> get props => [];
}

class SupplierInvoiceInitial extends SupplierInvoiceState {}

class SupplierInvoiceLoading extends SupplierInvoiceState {}

class SupplierInvoiceLoaded extends SupplierInvoiceState {
  final List<SupplierInvoice> invoices;

  const SupplierInvoiceLoaded(this.invoices);

  @override
  List<Object?> get props => [invoices];
}

class SupplierInvoiceError extends SupplierInvoiceState {
  final String message;

  const SupplierInvoiceError(this.message);

  @override
  List<Object?> get props => [message];
}
