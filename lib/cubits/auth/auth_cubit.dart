// lib/cubits/auth/auth_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _auth;

  AuthCubit({AuthService? authService})
      : _auth = authService ?? AuthService(),
        super(const AuthInitial());

  // ── Auto-login on app start ────────────────────────────────────
  Future<void> checkAuth() async {
    emit(const AuthChecking());
    await _auth.init();
    if (_auth.isLoggedIn && _auth.currentUser != null) {
      emit(AuthAuthenticated(_auth.currentUser!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  // ── Login ──────────────────────────────────────────────────────
  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _auth.login(email: email, password: password);
      print(user.toJson());
      emit(AuthSuccess(user, message: 'مرحباً بك ${user.name}! 👋'));
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(const AuthError('تعذر الاتصال. تحقق من الإنترنت.'));
    }
  }

  // ── Register ───────────────────────────────────────────────────
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    List<String>? categories,
    String? localAvatarPath,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _auth.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        categories: categories,
        localAvatarPath: localAvatarPath,
      );

      print(user.toJson());
      emit(AuthSuccess(user, message: 'تم إنشاء الحساب بنجاح! 🎉'));
      emit(AuthAuthenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(const AuthError('تعذر الاتصال. تحقق من الإنترنت.'));
    }
  }

  // ── Logout ─────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.logout();
    emit(const AuthLoggedOut());
    emit(const AuthUnauthenticated());
  }

  // ── Refresh user (after profile update) ───────────────────────
  void refreshUser() {
    final user = _auth.currentUser;
    if (user != null) emit(AuthAuthenticated(user));
  }
}
