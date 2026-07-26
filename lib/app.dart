import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/billing/bloc/invoice_creation_bloc.dart';
import 'features/customers/bloc/customer_list_bloc.dart';
import 'features/home/bloc/home_bloc.dart';
import 'features/main_layout/bloc/nav_cubit.dart';
import 'features/stock/bloc/stock_bloc.dart';
import 'features/stock/bloc/receive_stock_cubit.dart';
import 'features/warehouse/bloc/warehouse_bloc.dart';
import 'injection.dart';

class EnterpriseApp extends StatelessWidget {
  const EnterpriseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              AuthBloc(authRepository: getIt.authRepository)
                ..add(AuthCheckRequested()),
        ),
        BlocProvider(create: (_) => NavCubit()),
        BlocProvider(
          create: (_) => HomeBloc(
            invoiceRepository: getIt.invoiceRepository,
            productRepository: getIt.productRepository,
            customerRepository: getIt.customerRepository,
          ),
        ),
        BlocProvider(
          create: (_) => StockBloc(
            productRepository: getIt.productRepository,
            shipmentRepository: getIt.shipmentRepository,
          ),
        ),
        BlocProvider(
          create: (_) =>
              CustomerListBloc(customerRepository: getIt.customerRepository),
        ),
        BlocProvider(
          create: (_) =>
              WarehouseBloc(warehouseRepository: getIt.warehouseRepository),
        ),
        BlocProvider(
          create: (_) => ReceiveStockCubit(
            shipmentRepository: getIt.shipmentRepository,
            productRepository: getIt.productRepository,
          ),
        ),
        BlocProvider(
          create: (_) => InvoiceCreationBloc(
            invoiceRepository: getIt.invoiceRepository,
            paymentRepository: getIt.paymentRepository,
            customerRepository: getIt.customerRepository,
            productRepository: getIt.productRepository,
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final authBloc = context.read<AuthBloc>();
          final router = AppRouter.buildRouter(authBloc);

          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
