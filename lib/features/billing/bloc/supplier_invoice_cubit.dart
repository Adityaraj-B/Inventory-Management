import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vishnu_enterprises/injection.dart';
import 'supplier_invoice_state.dart';

class SupplierInvoiceCubit extends Cubit<SupplierInvoiceState> {
  SupplierInvoiceCubit() : super(SupplierInvoiceInitial());

  Future<void> fetchInvoices(String warehouseId) async {
    emit(SupplierInvoiceLoading());
    try {
      final invoices = await getIt.supplierRepository.getSupplierInvoices(
        warehouseId,
      );
      emit(SupplierInvoiceLoaded(invoices));
    } catch (e) {
      emit(SupplierInvoiceError('Failed to fetch supplier invoices: $e'));
    }
  }
}
