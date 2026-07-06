// lib/screens/auth/register_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';

// ── Available categories — could be fetched from API ──────────────
const List<String> _kCategories = [
  'أزياء',
  'إلكترونيات',
  'جمال',
  'رياضة',
  'طعام',
  'سفر',
  'صحة',
  'منزل',
  'ترفيه',
  'أخرى',
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _obscure = true;
  List<String> _selectedCats = [];
  String? _localAvatarPath;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Pick image ─────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text('الكاميرا', style: AppTheme.tajawal(fontSize: 15)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('معرض الصور', style: AppTheme.tajawal(fontSize: 15)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 800);
    if (picked != null && mounted) {
      setState(() => _localAvatarPath = picked.path);
    }
  }

  // ── Toggle category ────────────────────────────────────────────
  void _toggleCat(String cat) {
    setState(() {
      if (_selectedCats.contains(cat)) {
        _selectedCats.remove(cat);
      } else {
        _selectedCats.add(cat);
      }
    });
  }

  // ── Submit ─────────────────────────────────────────────────────
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          categories: _selectedCats.isEmpty ? null : _selectedCats,
          localAvatarPath: _localAvatarPath,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: Colors.black54, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'إنشاء حساب جديد',
          style: AppTheme.tajawal(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (_, s) => s is AuthError,
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, textDirection: TextDirection.rtl),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(12),
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Avatar picker ─────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: loading ? null : _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 46,
                            backgroundColor: AppTheme.primary.withOpacity(0.1),
                            backgroundImage: _localAvatarPath != null
                                ? FileImage(File(_localAvatarPath!))
                                : null,
                            child: _localAvatarPath == null
                                ? Icon(Icons.person_outline,
                                    color: AppTheme.primary, size: 40)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 20),
                      child: Text(
                        'صورة الملف الشخصي (اختياري)',
                        style:
                            AppTheme.tajawal(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ),

                  // ── Name ──────────────────────────────────────
                  _SectionLabel('الاسم الكامل *'),
                  _RegField(
                    controller: _nameCtrl,
                    hint: 'محمد أحمد',
                    icon: Icons.person_outline,
                    validator: Validators.name,
                    enabled: !loading,
                  ),
                  const SizedBox(height: 14),

                  // ── Email ─────────────────────────────────────
                  _SectionLabel('البريد الإلكتروني *'),
                  _RegField(
                    controller: _emailCtrl,
                    hint: 'example@email.com',
                    icon: Icons.email_outlined,
                    ltr: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    enabled: !loading,
                  ),
                  const SizedBox(height: 14),

                  // ── Phone ─────────────────────────────────────
                  _SectionLabel('رقم الهاتف (اختياري)'),
                  _RegField(
                    controller: _phoneCtrl,
                    hint: '+966 5X XXX XXXX',
                    icon: Icons.phone_outlined,
                    ltr: true,
                    keyboardType: TextInputType.phone,
                    validator: Validators.phoneOptional,
                    enabled: !loading,
                  ),
                  const SizedBox(height: 14),

                  // ── Password ──────────────────────────────────
                  _SectionLabel('كلمة المرور *'),
                  _RegField(
                    controller: _passCtrl,
                    hint: 'على الأقل 8 أحرف',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    validator: Validators.password,
                    enabled: !loading,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscure = !_obscure),
                      child: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                          size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Categories ────────────────────────────────
                  _SectionLabel('الفئات المفضلة (اختياري)'),
                  const SizedBox(height: 4),
                  Text(
                    'اختر ما يناسبك لتحسين تجربتك',
                    style: AppTheme.tajawal(
                        fontSize: 12, color: AppTheme.textSecondaryinWhite),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _kCategories.map((cat) {
                      final selected = _selectedCats.contains(cat);
                      return GestureDetector(
                        onTap: loading ? null : () => _toggleCat(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primary
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primary
                                  : const Color(0xFFE0E0E0),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: AppTheme.tajawal(
                              fontSize: 13,
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // ── Submit ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppTheme.primary.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              'إنشاء الحساب',
                              style: AppTheme.tajawal(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Login link ────────────────────────────────
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('لديك حساب بالفعل؟ ',
                            style: AppTheme.tajawal(
                                color: AppTheme.textSecondaryinBlack,
                                fontSize: 14)),
                        GestureDetector(
                          onTap: loading ? null : () => Navigator.pop(context),
                          child: Text(
                            'تسجيل الدخول',
                            style: AppTheme.tajawal(
                              color: AppTheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Local widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: AppTheme.tajawal(
              fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      );
}

class _RegField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool ltr;
  final bool enabled;
  final TextInputType keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;

  const _RegField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.ltr = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
        enabled: enabled,
        validator: validator,
        style: AppTheme.tajawal(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.tajawal(color: Colors.grey, fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          suffixIcon: suffix != null
              ? Padding(padding: const EdgeInsets.only(left: 8), child: suffix)
              : null,
          filled: true,
          fillColor: const Color(0xFFF7F7F7),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );
}
