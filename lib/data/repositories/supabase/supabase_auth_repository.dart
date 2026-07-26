import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../auth_repository.dart';
import '../../models/user.dart';

class SupabaseAuthRepository implements AuthRepository {
  final supa.SupabaseClient _supabase = supa.Supabase.instance.client;

  @override
  Future<User?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    final userId = session.user.id;
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      // Create fallback user
      return User(
        id: userId,
        name: session.user.email?.split('@').first ?? 'User',
        email: session.user.email ?? '',
        role: 'billing_staff',
      );
    }

    return User.fromJson({
      ...response,
      'email': session.user.email ?? '', // merge email from auth
    });
  }

  @override
  Future<User> login({
    required String email,
    String? linkedWarehouseId,
    required String password,
    required String role,
  }) async {
    // TEMPORARY BYPASS: Return a mock user instead of hitting Supabase auth
    return User(
      id: 'mock-user-id',
      name: email.contains('admin') ? 'Admin User' : 'Billing User',
      email: email,
      role: email.contains('admin') ? 'admin' : 'billing_staff',
      linkedWarehouseId: linkedWarehouseId,
    );
  }

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}
