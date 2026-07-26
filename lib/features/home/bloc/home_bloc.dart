import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vishnu_enterprises/data/repositories/customer_repository.dart';
import 'package:vishnu_enterprises/data/repositories/invoice_repository.dart';
import 'package:vishnu_enterprises/data/repositories/product_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final InvoiceRepository _invoiceRepository;
  final ProductRepository _productRepository;
  final CustomerRepository _customerRepository;

  HomeBloc({
    required InvoiceRepository invoiceRepository,
    required ProductRepository productRepository,
    required CustomerRepository customerRepository,
  }) : _invoiceRepository = invoiceRepository,
       _productRepository = productRepository,
       _customerRepository = customerRepository,
       super(HomeInitial()) {
    on<HomeLoadRequested>(_onLoad);
    on<HomeRefreshRequested>(_onRefresh);
  }

  Future<void> _onLoad(HomeLoadRequested event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    await _fetchData(emit);
  }

  Future<void> _onRefresh(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    await _fetchData(emit);
  }

  Future<void> _fetchData(Emitter<HomeState> emit) async {
    try {
      final invoices = await _invoiceRepository.getInvoices();
      final todayInvoices = await _invoiceRepository.getTodayInvoices();
      final products = await _productRepository.getProducts();
      final customers = await _customerRepository.getCustomers();

      final productCostMap = {for (var p in products) p.id: p.costPrice};
      final customerNameMap = {for (var c in customers) c.id: c.name};

      double sales = 0.0;
      double profit = 0.0;

      for (var inv in todayInvoices) {
        sales += inv.grandTotal;
        for (var item in inv.lineItems) {
          final cost = productCostMap[item.productId] ?? (item.rate * 0.75);
          profit += (item.lineTotal - (cost * item.quantity));
        }
      }

      emit(
        HomeLoaded(
          todaySales: sales,
          todayBillCount: todayInvoices.length,
          todayProfit: profit,
          todayInvoices: todayInvoices,
          recentInvoices: invoices,
          customerNames: customerNameMap,
          productCosts: productCostMap,
        ),
      );
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
