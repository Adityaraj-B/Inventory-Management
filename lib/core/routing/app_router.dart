import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vishnu_enterprises/core/routing/go_router_refresh_stream.dart';
import 'package:vishnu_enterprises/core/routing/page_transitions.dart';
import 'package:vishnu_enterprises/core/routing/route_paths.dart';
import 'package:vishnu_enterprises/core/widgets/access_denied_view.dart';
import 'package:vishnu_enterprises/data/models/customer.dart';
import 'package:vishnu_enterprises/data/models/product.dart';
import 'package:vishnu_enterprises/data/models/warehouse.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_bloc.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_state.dart';
import 'package:vishnu_enterprises/features/auth/presentation/screens/login_screen.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_detail_bloc.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_detail_state.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_ledger_cubit.dart';
import 'package:vishnu_enterprises/features/customers/bloc/manage_payment_cubit.dart';
import 'package:vishnu_enterprises/features/customers/presentation/screens/admin_customer_detail_screen.dart';
import 'package:vishnu_enterprises/features/customers/presentation/screens/admin_customer_payments_screen.dart';
import 'package:vishnu_enterprises/features/customers/presentation/screens/admin_customer_ledger_screen.dart';
import 'package:vishnu_enterprises/features/customers/presentation/screens/admin_customer_transactions_screen.dart';
import 'package:vishnu_enterprises/features/customers/presentation/screens/admin_manage_payment_screen.dart';
import 'package:vishnu_enterprises/features/main_layout/presentation/screens/main_layout_screen.dart';
import 'package:vishnu_enterprises/features/stock/presentation/screens/add_edit_product_screen.dart';
import 'package:vishnu_enterprises/features/stock/presentation/screens/product_detail_screen.dart';
import 'package:vishnu_enterprises/features/stock/presentation/screens/receive_stock_scan_screen.dart';
import 'package:vishnu_enterprises/features/stock/presentation/screens/stock_history_screen.dart';
import 'package:vishnu_enterprises/features/stock/presentation/screens/stock_transfer_screen.dart';
import 'package:vishnu_enterprises/features/warehouse/presentation/screens/warehouse_detail_screen.dart';
import 'package:vishnu_enterprises/data/models/invoice.dart';
import 'package:vishnu_enterprises/features/billing/presentation/screens/invoice_generated_screen.dart';
import 'package:vishnu_enterprises/features/billing/presentation/screens/invoice_manual_select_screen.dart';
import 'package:vishnu_enterprises/features/billing/presentation/screens/invoice_review_screen.dart';
import 'package:vishnu_enterprises/features/billing/presentation/screens/invoice_scan_screen.dart';
import 'package:vishnu_enterprises/features/main_layout/presentation/screens/billing_staff_main_layout_screen.dart';
import 'package:vishnu_enterprises/features/billing/presentation/screens/supplier_invoices_screen.dart';
import 'package:vishnu_enterprises/features/billing/presentation/screens/select_supplier_screen.dart';
import 'package:vishnu_enterprises/features/billing/presentation/screens/create_supplier_invoice_screen.dart';
import 'package:vishnu_enterprises/data/models/supplier.dart';
import 'package:vishnu_enterprises/features/billing/bloc/supplier_invoice_cubit.dart';
import 'package:vishnu_enterprises/injection.dart';

