import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:vishnu_enterprises/core/routing/route_paths.dart';
import 'package:vishnu_enterprises/data/models/supplier_invoice.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_bloc.dart';
import 'package:vishnu_enterprises/features/auth/bloc/auth_state.dart';
import 'package:vishnu_enterprises/features/billing/bloc/supplier_invoice_cubit.dart';
import 'package:vishnu_enterprises/features/billing/bloc/supplier_invoice_state.dart';

class SupplierInvoicesScreen extends StatefulWidget {
  const SupplierInvoicesScreen({super.key});

  @override
  State<SupplierInvoicesScreen> createState() => _SupplierInvoicesScreenState();
}

class _SupplierInvoicesScreenState extends State<SupplierInvoicesScreen> {
  bool _initialLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoaded) {
      _initialLoaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    }
  }

  Future<void> _loadData() async {
    final authState = context.read<AuthBloc>().state;
    final warehouseId = authState is AuthAuthenticated
        ? authState.user.warehouseId
        : null;

    if (warehouseId != null) {
      context.read<SupplierInvoiceCubit>().fetchInvoices(warehouseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(RoutePaths.billingStaffHome);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Supplier Invoices'),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(RoutePaths.billingStaffHome),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilledButton.icon(
                onPressed: () => context.push(RoutePaths.selectSupplier),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: BlocBuilder<SupplierInvoiceCubit, SupplierInvoiceState>(
          builder: (context, state) {
            if (state is SupplierInvoiceLoading ||
                state is SupplierInvoiceInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SupplierInvoiceError) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              );
            } else if (state is SupplierInvoiceLoaded) {
              final invoices = state.invoices;
              if (invoices.isEmpty) {
                return _buildEmptyState(theme);
              }
              return RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: invoices.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final inv = invoices[index];
                    return _InvoiceCard(invoice: inv);
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Supplier Invoices Yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "+ Add" to create your first\nsupplier invoice',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final SupplierInvoice invoice;

  const _InvoiceCard({required this.invoice});

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'credit':
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd MMM yyyy').format(invoice.date.toLocal());
    final statusStr = invoice.paymentStatus.displayName;
    final statusClr = _statusColor(invoice.paymentStatus.toSupabase());

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          '/billing-staff/supplier-invoice-detail?invoiceId=${invoice.id}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Supplier name + status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.local_shipping,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.supplierName ?? 'Supplier',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (invoice.invoiceNumber.isNotEmpty)
                                Text(
                                  invoice.invoiceNumber,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusClr.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusStr,
                      style: TextStyle(
                        color: statusClr,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 20),

              // Row 2: Date + Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'â‚¹ ${NumberFormat('#,##,##0.00').format(invoice.totalAmount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),

              // Row 3: Items count
              if (invoice.lineItems.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${invoice.lineItems.length} item${invoice.lineItems.length > 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
