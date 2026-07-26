import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String? gstin;
  final double previousBalance;
  final double currentBalance;
  final String? warehouseId;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    this.gstin,
    required this.previousBalance,
    this.currentBalance = 0.0,
    this.warehouseId,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? gstin,
    double? previousBalance,
    double? currentBalance,
    String? warehouseId,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      gstin: gstin ?? this.gstin,
      previousBalance: previousBalance ?? this.previousBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      warehouseId: warehouseId ?? this.warehouseId,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    final previousBalance = (json['previous_balance'] as num?)?.toDouble() ?? 0.0;
    double currentBalance = previousBalance;

    if (json.containsKey('invoices') || json.containsKey('payments')) {
      final rawEvents = <Map<String, dynamic>>[];
      if (json['invoices'] != null) {
        for (var inv in json['invoices'] as List) {
          final id = inv['id'] as String?;
          final amountPaid = (inv['amount_paid'] as num?)?.toDouble() ?? 0.0;
          final dt = DateTime.tryParse(inv['date'] ?? '') ?? DateTime.now();
          
          rawEvents.add({
            'type': 'invoice',
            'date': dt,
            'amount': (inv['grand_total'] as num?)?.toDouble() ?? 0.0,
          });

          if (amountPaid > 0 && id != null) {
            final payments = json['payments'] as List?;
            final matchesPayment = payments?.any((p) => p['invoice_id'] == id) ?? false;
            
            if (!matchesPayment) {
              rawEvents.add({
                'type': 'payment',
                'date': dt.add(const Duration(seconds: 1)),
                'amount': amountPaid,
              });
            }
          }
        }
      }
      if (json['payments'] != null) {
        for (var pay in json['payments'] as List) {
          rawEvents.add({
            'type': 'payment',
            'date': DateTime.tryParse(pay['date'] ?? '') ?? DateTime.now(),
            'amount': (pay['amount'] as num?)?.toDouble() ?? 0.0,
          });
        }
      }

      rawEvents.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      for (var event in rawEvents) {
        if (event['type'] == 'invoice') {
          currentBalance += event['amount'];
        } else {
          currentBalance -= event['amount'];
          if (currentBalance < 0) currentBalance = 0.0;
        }
      }
    }

    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      gstin: json['gstin'] as String?,
      previousBalance: previousBalance,
      currentBalance: currentBalance,
      warehouseId: json['warehouse_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'gstin': gstin,
      'previous_balance': previousBalance,
      'warehouse_id': warehouseId,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    email,
    address,
    city,
    gstin,
    previousBalance,
    currentBalance,
    warehouseId,
  ];
}
