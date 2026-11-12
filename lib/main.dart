import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/utils/date_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';

import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian date formatting locale safely
  await AppDateFormatter.ensureInitialized();

  // Initialize Native Local Notification Service
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('NotificationService init error: $e');
  }

  final sharedPreferences = await SharedPreferences.getInstance();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER_ERROR: ${details.exceptionAsString()}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Terjadi sedikit kendala tampilan.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SuaraSiswaApp(),
    ),
  );
}

class SuaraSiswaApp extends ConsumerStatefulWidget {
  const SuaraSiswaApp({super.key});

  @override
  ConsumerState<SuaraSiswaApp> createState() => _SuaraSiswaAppState();
}

class _SuaraSiswaAppState extends ConsumerState<SuaraSiswaApp> {
  @override
  void initState() {
    super.initState();
    // Start background sync for native device notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationSyncManagerProvider).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
