import 'package:equatable/equatable.dart';
import 'package:vishnu_enterprises/data/models/invoice.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final double todaySales;
  final int todayBillCount;
  final double todayProfit;
  final List<Invoice> todayInvoices;
  final List<Invoice> recentInvoices;
  final Map<String, String> customerNames;
  final Map<String, double> productCosts;

  const HomeLoaded({
    required this.todaySales,
    required this.todayBillCount,
    required this.todayProfit,
    required this.todayInvoices,
    required this.recentInvoices,
    required this.customerNames,
    required this.productCosts,
  });

  @override
  List<Object?> get props => [
    todaySales,
    todayBillCount,
    todayProfit,
    todayInvoices,
    recentInvoices,
    customerNames,
    productCosts,
  ];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
