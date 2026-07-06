// lib/cubits/profile/profile_state.dart

import 'package:equatable/equatable.dart';
import '../../models/auth_models.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final User user;
  const ProfileLoaded(this.user);
  @override
  List<Object?> get props => [user];
}

class ProfileUpdateSuccess extends ProfileState {
  final User user;
  final String message;
  const ProfileUpdateSuccess(this.user, {this.message = 'تم الحفظ بنجاح ✅'});
  @override
  List<Object?> get props => [user, message];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
  @override
  List<Object?> get props => [message];
}

class PasswordChangeSuccess extends ProfileState {
  const PasswordChangeSuccess();
}