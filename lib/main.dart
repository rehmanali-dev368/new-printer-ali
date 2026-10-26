import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads/ad_service.dart';
import 'ads/app_open_ad_service.dart';
import 'ads/remote_config_service.dart';
import 'ads/resume_app_open_ad_service.dart';
import 'pro/pro_controller.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  await ProController.instance.init();
  // Fetch Remote Config before ads so isAppZonePrinterAdsON can block them.
  await RemoteConfigService.instance.init();
  debugPrint(
    '[Startup] Firebase RC connected=${RemoteConfigService.instance.connected} '
    'source=${RemoteConfigService.instance.valueSource} '
    'isAppZonePrinterAdsON=${RemoteConfigService.instance.showAds}',
  );
  await AdService.instance.initialize();
  if (!ProController.instance.isPro &&
      RemoteConfigService.instance.showAds) {
    AppOpenAdManager.instance.loadAd();
  }
  MinimizeAppOpenAdService.instance.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Printer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF9FCFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
