import 'package:flutter_test/flutter_test.dart';
import 'package:vishnu_enterprises/core/constants.dart';
import 'package:vishnu_enterprises/data/datasources/mock/mock_customer_repository.dart';
import 'package:vishnu_enterprises/data/datasources/mock/mock_invoice_repository.dart';
import 'package:vishnu_enterprises/data/datasources/mock/mock_payment_repository.dart';
import 'package:vishnu_enterprises/data/datasources/mock/mock_product_repository.dart';
import 'package:vishnu_enterprises/data/models/product.dart';
import 'package:vishnu_enterprises/data/models/user.dart';
import 'package:vishnu_enterprises/features/billing/bloc/cart_item.dart';
import 'package:vishnu_enterprises/features/billing/bloc/invoice_creation_bloc.dart';
import 'package:vishnu_enterprises/features/billing/bloc/invoice_creation_event.dart';
import 'package:vishnu_enterprises/features/billing/bloc/invoice_creation_state.dart';

void main() {
  late InvoiceCreationBloc bloc;
  late MockInvoiceRepository mockInvoiceRepository;
  late MockPaymentRepository mockPaymentRepository;
  late MockCustomerRepository mockCustomerRepository;
  late MockProductRepository mockProductRepository;

  final adminUser = const User(
    id: 'u-1',
    name: 'Admin User',
    email: 'admin@vishnu.com',
    role: AppConstants.roleAdmin,
  );

  final billingStaffUser = const User(
    id: 'u-2',
    name: 'Staff User',
    email: 'staff@vishnu.com',
    role: AppConstants.roleBillingStaff,
    linkedWarehouseId: 'wh-1',
  );

  final sampleProduct = Product(
    id: 'prod-test',
    name: 'Test Cement Bag',
    sku: 'TST-101',
    category: 'Construction',
    unitPrice: 400.0,
    mrp: 400.0,
    costPrice: 300.0,
    quantityInStock: 20,
    warehouseId: 'wh-1',
    lowStockThreshold: 5,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    mockInvoiceRepository = MockInvoiceRepository();
    mockPaymentRepository = MockPaymentRepository();
    mockCustomerRepository = MockCustomerRepository();
    mockProductRepository = MockProductRepository();

    bloc = InvoiceCreationBloc(
      invoiceRepository: mockInvoiceRepository,
      paymentRepository: mockPaymentRepository,
      customerRepository: mockCustomerRepository,
      productRepository: mockProductRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('Rule 1: Admin user IS allowed to underprice below MRP', () {
    bloc.add(AddProductToCart(
      product: sampleProduct,
      quantity: 2,
      unitPrice: 350.0, // Below MRP 400.0
      currentUser: adminUser,
    ));

    expectLater(
      bloc.stream,
      emits(
        predicate<InvoiceCreationState>((state) {
          if (state is InvoiceCartState) {
            return state.errorMessage == null &&
                state.cartItems.length == 1 &&
                state.cartItems.first.customUnitPrice == 350.0;
          }
          return false;
        }),
      ),
    );
  });

  test('Rule 2: Billing Staff user is BLOCKED from underpricing below MRP', () {
    bloc.add(AddProductToCart(
      product: sampleProduct,
      quantity: 1,
      unitPrice: 350.0, // Below MRP 400.0
      currentUser: billingStaffUser,
    ));

    expectLater(
      bloc.stream,
      emits(
        predicate<InvoiceCreationState>((state) {
          if (state is InvoiceCartState) {
            return state.errorMessage != null &&
                state.errorMessage!.contains('Cannot set unit price below MRP') &&
                state.cartItems.isEmpty;
          }
          return false;
        }),
      ),
    );
  });

  test('Rule 3: Overselling stock is BLOCKED with exact available stock count in error message', () {
    bloc.add(AddProductToCart(
      product: sampleProduct, // quantityInStock is 20
      quantity: 25, // Requesting 25 > 20
      currentUser: billingStaffUser,
    ));

    expectLater(
      bloc.stream,
      emits(
        predicate<InvoiceCreationState>((state) {
          if (state is InvoiceCartState) {
            return state.errorMessage != null &&
                state.errorMessage!.contains('Cannot add 25 units. Only 20 units available in stock.') &&
                state.cartItems.isEmpty;
          }
          return false;
        }),
      ),
    );
  });
}
