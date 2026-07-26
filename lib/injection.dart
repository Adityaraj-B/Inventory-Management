import 'data/repositories/supabase/supabase_auth_repository.dart';
import 'data/repositories/supabase/supabase_customer_repository.dart';
import 'data/repositories/supabase/supabase_invoice_repository.dart';
import 'data/repositories/supabase/supabase_payment_repository.dart';
import 'data/repositories/supabase/supabase_product_repository.dart';
import 'data/repositories/supabase/supabase_supplier_repository.dart';
import 'data/repositories/supabase/supabase_warehouse_repository.dart';
import 'data/repositories/supabase/supabase_shipment_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/customer_repository.dart';
import 'data/repositories/invoice_repository.dart';
import 'data/repositories/payment_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/supplier_repository.dart';
import 'data/repositories/warehouse_repository.dart';
import 'data/repositories/shipment_repository.dart';

class Injection {
  static final Injection _instance = Injection._internal();
  factory Injection() => _instance;
  Injection._internal();

  late final AuthRepository authRepository;
  late final ProductRepository productRepository;
  late final CustomerRepository customerRepository;
  late final InvoiceRepository invoiceRepository;
  late final PaymentRepository paymentRepository;
  late final WarehouseRepository warehouseRepository;
  late final SupplierRepository supplierRepository;
  late final ShipmentRepository shipmentRepository;

  void init() {
    authRepository = SupabaseAuthRepository();
    productRepository = SupabaseProductRepository();
    customerRepository = SupabaseCustomerRepository();
    invoiceRepository = SupabaseInvoiceRepository();
    paymentRepository = SupabasePaymentRepository();
    warehouseRepository = SupabaseWarehouseRepository();
    supplierRepository = SupabaseSupplierRepository();
    shipmentRepository = SupabaseShipmentRepository();
  }
}

final getIt = Injection();
