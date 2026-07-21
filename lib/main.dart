// lib/main.dart

import 'package:discounts_app/screens/home_screen.dart';
import 'package:discounts_app/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/remote_config_service.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/profile/profile_cubit.dart';
import 'screens/auth/auth_gate.dart';
import 'services/auth_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // 🚀 Call runApp IMMEDIATELY so the UI renders instantly on iOS/iPadOS
  runApp(const DiscountsApp());

  // ── Safe Background Async Initializations ────────────────
  // Run external services asynchronously without blocking runApp() or main thread
  _initServicesAsync();
}

Future<void> _initServicesAsync() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 4));
  } catch (e) {
    debugPrint('❌ Firebase.initializeApp failed or timed out: $e');
  }

  try {
    await RemoteConfigService.initialize()
        .timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('❌ RemoteConfigService.initialize failed or timed out: $e');
  }

  try {
    await NotificationService.initialize()
        .timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('❌ NotificationService.initialize failed or timed out: $e');
  }

  try {
    await NotificationService.subscribeToTopic('new_coupons')
        .timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('❌ NotificationService.subscribeToTopic failed or timed out: $e');
  }
}

class DiscountsApp extends StatelessWidget {
  const DiscountsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ── AuthCubit — root level, persists entire app lifetime ──
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(authService: AuthService())
            ..checkAuth(), // يتحقق من token عند البدء
        ),
        // ── ProfileCubit ──────────────────────────────────────────
        BlocProvider<ProfileCubit>(
          create: (_) => ProfileCubit(authService: AuthService()),
        ),
      ],
      child: MaterialApp(
        title: 'كوبوني',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
