import 'package:equatable/equatable.dart';
import '../../../data/models/customer.dart';

abstract class CustomerListState extends Equatable {
  const CustomerListState();

  @override
  List<Object?> get props => [];
}

class CustomerListInitial extends CustomerListState {}

class CustomerListLoading extends CustomerListState {}

class CustomerListLoaded extends CustomerListState {
  final List<Customer> customers;
  final String searchQuery;

  const CustomerListLoaded({required this.customers, this.searchQuery = ''});

  @override
  List<Object?> get props => [customers, searchQuery];
}

class CustomerOperationSuccess extends CustomerListState {
  final String message;

  const CustomerOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CustomerListError extends CustomerListState {
  final String message;

  const CustomerListError(this.message);

  @override
  List<Object?> get props => [message];
}
