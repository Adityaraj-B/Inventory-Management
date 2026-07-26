import 'dart:convert';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vishnu_enterprises/core/utils/formatters.dart';
import 'package:vishnu_enterprises/data/models/customer.dart';
import 'package:vishnu_enterprises/data/models/invoice.dart';
import 'package:vishnu_enterprises/data/models/payment.dart';

enum LedgerEntryType { openingBalance, invoice, payment }

class LedgerEntry extends Equatable {
  final String id;
  final DateTime date;
  final String description;
  final LedgerEntryType type;
  final double debit; // Invoice amount added to balance
  final double credit; // Payment amount reducing balance
  final double runningBalance;
  final String? referenceId;

  const LedgerEntry({
    required this.id,
    required this.date,
    required this.description,
    required this.type,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    this.referenceId,
  });

  @override
  List<Object?> get props => [
    id,
    date,
    description,
    type,
    debit,
    credit,
    runningBalance,
    referenceId,
  ];
}

class CustomerLedgerState extends Equatable {
  final Customer? customer;
  final List<LedgerEntry> entries;
  final double currentBalance;
  final bool isLoading;
  final String? error;

  const CustomerLedgerState({
    this.customer,
    this.entries = const [],
    this.currentBalance = 0.0,
    this.isLoading = false,
    this.error,
  });

  @override
  List<Object?> get props => [
    customer,
    entries,
    currentBalance,
    isLoading,
    error,
  ];
}

class CustomerLedgerCubit extends Cubit<CustomerLedgerState> {
  CustomerLedgerCubit() : super(const CustomerLedgerState());

  void buildLedger({
    required Customer customer,
    required List<Invoice> invoices,
    required List<Payment> payments,
  }) {
    emit(const CustomerLedgerState(isLoading: true));

    final rawEvents = <Map<String, dynamic>>[];

    // 1. Invoices
    for (var inv in invoices) {
      rawEvents.add({
        'type': LedgerEntryType.invoice,
        'date': inv.date,
        'amount': inv.grandTotal,
        'description': 'Invoice #${inv.invoiceNumber}',
        'refId': inv.id,
      });

      // Implicit checkout payment if amountPaid > 0 and no separate payment matches
      if (inv.amountPaid > 0) {
        final matchesPayment = payments.any((p) => p.invoiceId == inv.id);
        if (!matchesPayment) {
          rawEvents.add({
            'type': LedgerEntryType.payment,
            'date': inv.date.add(const Duration(seconds: 1)),
            'amount': inv.amountPaid,
            'description': 'Payment at checkout (#${inv.invoiceNumber})',
            'refId': 'chk-${inv.id}',
          });
        }
      }
    }

    // 2. Payments
    for (var pay in payments) {
      rawEvents.add({
        'type': LedgerEntryType.payment,
        'date': pay.date,
        'amount': pay.amount,
        'description': pay.notes != null && pay.notes!.isNotEmpty
            ? 'Payment (${pay.paymentMethod}): ${pay.notes}'
            : 'Payment received (${pay.paymentMethod})',
        'refId': pay.id,
      });
    }

    // Sort chronologically ascending
    rawEvents.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );

    final ledgerEntries = <LedgerEntry>[];
    double balance = customer.previousBalance;

    // Add opening balance entry if > 0
    if (customer.previousBalance > 0) {
      ledgerEntries.add(
        LedgerEntry(
          id: 'op-bal',
          date: DateTime.now().subtract(const Duration(days: 365)),
          description: 'Opening Outstanding Balance',
          type: LedgerEntryType.openingBalance,
          debit: customer.previousBalance,
          credit: 0.0,
          runningBalance: balance,
        ),
      );
    }

    // Process chronological entries
    for (var i = 0; i < rawEvents.length; i++) {
      final item = rawEvents[i];
      final type = item['type'] as LedgerEntryType;
      final amount = item['amount'] as double;
      final dt = item['date'] as DateTime;
      final desc = item['description'] as String;
      final refId = item['refId'] as String;

      if (type == LedgerEntryType.invoice) {
        balance += amount;
        ledgerEntries.add(
          LedgerEntry(
            id: 'ent-$i',
            date: dt,
            description: desc,
            type: type,
            debit: amount,
            credit: 0.0,
            runningBalance: balance,
            referenceId: refId,
          ),
        );
      } else {
        balance -= amount;
        if (balance < 0) balance = 0.0;
        ledgerEntries.add(
          LedgerEntry(
            id: 'ent-$i',
            date: dt,
            description: desc,
            type: type,
            debit: 0.0,
            credit: amount,
            runningBalance: balance,
            referenceId: refId,
          ),
        );
      }
    }

    emit(
      CustomerLedgerState(
        customer: customer,
        entries: ledgerEntries.reversed.toList(), // newest first for display
        currentBalance: balance,
        isLoading: false,
      ),
    );
  }

  Future<void> exportLedgerPdf() async {
    final cust = state.customer;
    if (cust == null) return;

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VISHNU ENTERPRISES',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Customer Ledger Account Statement',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Statement Date:',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      Formatters.date(DateTime.now()),
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
                color: PdfColors.grey100,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        cust.name,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Phone: ${cust.phone} | Email: ${cust.email}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      if (cust.city.isNotEmpty)
                        pw.Text(
                          'City: ${cust.city}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Outstanding Balance',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        Formatters.currency(state.currentBalance),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: [
                'Date',
                'Description',
                'Debit (â‚¹)',
                'Credit (â‚¹)',
                'Balance (â‚¹)',
              ],
              data: state.entries.map((e) {
                return [
                  Formatters.date(e.date),
                  e.description,
                  e.debit > 0 ? Formatters.currency(e.debit) : '-',
                  e.credit > 0 ? Formatters.currency(e.credit) : '-',
                  Formatters.currency(e.runningBalance),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    final pdfBytes = await doc.save();
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Ledger_${cust.name.replaceAll(' ', '_')}.pdf',
    );
  }

  Future<void> exportLedgerExcel() async {
    final cust = state.customer;
    if (cust == null) return;

    final buffer = StringBuffer();
    // Excel CSV Header: date, description, debit, credit, balance
    buffer.writeln('Date,Description,Debit (INR),Credit (INR),Balance (INR)');
    for (final e in state.entries) {
      final dateStr = Formatters.date(e.date);
      final descStr = '"${e.description.replaceAll('"', '""')}"';
      final debitStr = e.debit > 0 ? e.debit.toStringAsFixed(2) : '0.00';
      final creditStr = e.credit > 0 ? e.credit.toStringAsFixed(2) : '0.00';
      final balanceStr = e.runningBalance.toStringAsFixed(2);
      buffer.writeln('$dateStr,$descStr,$debitStr,$creditStr,$balanceStr');
    }

    final bytes = utf8.encode(buffer.toString());
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'Ledger_${cust.name.replaceAll(' ', '_')}.csv',
    );
  }
}
