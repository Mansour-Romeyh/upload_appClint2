// lib/screens/auth/login_screen.dart

import 'package:discounts_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              _errorSnack(state.message),
            );
          }

          if (state is AuthAuthenticated) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                      child: Container(
                        width: 70,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.skip_next_outlined,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "تخطي",
                              style: AppTheme.tajawal(
                                  color: AppTheme.primary, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 48),

                        // ── Logo ─────────────────────────────────────
                        Image.asset(
                          'assets/images/Logo_B.png',
                          height: 100,
                          errorBuilder: (_, __, ___) => Text(
                            'كوبوني',
                            style: AppTheme.tajawal(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        // Text(
                        //   'مرحباً بك 👋',
                        //   style: AppTheme.tajawal(
                        //       fontSize: 24, fontWeight: FontWeight.bold),
                        // ),
                        const SizedBox(height: 6),
                        Text(
                          'سجّل دخولك للوصول إلى كوبوناتك المفضلة',
                          style: AppTheme.tajawal(
                              fontSize: 15,
                              color: AppTheme.textSecondaryinWhite),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 80),

                        // ── Email ─────────────────────────────────────
                        _AuthField(
                          controller: _emailCtrl,
                          label: 'البريد الإلكتروني',
                          hint: 'example@email.com',
                          icon: Icons.email_outlined,
                          ltr: true,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                          enabled: !loading,
                        ),

                        const SizedBox(height: 30),

                        // ── Password ──────────────────────────────────
                        _AuthField(
                          controller: _passCtrl,
                          label: 'كلمة المرور',
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          obscure: _obscure,
                          validator: Validators.password,
                          enabled: !loading,
                          onSubmit: (_) => _submit(),
                          suffix: GestureDetector(
                            onTap: () => setState(() => _obscure = !_obscure),
                            child: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),

                        const SizedBox(height: 60),

                        // ── Login Button ──────────────────────────────
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
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    'تسجيل الدخول',
                                    style: AppTheme.tajawal(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Register link ─────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ليس لديك حساب؟ ',
                              style: AppTheme.tajawal(
                                  color: AppTheme.textSecondaryinWhite,
                                  fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: loading
                                  ? null
                                  : () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterScreen()),
                                      ),
                              child: Text(
                                'إنشاء حساب',
                                style: AppTheme.tajawal(
                                  color: AppTheme.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // SizedBox(
                        //     height: MediaQuery.of(context).size.height * 0.18),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Register Screen
// ─────────────────────────────────────────────────────────────────────────────

// ── Shared helpers ──────────────────────────────────────────────────────────

SnackBar _errorSnack(String msg) => SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl),
      backgroundColor: Colors.red.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 4),
    );

// ── AuthField widget (shared across auth screens) ────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool ltr;
  final bool enabled;
  final TextInputType keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmit;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.ltr = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.validator,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.tajawal(
              fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
          enabled: enabled,
          onFieldSubmitted: onSubmit,
          validator: validator,
          style: AppTheme.tajawal(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.tajawal(color: Colors.grey, fontSize: 13),
            prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 8), child: suffix)
                : null,
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
