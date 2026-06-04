import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await initializeDateFormatting('pt_BR', null);

  runApp(
    ProviderScope(
      child: DevicePreview(
        // Device preview frame only in web debug builds — zero cost on Android/iOS
        enabled: kIsWeb && kDebugMode,
        builder: (context) => const TravelSurpriseApp(),
      ),
    ),
  );
}

class TravelSurpriseApp extends ConsumerWidget {
  const TravelSurpriseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Travel Surprise',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // Pass device_preview locale/builder — no-op when DevicePreview is disabled
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
    );
  }
}
