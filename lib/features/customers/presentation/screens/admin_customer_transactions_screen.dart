import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vishnu_enterprises/core/widgets/empty_state.dart';
import 'package:vishnu_enterprises/features/customers/bloc/customer_detail_state.dart';
import 'package:vishnu_enterprises/features/customers/presentation/widgets/invoice_expandable_card.dart';

class AdminCustomerTransactionsScreen extends StatelessWidget {
  final CustomerDetailLoaded data;

  const AdminCustomerTransactionsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
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
                data.customer.name,
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
                'Invoice History',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        body: data.invoices.isEmpty
            ? const EmptyState(
                title: 'No invoices recorded',
                message:
                    'Invoices associated with this customer will appear here.',
                icon: CupertinoIcons.doc_plaintext,
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                itemCount: data.invoices.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return InvoiceExpandableCard(invoice: data.invoices[index]);
                },
              ),
      ),
    );
  }
}
