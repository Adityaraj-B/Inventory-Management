import 'package:equatable/equatable.dart';
import '../../../data/models/customer.dart';

abstract class CustomerListEvent extends Equatable {
  const CustomerListEvent();

  @override
  List<Object?> get props => [];
}

class CustomerListLoadRequested extends CustomerListEvent {
  final String? searchQuery;
  final String? warehouseId;

  const CustomerListLoadRequested({this.searchQuery, this.warehouseId});

  @override
  List<Object?> get props => [searchQuery, warehouseId];
}

class CustomerSearchChanged extends CustomerListEvent {
  final String query;
  final String? warehouseId;

  const CustomerSearchChanged(this.query, {this.warehouseId});

  @override
  List<Object?> get props => [query, warehouseId];
}

class AddCustomerRequested extends CustomerListEvent {
  final Customer customer;

  const AddCustomerRequested(this.customer);

  @override
  List<Object?> get props => [customer];
}
