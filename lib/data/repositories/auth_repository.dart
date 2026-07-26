import '../models/user.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> login({
    required String email,
    required String password,
    required String role,
    String? linkedWarehouseId,
  });
  Future<void> logout();
}
