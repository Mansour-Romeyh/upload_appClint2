// lib/models/auth_models.dart

import 'dart:convert';
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? localAvatarPath;
  final List<String> preferredCategories;
  final String? country;
  final String? token;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.localAvatarPath,
    this.preferredCategories = const [],
    this.country,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    List<String> parseCategories(dynamic raw) {
      if (raw == null) return [];

      if (raw is List) {
        return raw
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      if (raw is String && raw.trim().isNotEmpty) {
        final value = raw.trim();

        try {
          if (value.startsWith('[') && value.endsWith(']')) {
            final decoded = jsonDecode(value);
            if (decoded is List) {
              return decoded
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
          }
        } catch (_) {}

        return [value];
      }

      return [];
    }

    return User(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: (json['name'] ?? '').toString().trim(),
      email: (json['email'] ?? '').toString().trim(),
      phone: json['phone']?.toString(),
      avatarUrl: json['avatar']?.toString() ??
          json['avatar_url']?.toString() ??
          json['photo']?.toString() ??
          json['profile_image']?.toString(),
      localAvatarPath: json['local_avatar_path']?.toString(),
      preferredCategories: parseCategories(
        json['preferred_categories'] ?? json['categories'] ?? json['interests'],
      ),
      country: json['country']?.toString(),
      token: token ??
          json['token']?.toString() ??
          json['access_token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (localAvatarPath != null) 'local_avatar_path': localAvatarPath,
        'preferred_categories': preferredCategories,
        if (country != null) 'country': country,
        if (token != null) 'token': token,
      };

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? localAvatarPath,
    List<String>? preferredCategories,
    String? country,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      localAvatarPath: localAvatarPath ?? this.localAvatarPath,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      country: country ?? this.country,
      token: token ?? this.token,
    );
  }

  String get initials {
    final cleanName = name.trim();

    if (cleanName.isEmpty) return '?';

    final parts =
        cleanName.split(' ').where((e) => e.trim().isNotEmpty).toList();

    if (parts.isEmpty) return '?';

    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }

    final first = parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    final second = parts[1].isNotEmpty ? parts[1][0].toUpperCase() : '';

    final result = '$first$second';

    return result.isEmpty ? '?' : result;
  }

  String get categoryDisplay =>
      preferredCategories.isNotEmpty ? preferredCategories.join(' · ') : '';

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        avatarUrl,
        localAvatarPath,
        preferredCategories,
        country,
        token,
      ];
}
