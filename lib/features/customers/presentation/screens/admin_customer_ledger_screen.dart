import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vishnu_enterprises/core/utils/formatters.dart';
import 'package:vishnu_enterprises/core/widgets/empty_state.dart';
import 'package:vishnu_enterprises/core/widgets/loading_indicator.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_detail_state.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_ledger_cubit.dart';
import 'package:vishnu_enterprises/features/customers/presentation/widgets/ledger_entry_tile.dart';

class AdminCustomerLedgerScreen extends StatefulWidget {
  final CustomerDetailLoaded data;

  const AdminCustomerLedgerScreen({super.key, required this.data});

  @override
  State<AdminCustomerLedgerScreen> createState() =>
      _AdminCustomerLedgerScreenState();
}

class _AdminCustomerLedgerScreenState extends State<AdminCustomerLedgerScreen> {
  @override
  void initState() {
    super.initState();
    _refreshLedger(widget.data);
  }

  @override
  void didUpdateWidget(covariant AdminCustomerLedgerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _refreshLedger(widget.data);
    }
  }

  void _refreshLedger(CustomerDetailLoaded detailData) {
    context.read<CustomerLedgerCubit>().buildLedger(
      customer: detailData.customer,
      invoices: detailData.invoices,
      payments: detailData.payments,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FA),
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
                    color: Colors.black.withValues(alpha: 0.04),
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
          title: Column(
            children: [
              Text(
                widget.data.customer.name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Customer Account Ledger',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        body: BlocBuilder<CustomerLedgerCubit, CustomerLedgerState>(
          builder: (context, ledgerState) {
            if (ledgerState.isLoading) {
              return const Center(
                child: LoadingIndicator(
                  message: 'Loading synced ledger entries...',
                ),
              );
            }

            final cust = ledgerState.customer ?? widget.data.customer;
            final balance = ledgerState.currentBalance;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                cust.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'SYNCED LEDGER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cust.phone,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Divider(
                          color: Colors.white.withValues(alpha: 0.2),
                          height: 1,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OUTSTANDING BALANCE',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Formatters.currency(balance),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Export Options Card
                  Row(
                    children: [
                      Expanded(
                        child: _ExportButton(
                          title: 'Export Excel',
                          subtitle: 'Date, Debit, Credit',
                          icon: CupertinoIcons.table,
                          color: const Color(0xFF107C41), // Excel green
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context
                                .read<CustomerLedgerCubit>()
                                .exportLedgerExcel();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ExportButton(
                          title: 'Export PDF',
                          subtitle: 'Statement sheet',
                          icon: CupertinoIcons.doc_text_fill,
                          color: theme.colorScheme.primary,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context
                                .read<CustomerLedgerCubit>()
                                .exportLedgerPdf();
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Ledger Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LEDGER TRANSACTIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '${ledgerState.entries.length} records',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Ledger Entries
                  if (ledgerState.entries.isEmpty)
                    const EmptyState(
                      title: 'No ledger entries',
                      message:
                          'Invoices and payments will appear in this ledger.',
                      icon: CupertinoIcons.doc_text_search,
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ledgerState.entries.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return LedgerEntryTile(
                          entry: ledgerState.entries[index],
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ExportButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
