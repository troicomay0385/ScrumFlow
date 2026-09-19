import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _authSubscription;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthGoogleSignInRequested>(_onAuthGoogleSignInRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthLoadRecentAccounts>(_onAuthLoadRecentAccounts);
    on<AuthRemoveRecentAccount>(_onAuthRemoveRecentAccount);

    // Listen to auth state changes from repository
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        add(AuthCheckRequested()); // Re-trigger check if session changes
      }
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _authRepository.getCachedUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        final recentAccounts = await _authRepository.getRecentAccounts();
        emit(AuthUnauthenticated(recentAccounts: recentAccounts));
      }
    } catch (e) {
      final recentAccounts = await _authRepository.getRecentAccounts();
      emit(AuthUnauthenticated(recentAccounts: recentAccounts));
    }
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUp(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      final recentAccounts = await _authRepository.getRecentAccounts();
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(errorMessage, recentAccounts: recentAccounts));
    }
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      final recentAccounts = await _authRepository.getRecentAccounts();
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(errorMessage, recentAccounts: recentAccounts));
    }
  }

  Future<void> _onAuthGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      emit(AuthAuthenticated(user));
    } catch (e) {
      final recentAccounts = await _authRepository.getRecentAccounts();
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(errorMessage, recentAccounts: recentAccounts));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      final recentAccounts = await _authRepository.getRecentAccounts();
      emit(AuthUnauthenticated(recentAccounts: recentAccounts));
    } catch (e) {
      final recentAccounts = await _authRepository.getRecentAccounts();
      emit(AuthError(e.toString(), recentAccounts: recentAccounts));
    }
  }

  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendPasswordReset(event.email);
      emit(AuthPasswordResetSent(event.email));
    } catch (e) {
      final recentAccounts = await _authRepository.getRecentAccounts();
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(AuthError(errorMessage, recentAccounts: recentAccounts));
    }
  }

  Future<void> _onAuthLoadRecentAccounts(
    AuthLoadRecentAccounts event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final recentAccounts = await _authRepository.getRecentAccounts();
      // Keep existing user if authenticated, just a safety check, normally only unauth uses this
      if (state is AuthUnauthenticated) {
        emit(AuthUnauthenticated(recentAccounts: recentAccounts));
      } else if (state is AuthError) {
        emit(AuthUnauthenticated(recentAccounts: recentAccounts));
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _onAuthRemoveRecentAccount(
    AuthRemoveRecentAccount event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.removeRecentAccount(event.email);
      final recentAccounts = await _authRepository.getRecentAccounts();
      if (state is AuthUnauthenticated || state is AuthError || state is AuthInitial) {
        emit(AuthUnauthenticated(recentAccounts: recentAccounts));
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
