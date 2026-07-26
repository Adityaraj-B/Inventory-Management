import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/customer_repository.dart';
import 'customer_list_event.dart';
import 'customer_list_state.dart';

class CustomerListBloc extends Bloc<CustomerListEvent, CustomerListState> {
  final CustomerRepository _customerRepository;
  String? _currentSearchQuery;
  String? _currentWarehouseId;

  CustomerListBloc({required CustomerRepository customerRepository})
    : _customerRepository = customerRepository,
      super(CustomerListInitial()) {
    on<CustomerListLoadRequested>(_onLoad);
    on<CustomerSearchChanged>(_onSearchChanged);
    on<AddCustomerRequested>(_onAddCustomer);
  }

  Future<void> _onLoad(
    CustomerListLoadRequested event,
    Emitter<CustomerListState> emit,
  ) async {
    _currentSearchQuery = event.searchQuery;
    _currentWarehouseId = event.warehouseId;
    emit(CustomerListLoading());
    try {
      final customers = await _customerRepository.getCustomers(
        searchQuery: event.searchQuery,
        warehouseId: event.warehouseId,
      );
      emit(
        CustomerListLoaded(
          customers: customers,
          searchQuery: event.searchQuery ?? '',
        ),
      );
    } catch (e) {
      emit(CustomerListError(e.toString()));
    }
  }

  Future<void> _onSearchChanged(
    CustomerSearchChanged event,
    Emitter<CustomerListState> emit,
  ) async {
    _currentSearchQuery = event.query;
    _currentWarehouseId = event.warehouseId;
    try {
      final customers = await _customerRepository.getCustomers(
        searchQuery: event.query,
        warehouseId: event.warehouseId,
      );
      emit(CustomerListLoaded(customers: customers, searchQuery: event.query));
    } catch (e) {
      emit(CustomerListError(e.toString()));
    }
  }

  Future<void> _onAddCustomer(
    AddCustomerRequested event,
    Emitter<CustomerListState> emit,
  ) async {
    emit(CustomerListLoading());
    try {
      await _customerRepository.addCustomer(event.customer);
      final customers = await _customerRepository.getCustomers(
        searchQuery: _currentSearchQuery,
        warehouseId: _currentWarehouseId,
      );
      emit(const CustomerOperationSuccess('Customer added successfully'));
      emit(
        CustomerListLoaded(
          customers: customers,
          searchQuery: _currentSearchQuery ?? '',
        ),
      );
    } catch (e) {
      emit(CustomerListError(e.toString()));
    }
  }
}
