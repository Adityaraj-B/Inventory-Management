import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vishnu_enterprises/core/routing/route_paths.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/core/widgets/empty_state.dart';
import 'package:vishnu_enterprises/core/widgets/loading_indicator.dart';
import 'package:vishnu_enterprises/data/models/customer.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_bloc.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_state.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_detail_bloc.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_detail_event.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_detail_state.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_ledger_cubit.dart';
import 'package:vishnu_enterprises/features/customers/presentation/widgets/balance_banner.dart';
import 'package:vishnu_enterprises/features/customers/presentation/widgets/ledger_entry_tile.dart';

class AdminCustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const AdminCustomerDetailScreen({super.key, required this.customer});

  @override
  State<AdminCustomerDetailScreen> createState() =>
      _AdminCustomerDetailScreenState();
}

class _AdminCustomerDetailScreenState extends State<AdminCustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerDetailBloc>().add(
      CustomerDetailLoadRequested(widget.customer.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: BlocConsumer<CustomerDetailBloc, CustomerDetailState>(
        listener: (context, state) {
          if (state is CustomerDetailLoaded) {
            context.read<CustomerLedgerCubit>().buildLedger(
              customer: state.customer,
              invoices: state.invoices,
              payments: state.payments,
            );
          }
        },
        builder: (context, state) {
          final cust = state is CustomerDetailLoaded
              ? state.customer
              : widget.customer;
          final authState = context.watch<AuthBloc>().state;
          final isAdmin =
              authState is AuthAuthenticated && authState.user.isAdmin;

          return Scaffold(
            backgroundColor: const Color(0xFFF4F6F8),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF4F6F8),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      CupertinoIcons.chevron_left,
                      size: 18,
                      color: Colors.black87,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              title: Text(
                cust.name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      CupertinoIcons.printer_fill,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () =>
                        context.read<CustomerLedgerCubit>().exportLedgerPdf(),
                    tooltip: 'Export PDF Ledger Statement',
                  ),
                ),
              ],
            ),
            body: state is CustomerDetailLoading
                ? const Center(
                    child: LoadingIndicator(
                      message: 'Loading customer statement...',
                    ),
                  )
                : RefreshIndicator(
                    color: theme.colorScheme.primary,
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      context.read<CustomerDetailBloc>().add(
                        CustomerDetailLoadRequested(cust.id),
                      );
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer info card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade100,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            theme.colorScheme.primary
                                                .withOpacity(0.8),
                                            theme.colorScheme.primary,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          cust.name.isNotEmpty
                                              ? cust.name[0].toUpperCase()
                                              : 'C',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cust.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black87,
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.phone_fill,
                                                size: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                cust.phone,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.mail_solid,
                                                size: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  cust.email,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1.2,
                                    color: Color(0xFFF0F0F0),
                                  ),
                                ),
                                _InfoRow(
                                  icon: CupertinoIcons.location_solid,
                                  label: 'Address',
                                  value: '${cust.address}, ${cust.city}',
                                ),
                                if (cust.gstin != null &&
                                    cust.gstin!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _InfoRow(
                                    icon: CupertinoIcons.doc_text_fill,
                                    label: 'GSTIN',
                                    value: cust.gstin!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Balance Banner
                          BlocBuilder<CustomerLedgerCubit, CustomerLedgerState>(
                            builder: (context, ledgerState) {
                              return BalanceBanner(
                                balance: ledgerState.currentBalance,
                              );
                            },
                          ),
                          const SizedBox(height: 20),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  icon: CupertinoIcons.doc_plaintext,
                                  label: 'Invoices',
                                  color: theme.colorScheme.primary,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    if (state is CustomerDetailLoaded) {
                                      context.push(
                                        RoutePaths.customerTransactions,
                                        extra: state,
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionButton(
                                  icon: CupertinoIcons.doc_text_fill,
                                  label: 'Ledger',
                                  color: const Color(0xFF107C41),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    if (state is CustomerDetailLoaded) {
                                      context.push(
                                        RoutePaths.customerLedger,
                                        extra: state,
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ActionButton(
                                  icon: CupertinoIcons.arrow_right_arrow_left,
                                  label: 'Transactions',
                                  color: const Color(0xFF2B579A),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    if (state is CustomerDetailLoaded) {
                                      context.push(
                                        RoutePaths.customerPayments,
                                        extra: state,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (isAdmin) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionButton(
                                    icon: CupertinoIcons.add,
                                    label: 'Record Pay',
                                    color: AppColors.accent,
                                    isPrimary: true,
                                    onTap: () async {
                                      HapticFeedback.lightImpact();
                                      final detailBloc = context
                                          .read<CustomerDetailBloc>();
                                      final result = await context.push(
                                        RoutePaths.managePayment,
                                        extra: cust,
                                      );
                                      if (result == true) {
                                        detailBloc.add(
                                          CustomerDetailLoadRequested(cust.id),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 32),

                          // Ledger Entries Preview
                          Text(
                            'ACCOUNT LEDGER STATEMENT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade500,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),

                          BlocBuilder<CustomerLedgerCubit, CustomerLedgerState>(
                            builder: (context, ledgerState) {
                              if (ledgerState.isLoading) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 32),
                                  child: Center(
                                    child: LoadingIndicator(
                                      message: 'Calculating ledger entries...',
                                    ),
                                  ),
                                );
                              }

                              if (ledgerState.entries.isEmpty) {
                                return const EmptyState(
                                  title: 'No ledger history',
                                  message:
                                      'Transactions and payments will record here.',
                                  icon: CupertinoIcons.doc_text_search,
                                );
                              }

                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: ledgerState.entries.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  return LedgerEntryTile(
                                    entry: ledgerState.entries[index],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade100, width: 1.2),
          ),
          child: Icon(icon, size: 16, color: Colors.grey.shade500),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? null : Colors.white,
        gradient: isPrimary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.85),
                  theme.colorScheme.primary,
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(20),
        border: isPrimary
            ? null
            : Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          isPrimary
              ? BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              : BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: isPrimary ? Colors.white : color),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isPrimary ? Colors.white : Colors.black87,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
