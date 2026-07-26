import 'package:equatable/equatable.dart';

abstract class CustomerDetailEvent extends Equatable {
  const CustomerDetailEvent();

  @override
  List<Object?> get props => [];
}

class CustomerDetailLoadRequested extends CustomerDetailEvent {
  final String customerId;

  const CustomerDetailLoadRequested(this.customerId);

  @override
  List<Object?> get props => [customerId];
}
