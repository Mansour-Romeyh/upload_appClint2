// lib/utils/validators.dart

class Validators {
  Validators._();

  // ── Name ───────────────────────────────────────────────────────
  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'الاسم مطلوب';
    if (v.trim().length < 2) return 'الاسم قصير جداً';
    return null;
  }

  // ── Email ──────────────────────────────────────────────────────
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'البريد الإلكتروني مطلوب';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
      return 'أدخل بريد إلكتروني صحيح';
    }
    return null;
  }

  // ── Password ───────────────────────────────────────────────────
  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
    if (v.length < 6) return 'كلمة المرور لا تقل عن ٦ أحرف';
    return null;
  }

  // ── Phone (optional) ──────────────────────────────────────────
  static String? phoneOptional(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    if (v.trim().length < 7) return 'رقم الهاتف غير صحيح';
    return null;
  }

  // ── Phone (required) ──────────────────────────────────────────
  static String? phoneRequired(String? v) {
    if (v == null || v.trim().isEmpty) return 'رقم الهاتف مطلوب';
    if (v.trim().length < 7) return 'رقم الهاتف غير صحيح';
    return null;
  }

  // ── Required (generic) ────────────────────────────────────────
  static String? required(String? v) {
    if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
    return null;
  }
}