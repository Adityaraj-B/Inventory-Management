import '../../../core/constants.dart';
import '../../models/user.dart';
import '../../repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  User? _currentUser;

  @override
  Future<User?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentUser;
  }

  @override
  Future<User> login({
    required String email,
    required String password,
    required String role,
    String? linkedWarehouseId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final isAdmin = role == AppConstants.roleAdmin;
    _currentUser = User(
      id: isAdmin ? 'u-101' : 'u-202',
      name: isAdmin ? 'Rajesh Sharma (Admin)' : 'Anil Kumar (Billing Staff)',
      email: email,
      role: role,
      linkedWarehouseId: linkedWarehouseId,
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentUser = null;
  }
}
