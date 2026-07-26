import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String customerId;
  final String? invoiceId;
  final double amount;
  final String paymentMethod;
  final DateTime date;
  final double balanceBefore;
  final double balanceAfter;
  final String? referenceNumber;
  final String? notes;

  const Payment({
    required this.id,
    required this.customerId,
    this.invoiceId,
    required this.amount,
    required this.paymentMethod,
    required this.date,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceNumber,
    this.notes,
  });

  Payment copyWith({
    String? id,
    String? customerId,
    String? invoiceId,
    double? amount,
    String? paymentMethod,
    DateTime? date,
    double? balanceBefore,
    double? balanceAfter,
    String? referenceNumber,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
    );
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      customerId: json['customer_id'] as String? ?? '',
      invoiceId: json['invoice_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      balanceBefore: (json['balance_before'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      referenceNumber: json['reference_number'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'invoice_id': invoiceId,
      'amount': amount,
      'payment_method': paymentMethod,
      'date': date.toIso8601String(),
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'reference_number': referenceNumber,
      'notes': notes,
      'is_on_account': invoiceId == null,
    };
  }

  @override
  List<Object?> get props => [
    id,
    customerId,
    invoiceId,
    amount,
    paymentMethod,
    date,
    balanceBefore,
    balanceAfter,
    referenceNumber,
    notes,
  ];
}
