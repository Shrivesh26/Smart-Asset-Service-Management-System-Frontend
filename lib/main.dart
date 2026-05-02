import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_asset_service/utils/theme_provider.dart';

import 'services/auth_service.dart';
import 'services/asset_service.dart';
import 'services/booking_service.dart';
import 'services/provider_service.dart';
import 'services/service_catalog_service.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'utils/app_theme.dart';
import 'utils/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        // Core API
        Provider<ApiService>(create: (_) => apiService),

        // Auth — drives all routing decisions
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(apiService, prefs),
        ),

        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(prefs),
        ),
        
        // Feature services
        ChangeNotifierProxyProvider<AuthService, AssetService>(
          create: (ctx) => AssetService(apiService),
          update: (ctx, auth, prev) => prev ?? AssetService(apiService),
        ),
        ChangeNotifierProxyProvider<AuthService, BookingService>(
          create: (ctx) => BookingService(apiService),
          update: (ctx, auth, prev) => prev ?? BookingService(apiService),
        ),
        ChangeNotifierProxyProvider<AuthService, ProviderService>(
          create: (ctx) => ProviderService(apiService),
          update: (ctx, auth, prev) => prev ?? ProviderService(apiService),
        ),
        ChangeNotifierProxyProvider<AuthService, ServiceCatalogService>(
          create: (ctx) => ServiceCatalogService(apiService),
          update: (ctx, auth, prev) =>
              prev ?? ServiceCatalogService(apiService),
        ),
        ChangeNotifierProxyProvider<AuthService, NotificationService>(
          create: (ctx) => NotificationService(apiService),
          update: (ctx, auth, prev) => prev ?? NotificationService(apiService),
        ),
      ],
      child: const SmartAssetApp(),
    ),
  );
}

class SmartAssetApp extends StatelessWidget {
  const SmartAssetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'Smart Asset & Service Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme:  AppTheme.darkTheme,          
      themeMode:  themeProvider.themeMode, 
      routerConfig: AppRoutes.router(authService),
    );
  }
}
