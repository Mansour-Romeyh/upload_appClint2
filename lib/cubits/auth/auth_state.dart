// lib/cubits/auth/auth_state.dart

import 'package:equatable/equatable.dart';
import '../../models/auth_models.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// التطبيق شغّال لسه ما قررش
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// بيتحقق من الـ token المخزن
class AuthChecking extends AuthState {
  const AuthChecking();
}

/// مسجّل دخول
class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

/// مش مسجّل دخول
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// بيتحمل (login / register)
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// نجح الـ login أو register
class AuthSuccess extends AuthState {
  final User user;
  final String? message;
  const AuthSuccess(this.user, {this.message});
  @override
  List<Object?> get props => [user, message];
}

/// حصل error
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

/// logout ناجح
class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}