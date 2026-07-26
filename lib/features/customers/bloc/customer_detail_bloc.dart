import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/invoice_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import 'customer_detail_event.dart';
import 'customer_detail_state.dart';

class CustomerDetailBloc
    extends Bloc<CustomerDetailEvent, CustomerDetailState> {
  final CustomerRepository _customerRepository;
  final InvoiceRepository _invoiceRepository;
  final PaymentRepository _paymentRepository;

  CustomerDetailBloc({
    required CustomerRepository customerRepository,
    required InvoiceRepository invoiceRepository,
    required PaymentRepository paymentRepository,
  }) : _customerRepository = customerRepository,
       _invoiceRepository = invoiceRepository,
       _paymentRepository = paymentRepository,
       super(CustomerDetailInitial()) {
    on<CustomerDetailLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    CustomerDetailLoadRequested event,
    Emitter<CustomerDetailState> emit,
  ) async {
    emit(CustomerDetailLoading());
    try {
      final customer = await _customerRepository.getCustomerById(
        event.customerId,
      );
      if (customer == null) {
        emit(const CustomerDetailError('Customer not found'));
        return;
      }
      final invoices = await _invoiceRepository.getInvoices(
        customerId: event.customerId,
      );
      final payments = await _paymentRepository.getPayments(
        customerId: event.customerId,
      );

      emit(
        CustomerDetailLoaded(
          customer: customer,
          invoices: invoices,
          payments: payments,
        ),
      );
    } catch (e) {
      emit(CustomerDetailError(e.toString()));
    }
  }
}
