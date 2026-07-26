import '../models/customer.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getCustomers({
    String? searchQuery,
    String? warehouseId,
  });
  Future<Customer?> getCustomerById(String id);
  Future<Customer> addCustomer(Customer customer);
  Future<Customer> updateCustomer(Customer customer);
  Future<void> updateCustomerBalance(String customerId, double newBalance);
}
