import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Firebase Remote Config — master ads switch.
///
/// Console key: [isAppZonePrinterAdsON]
/// - true  → ads allowed (still blocked for Pro users)
/// - false → no ads anywhere
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  static const String adsKey = 'isAppZonePrinterAdsON';

  bool _initialized = false;
  Future<void>? _initFuture;

  /// Default true so ads stay on if fetch fails / Firebase missing.
  bool adsEnabled = true;

  /// True when Firebase init + Remote Config fetch completed without error.
  bool connected = false;

  /// Where [adsEnabled] came from: remote / default / static / fallback.
  String valueSource = 'unset';

  bool get showAds => adsEnabled;
  bool get isInitialized => _initialized;

  Future<void> init() {
    _initFuture ??= _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    if (_initialized) return;
    adsEnabled = true;
    connected = false;
    valueSource = 'unset';

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final app = Firebase.app();
      debugPrint(
        '[RemoteConfig] Firebase OK '
        'name=${app.name} projectId=${app.options.projectId}',
      );

      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );
      await remoteConfig.setDefaults(<String, dynamic>{
        adsKey: true,
      });

      final activated = await remoteConfig.fetchAndActivate();
      adsEnabled = _readBool(remoteConfig, adsKey);
      valueSource = _sourceLabel(remoteConfig.getValue(adsKey).source);
      connected = true;
      _initialized = true;

      debugPrint(
        '[RemoteConfig] ${activated ? 'activated' : 'cached'} '
        'connected=true source=$valueSource $adsKey=$adsEnabled',
      );
      if (valueSource != 'remote') {
        debugPrint(
          '[RemoteConfig] WARN: value not from server yet '
          '(publish/parameter missing?). Using $valueSource=$adsEnabled',
        );
      }
    } catch (error, stack) {
      _initialized = true;
      connected = false;
      adsEnabled = true;
      valueSource = 'fallback';
      debugPrint('[RemoteConfig] FAILED — ads default ON: $error');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stack);
      }
    }
  }

  /// Re-fetch from Firebase (e.g. after resume). Safe no-op if not ready.
  Future<void> refresh() async {
    if (!connected) {
      await init();
      return;
    }
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      final activated = await remoteConfig.fetchAndActivate();
      adsEnabled = _readBool(remoteConfig, adsKey);
      valueSource = _sourceLabel(remoteConfig.getValue(adsKey).source);
      debugPrint(
        '[RemoteConfig] refresh ${activated ? 'activated' : 'cached'} '
        'source=$valueSource $adsKey=$adsEnabled',
      );
    } catch (error) {
      debugPrint('[RemoteConfig] refresh failed: $error');
    }
  }

  bool _readBool(FirebaseRemoteConfig remoteConfig, String key) {
    try {
      final raw = remoteConfig.getValue(key).asString().trim().toLowerCase();
      if (raw == 'true' || raw == '1') return true;
      if (raw == 'false' || raw == '0') return false;
      return remoteConfig.getBool(key);
    } catch (_) {
      return true;
    }
  }

  String _sourceLabel(ValueSource source) {
    switch (source) {
      case ValueSource.valueRemote:
        return 'remote';
      case ValueSource.valueDefault:
        return 'default';
      case ValueSource.valueStatic:
        return 'static';
    }
  }
}
