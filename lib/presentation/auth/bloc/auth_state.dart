import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  final List<String> recentAccounts;

  const AuthUnauthenticated({this.recentAccounts = const []});

  @override
  List<Object?> get props => [recentAccounts];
}

class AuthError extends AuthState {
  final String message;
  final List<String> recentAccounts;

  const AuthError(this.message, {this.recentAccounts = const []});

  @override
  List<Object?> get props => [message, recentAccounts];
}

class AuthPasswordResetSent extends AuthState {
  final String email;

  const AuthPasswordResetSent(this.email);

  @override
  List<Object?> get props => [email];
}