class AppRouter {
  static GoRouter buildRouter(AuthBloc authBloc) {
    return GoRouter(
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      initialLocation: RoutePaths.home,
      redirect: (context, state) {
        final authState = authBloc.state;

        // If unauthenticated, redirect to login
        if (authState is AuthUnauthenticated &&
            state.matchedLocation != RoutePaths.login) {
          return RoutePaths.login;
        }

        // Role guard:
        if (authState is AuthAuthenticated) {
          final user = authState.user;
          final isBillingRoute = state.matchedLocation.startsWith(
            '/billing-staff',
          );

          if (user.isBillingStaff) {
            final isAllowedSharedRoute =
                state.matchedLocation == RoutePaths.customerDetail ||
                state.matchedLocation == RoutePaths.customerTransactions ||
                state.matchedLocation == RoutePaths.customerPayments ||
                state.matchedLocation == RoutePaths.customerLedger ||
                state.matchedLocation == RoutePaths.editStock ||
                state.matchedLocation == RoutePaths.addStock ||
                state.matchedLocation == RoutePaths.stockHistory ||
                state.matchedLocation == RoutePaths.receiveStock ||
                state.matchedLocation == RoutePaths.accessDenied;

            if (state.matchedLocation == RoutePaths.login ||
                (!isBillingRoute && !isAllowedSharedRoute)) {
              return RoutePaths.billingStaffHome;
            }
          }

          if (user.isAdmin &&
              (state.matchedLocation == RoutePaths.login ||
                  (isBillingRoute &&
                      state.matchedLocation !=
                          RoutePaths.billingStockTransfer))) {
            return RoutePaths.home;
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RoutePaths.login,
          pageBuilder: (context, state) =>
              CustomPageTransitions.buildFadeScaleSlidePage(
                key: state.pageKey,
                child: const LoginScreen(),
              ),
        ),
        GoRoute(
          path: RoutePaths.accessDenied,
          pageBuilder: (context, state) =>
              CustomPageTransitions.buildFadeScaleSlidePage(
                key: state.pageKey,
                child: AccessDeniedView(
                  onSwitchRole: () => context.go(RoutePaths.login),
                ),
              ),
        ),
        GoRoute(
          path: RoutePaths.home,
          pageBuilder: (context, state) {
            return CustomPageTransitions.buildFadeScaleSlidePage(
              key: state.pageKey,
              child: const MainLayoutScreen(),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.stock,
          pageBuilder: (context, state) {
            return CustomPageTransitions.buildFadeScaleSlidePage(
              key: state.pageKey,
              child: const MainLayoutScreen(),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.addStock,
          pageBuilder: (context, state) =>
              CustomPageTransitions.buildDrillDownPage(
                key: state.pageKey,
                child: const AddEditProductScreen(),
              ),
        ),
        GoRoute(
          path: RoutePaths.editStock,
          pageBuilder: (context, state) {
            final product = state.extra as Product?;
            return CustomPageTransitions.buildDrillDownPage(
              key: state.pageKey,
              child: AddEditProductScreen(productToEdit: product),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.productDetail,
          pageBuilder: (context, state) {
            final product = state.extra as Product;
            return CustomPageTransitions.buildFadeScaleSlidePage(
              key: state.pageKey,
              child: ProductDetailScreen(product: product),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.stockHistory,
          pageBuilder: (context, state) {
            final productId = state.extra as String?;
            return CustomPageTransitions.buildDrillDownPage(
              key: state.pageKey,
              child: StockHistoryScreen(productId: productId),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.receiveStock,
          pageBuilder: (context, state) =>
              CustomPageTransitions.buildDrillDownPage(
                key: state.pageKey,
                child: const ReceiveStockScanScreen(),
              ),
        ),
        GoRoute(
          path: RoutePaths.customers,
          pageBuilder: (context, state) {
            return CustomPageTransitions.buildFadeScaleSlidePage(
              key: state.pageKey,
              child: const MainLayoutScreen(),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.customerDetail,
          pageBuilder: (context, state) {
            final customer = state.extra as Customer;
            return CustomPageTransitions.buildDrillDownPage(
              key: state.pageKey,
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => CustomerDetailBloc(
                      customerRepository: getIt.customerRepository,
                      invoiceRepository: getIt.invoiceRepository,
                      paymentRepository: getIt.paymentRepository,
                    ),
                  ),
                  BlocProvider(create: (_) => CustomerLedgerCubit()),
                ],
                child: AdminCustomerDetailScreen(customer: customer),
              ),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.customerTransactions,
          pageBuilder: (context, state) {
            final data = state.extra as CustomerDetailLoaded;
            return CustomPageTransitions.buildDrillDownPage(
              key: state.pageKey,
              child: AdminCustomerTransactionsScreen(data: data),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.customerPayments,
          pageBuilder: (context, state) {
            final data = state.extra as CustomerDetailLoaded;
            return CustomPageTransitions.buildDrillDownPage(
              key: state.pageKey,
              child: AdminCustomerPaymentsScreen(data: data),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.customerLedger,
          pageBuilder: (context, state) {
            final data = state.extra as CustomerDetailLoaded;
            return CustomPageTransitions.buildDrillDownPage(
              key: state.pageKey,
              child: BlocProvider(
                create: (_) => CustomerLedgerCubit(),
                child: AdminCustomerLedgerScreen(data: data),
              ),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.managePayment,
          pageBuilder: (context, state) {
            final customer = state.extra as Customer;
            return CustomPageTransitions.buildDrillDownPage(
              key: state.pageKey,
              child: BlocProvider(
                create: (_) => ManagePaymentCubit(
                  paymentRepository: getIt.paymentRepository,
                  customerRepository: getIt.customerRepository,
                ),
                child: AdminManagePaymentScreen(customer: customer),
              ),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.warehouses,
          pageBuilder: (context, state) {
            return CustomPageTransitions.buildFadeScaleSlidePage(
              key: state.pageKey,
              child: const MainLayoutScreen(),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.warehouseDetail,
          pageBuilder: (context, state) {
            final warehouse = state.extra as Warehouse;
            return CustomPageTransitions.buildDrillDownPage(
              key: state.pageKey,
              child: WarehouseDetailScreen(warehouse: warehouse),
            );
          },
        ),
        // Billing Staff Routes
        GoRoute(
          path: RoutePaths.billingStaffHome,
          pageBuilder: (context, state) =>
              CustomPageTransitions.buildFadeScaleSlidePage(
                key: state.pageKey,
                child: const BillingStaffMainLayoutScreen(),
              ),
        ),
        GoRoute(
          path: RoutePaths.billingScan,
          pageBuilder: (context, state) =>
              CustomPageTransitions.buildDrillDownPage(
                key: state.pageKey,
                child: const InvoiceScanScreen(),
              ),
        ),
        GoRoute(
          path: RoutePaths.billingManualSelect,
          pageBuilder: (context, state) =>
              CustomPageTransitions.buildDrillDownPage(
                key: state.pageKey,
                child: const InvoiceManualSelectScreen(),
              ),
        ),
        GoRoute(
          path: RoutePaths.billingReview,
          pageBuilder: (context, state) =>
              CustomPageTransitions.buildDrillDownPage(
                key: state.pageKey,
                child: const InvoiceReviewScreen(),
              ),
        ),
        GoRoute(
          path: RoutePaths.billingGenerated,
          pageBuilder: (context, state) {
            final invoice = state.extra as Invoice;
            return CustomPageTransitions.buildDrillDownPage(
              key: state.pageKey,
              child: InvoiceGeneratedScreen(invoice: invoice),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.billingSupplierInvoices,
          pageBuilder: (context, state) =>
              CustomPageTransitions.buildFadeScaleSlidePage(
                key: state.pageKey,
                child: BlocProvider(
                  create: (_) => SupplierInvoiceCubit(),
                  child: const SupplierInvoicesScreen(),
                ),
              ),
        ),
        GoRoute(
          path: RoutePaths.billingStockTransfer,
          pageBuilder: (context, state) =>
              CustomPageTransitions.buildFadeScaleSlidePage(
                key: state.pageKey,
                child: const StockTransferScreen(),
              ),
        ),
        GoRoute(
          path: RoutePaths.selectSupplier,
          pageBuilder: (context, state) =>
              CustomPageTransitions.buildDrillDownPage(
                key: state.pageKey,
                child: const SelectSupplierScreen(),
              ),
        ),
        GoRoute(
          path: RoutePaths.createSupplierInvoice,
          pageBuilder: (context, state) {
            final supplier = state.extra as Supplier?;
            return CustomPageTransitions.buildDrillDownPage(
              key: state.pageKey,
              child: CreateSupplierInvoiceScreen(supplier: supplier),
            );
          },
        ),
      ],
    );
  }
}
