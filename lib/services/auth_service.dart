// lib/services/auth_service.dart
//
// Endpoints:
//   POST /api/client/register  — formdata: name, email, password, phone?
//   POST /api/client/login     — formdata: email, password
//   POST /api/client/logout    — Bearer
//   GET  /api/client/me        — Bearer
//   POST /api/client/profile   — Bearer + formdata

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  static const String _base = 'https://couponey.net';
  static const String _userKey = 'couponx_user';

  // ── Singleton ──────────────────────────────────────────────────
  static final AuthService _i = AuthService._();
  AuthService._();
  factory AuthService() => _i;

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser?.token != null;

  Map<String, String> get _bearerHeaders => {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${_currentUser!.token}',
      };

  // ── Init ───────────────────────────────────────────────────────
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userKey);
      if (raw != null) {
        _currentUser = User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  Future<void> _save(User u) async {
    _currentUser = u;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(u.toJson()));
  }

  Future<void> _clear() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // ── Register ───────────────────────────────────────────────────
  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    List<String>? categories,
    String? localAvatarPath,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/api/client/register'),
    )
      ..headers['Accept'] = 'application/json'
      ..fields['name'] = name
      ..fields['email'] = email
      ..fields['password'] = password;

    if (phone != null && phone.isNotEmpty) {
      req.fields['phone'] = phone;
    }
    if (categories != null && categories.isNotEmpty) {
      req.fields['preferred_categories'] = jsonEncode(categories);
    }
    if (localAvatarPath != null && File(localAvatarPath).existsSync()) {
      req.files.add(await http.MultipartFile.fromPath(
        'avatar',
        localAvatarPath,
      ));
    }

    final streamed = await req.send().timeout(const Duration(seconds: 20));
    final res = await http.Response.fromStream(streamed);
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200 || res.statusCode == 201) {
      // أولاً: احفظ التوكن
      await _parseAndSave(data,
          localAvatarPath: localAvatarPath, overrideCategories: categories);
      // ثانياً: اجيب الداتا الكاملة من /me
      try {
        return await fetchMe();
      } catch (_) {
        return _currentUser!;
      }
    }
    throw AuthException(_extractError(data, res.statusCode));
  }

  // ── Login ──────────────────────────────────────────────────────
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/api/client/login'),
    )
      ..headers['Accept'] = 'application/json'
      ..fields['email'] = email
      ..fields['password'] = password;

    final streamed = await req.send().timeout(const Duration(seconds: 15));
    final res = await http.Response.fromStream(streamed);
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200) {
      // أولاً: احفظ التوكن اللي جاء مع الـ login response
      await _parseAndSave(data);
      // ثانياً: اجيب الداتا الكاملة من /me وابقى محدّث
      try {
        return await fetchMe();
      } catch (_) {
        // لو fetchMe فشل، رجّع الداتا اللي عندنا
        return _currentUser!;
      }
    }
    throw AuthException(_extractError(data, res.statusCode));
  }

  // ── Logout ─────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      if (isLoggedIn) {
        await http
            .post(Uri.parse('$_base/api/client/logout'),
                headers: _bearerHeaders)
            .timeout(const Duration(seconds: 10));
      }
    } catch (_) {}
    await _clear();
  }

  // ── Fetch me ───────────────────────────────────────────────────
  Future<User> fetchMe() async {
    final res = await http
        .get(Uri.parse('$_base/api/client/me'), headers: _bearerHeaders)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final userJson = _extractUserJson(data);
      final user = User.fromJson(userJson, token: _currentUser?.token);
      await _save(user);
      return user;
    }
    if (res.statusCode == 401) {
      await _clear();
      throw AuthException('انتهت الجلسة. الرجاء تسجيل الدخول مجدداً.');
    }
    throw AuthException('فشل تحميل البيانات (${res.statusCode})');
  }

  // ── Update profile ─────────────────────────────────────────────
  Future<User> updateProfile({
    required String name,
    required String email,
    String? phone,
    List<String>? preferredCategories,
    String? country,
    String? localAvatarPath,
    String? currentPassword,
    String? newPassword,
    String? newPasswordConfirmation,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/api/client/profile'),
    )
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer ${_currentUser!.token}'
      ..fields['name'] = name
      ..fields['email'] = email;

    if (phone != null && phone.isNotEmpty) req.fields['phone'] = phone;
    if (country != null && country.isNotEmpty) req.fields['country'] = country;
    if (preferredCategories != null && preferredCategories.isNotEmpty) {
      req.fields['preferred_categories'] = jsonEncode(preferredCategories);
    }
    if (currentPassword != null && currentPassword.isNotEmpty) {
      req.fields['current_password'] = currentPassword;
    }
    if (newPassword != null && newPassword.isNotEmpty) {
      req.fields['password'] = newPassword;
      req.fields['password_confirmation'] =
          newPasswordConfirmation ?? newPassword;
    }
    if (localAvatarPath != null && File(localAvatarPath).existsSync()) {
      req.files.add(await http.MultipartFile.fromPath(
        'avatar',
        localAvatarPath,
      ));
    }

    final streamed = await req.send().timeout(const Duration(seconds: 20));
    final res = await http.Response.fromStream(streamed);
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200) {
      final userJson = _extractUserJson(data);
      // نحتفظ بالـ localAvatarPath لو الـ API مردّتش avatar URL
      final user = User.fromJson(userJson, token: _currentUser?.token).copyWith(
        localAvatarPath: localAvatarPath ?? _currentUser?.localAvatarPath,
        preferredCategories:
            preferredCategories ?? _currentUser?.preferredCategories,
      );
      await _save(user);
      return user;
    }
    if (res.statusCode == 401) {
      await _clear();
      throw AuthException('انتهت الجلسة. الرجاء تسجيل الدخول مجدداً.');
    }
    throw AuthException(_extractError(data, res.statusCode));
  }

  // ── Helpers ────────────────────────────────────────────────────
  Future<User> _parseAndSave(
    Map<String, dynamic> data, {
    String? localAvatarPath,
    List<String>? overrideCategories,
  }) async {
    // استخرج التوكن من أي مكان ممكن يبقى فيه
    final token = data['token']?.toString() ??
        data['access_token']?.toString() ??
        (data['data'] is Map
            ? (data['data'] as Map)['token']?.toString()
            : null) ??
        (data['data'] is Map
            ? (data['data'] as Map)['access_token']?.toString()
            : null);
    final userJson = _extractUserJson(data);
    var user = User.fromJson(userJson, token: token);
    if (localAvatarPath != null) {
      user = user.copyWith(localAvatarPath: localAvatarPath);
    }
    if (overrideCategories != null &&
        overrideCategories.isNotEmpty &&
        user.preferredCategories.isEmpty) {
      user = user.copyWith(preferredCategories: overrideCategories);
    }
    await _save(user);
    return user;
  }

  Map<String, dynamic> _extractUserJson(Map<String, dynamic> data) {
    // الـ API بترجع { "client": { ... } } في /me و بعض الـ endpoints
    if (data['client'] is Map) return data['client'] as Map<String, dynamic>;
    if (data['user'] is Map) return data['user'] as Map<String, dynamic>;
    if (data['data'] is Map) {
      final inner = data['data'] as Map<String, dynamic>;
      if (inner['client'] is Map)
        return inner['client'] as Map<String, dynamic>;
      if (inner['user'] is Map) return inner['user'] as Map<String, dynamic>;
      return inner;
    }
    return data;
  }

  String _extractError(Map<String, dynamic> data, int code) {
    if (data['errors'] is Map) {
      final first = (data['errors'] as Map).values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    if (data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'];
    }
    if (code == 422) return 'بيانات غير صحيحة، تحقق من المدخلات';
    if (code == 401) return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    if (code == 409) return 'البريد الإلكتروني مستخدم بالفعل';
    return 'حدث خطأ (كود: $code)';
  }
}
