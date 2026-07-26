import '../../models/customer.dart';
import '../../repositories/customer_repository.dart';

class MockCustomerRepository implements CustomerRepository {
  final List<Customer> _customers = [
    const Customer(
      id: 'cust-1',
      name: 'Apex Constructions Pvt Ltd',
      phone: '+91 98100 12345',
      email: 'procurement@apexconstructions.com',
      address: 'Plot 12, Cyber City',
      city: 'Gurugram',
      gstin: '07AAAAA0000A1Z5',
      previousBalance: 45000.0,
      warehouseId: 'wh-1',
    ),
    const Customer(
      id: 'cust-2',
      name: 'Sharma Builders & Contractors',
      phone: '+91 98711 98765',
      email: 'sharma.builders@gmail.com',
      address: '45/2 Main Market, Karol Bagh',
      city: 'New Delhi',
      gstin: '07BBBBB1111B1Z2',
      previousBalance: 12500.0,
      warehouseId: 'wh-1',
    ),
    const Customer(
      id: 'cust-3',
      name: 'Verma Interiors & Decor',
      phone: '+91 99999 54321',
      email: 'contact@vermainteriors.in',
      address: 'Shop 88, Furniture Block, Kirti Nagar',
      city: 'New Delhi',
      gstin: null,
      previousBalance: 0.0,
      warehouseId: 'wh-2',
    ),
    const Customer(
      id: 'cust-4',
      name: 'Global Electricals Co.',
      phone: '+91 98188 77665',
      email: 'info@globalelectricals.com',
      address: '22 Bhagirath Palace, Chandni Chowk',
      city: 'Delhi',
      gstin: '07CCCCC2222C1Z9',
      previousBalance: 28400.0,
      warehouseId: 'wh-2',
    ),
  ];

  @override
  Future<List<Customer>> getCustomers({
    String? searchQuery,
    String? warehouseId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _customers.where((c) {
      if (warehouseId != null &&
          warehouseId.isNotEmpty &&
          c.warehouseId != warehouseId) {
        return false;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return c.name.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q) ||
            c.city.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Customer> addCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _customers.insert(0, customer);
    return customer;
  }

  @override
  Future<Customer> updateCustomer(Customer customer) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
    }
    return customer;
  }

  @override
  Future<void> updateCustomerBalance(
    String customerId,
    double newBalance,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      _customers[index] = _customers[index].copyWith(
        previousBalance: newBalance,
      );
    }
  }
}
