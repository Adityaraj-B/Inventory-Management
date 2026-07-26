import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String role;
  final String? linkedWarehouseId;

  const AuthLoginRequested({
    required this.email,
    required this.password,
    required this.role,
    this.linkedWarehouseId,
  });

  @override
  List<Object?> get props => [email, password, role, linkedWarehouseId];
}

class AuthLogoutRequested extends AuthEvent {}
