// lib/cubits/profile/profile_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final AuthService _auth;

  ProfileCubit({AuthService? authService})
      : _auth = authService ?? AuthService(),
        super(const ProfileInitial());

  // ── Load current user ──────────────────────────────────────────
  void load() {
    final user = _auth.currentUser;
    if (user != null) {
      emit(ProfileLoaded(user));
    } else {
      emit(const ProfileError('لم يتم تسجيل الدخول'));
    }
  }

  // ── Fetch fresh from API ───────────────────────────────────────
  Future<void> fetchFromApi() async {
    emit(const ProfileLoading());
    try {
      final user = await _auth.fetchMe();
      emit(ProfileLoaded(user));
    } on AuthException catch (e) {
      emit(ProfileError(e.message));
    } catch (_) {
      emit(const ProfileError('تعذر تحميل البيانات'));
    }
  }

  // ── Update profile info ────────────────────────────────────────
  Future<void> updateProfile({
    required String name,
    required String email,
    String? phone,
    List<String>? preferredCategories,
    String? country,
    String? localAvatarPath,
  }) async {
    emit(const ProfileLoading());
    try {
      final user = await _auth.updateProfile(
        name: name,
        email: email,
        phone: phone,
        country: country,
        preferredCategories: preferredCategories,
        localAvatarPath: localAvatarPath,
      );
      emit(ProfileUpdateSuccess(user));
      emit(ProfileLoaded(user));
    } on AuthException catch (e) {
      emit(ProfileError(e.message));
    } catch (_) {
      emit(const ProfileError('تعذر حفظ التغييرات'));
    }
  }

  // ── Change password ────────────────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    emit(const ProfileLoading());
    try {
      await _auth.updateProfile(
        name: _auth.currentUser?.name ?? '',
        email: _auth.currentUser?.email ?? '',
        currentPassword: currentPassword,
        newPassword: newPassword,
        newPasswordConfirmation: confirmPassword,
      );
      emit(const PasswordChangeSuccess());
      // إرجاع للـ loaded state
      final user = _auth.currentUser;
      if (user != null) emit(ProfileLoaded(user));
    } on AuthException catch (e) {
      emit(ProfileError(e.message));
    } catch (_) {
      emit(const ProfileError('تعذر تغيير كلمة المرور'));
    }
  }
}