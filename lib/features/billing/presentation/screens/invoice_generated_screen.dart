import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vishnu_enterprises/core/routing/route_paths.dart';
import 'package:vishnu_enterprises/core/theme/app_colors.dart';
import 'package:vishnu_enterprises/core/utils/formatters.dart';
import 'package:vishnu_enterprises/data/models/invoice.dart';
import 'package:vishnu_enterprises/features/billing/bloc/invoice_creation_bloc.dart';
import 'package:vishnu_enterprises/features/billing/bloc/invoice_creation_event.dart';
import 'package:flutter/services.dart';

class InvoiceGeneratedScreen extends StatelessWidget {
  final Invoice invoice;

  const InvoiceGeneratedScreen({super.key, required this.invoice});

  Future<void> _exportPdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pwContext) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TAX INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Invoice #: ${invoice.invoiceNumber}'),
              pw.Text('Date: ${Formatters.dateTime(invoice.date)}'),
              pw.Text('Customer ID: ${invoice.customerId}'),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headers: ['Item', 'Qty', 'Rate', 'Total'],
                data: invoice.lineItems.map((item) {
                  return [
                    item.productName,
                    item.quantity.toString(),
                    'â‚¹${item.rate}',
                    'â‚¹${item.lineTotal}',
                  ];
                }).toList(),
              ),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Grand Total:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('â‚¹${invoice.grandTotal}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Amount Paid:'),
                  pw.Text('â‚¹${invoice.amountPaid}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Outstanding Balance:'),
                  pw.Text('â‚¹${invoice.outstandingAmount}'),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${invoice.invoiceNumber}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Generated'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.successBackground,
                child: Icon(
                  CupertinoIcons.checkmark_alt,
                  size: 50,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Invoice Created Successfully!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Invoice #: ${invoice.invoiceNumber}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grand Total:'),
                          Text(
                            Formatters.currency(invoice.grandTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount Paid:'),
                          Text(
                            Formatters.currency(invoice.amountPaid),
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Balance Due:'),
                          Text(
                            Formatters.currency(invoice.outstandingAmount),
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: () => _exportPdf(context),
                icon: const Icon(CupertinoIcons.share),
                label: const Text('Export & Share PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.read<InvoiceCreationBloc>().add(ClearCartRequested());
                  context.go(RoutePaths.billingStaffHome);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Return to Billing Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
