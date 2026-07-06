// lib/screens/auth/auth_gate.dart
//
// بيستمع لـ AuthCubit ويوجّه المستخدم:
//   AuthChecking     → Splash/loading
//   AuthAuthenticated → HomeScreen
//   AuthUnauthenticated → LoginScreen

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/profile/profile_cubit.dart';
import '../../utils/theme.dart';
import '../home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      // listenWhen: نحتاجه فقط لو عايزين نعمل snackbar عند الـ success
      listenWhen: (prev, curr) =>
          curr is AuthSuccess || curr is AuthLoggedOut,
      listener: (context, state) {
        if (state is AuthSuccess && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message!,
                style: AppTheme.tajawal(color: Colors.white, fontSize: 14),
                textDirection: TextDirection.rtl,
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(12),
            ),
          );
        }
        if (state is AuthAuthenticated) {
          // نحمّل الـ profile بعد الـ login
          context.read<ProfileCubit>().load();
        }
      },
      builder: (context, state) {
        // ── Loading / Checking ─────────────────────────────────
        if (state is AuthInitial || state is AuthChecking) {
          return const _SplashLoader();
        }

        // ── Logged in ──────────────────────────────────────────
        if (state is AuthAuthenticated) {
          return const HomeScreen();
        }

        // ── Not logged in ──────────────────────────────────────
        return const LoginScreen();
      },
    );
  }
}

// ── Splash Loading Screen ──────────────────────────────────────────
class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/Logo.png',
              height: 80,
              errorBuilder: (_, __, ___) => Text(
                'كوبوني',
                style: AppTheme.tajawal(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}