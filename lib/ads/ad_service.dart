import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../pro/pro_controller.dart';
import 'remote_config_service.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // Google sample / test unit IDs (debug builds).
  static const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const _testAppOpenId = 'ca-app-pub-3940256099942544/9257395921';

  // Production units (release builds).
  static const _productionBannerId = 'ca-app-pub-5457165373760928/9654378093';
  static const _productionInterstitialId =
      'ca-app-pub-5457165373760928/5245938801';
  static const _productionAppOpenId = 'ca-app-pub-5457165373760928/8973430820';

  String get bannerAdUnitId => kDebugMode ? _testBannerId : _productionBannerId;

  String get interstitialAdUnitId =>
      kDebugMode ? _testInterstitialId : _productionInterstitialId;

  String get appOpenAdUnitId =>
      kDebugMode ? _testAppOpenId : _productionAppOpenId;

  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  bool _loadingInterstitial = false;
  bool _showingInterstitial = false;

  bool get _isProUser => ProController.instance.isPro;
  bool get _remoteAdsOn => RemoteConfigService.instance.showAds;
  bool get _adsAllowed => !_isProUser && _remoteAdsOn;
  bool _listeningPro = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!_remoteAdsOn) {
      debugPrint('AdService: Remote Config ads OFF — skipping MobileAds init');
      _listenProChanges();
      return;
    }
    await MobileAds.instance.initialize();
    debugPrint(
      kDebugMode
          ? 'AdService: using TEST ad units (debug)'
          : 'AdService: using REAL ad units (release)',
    );
    _listenProChanges();
    if (!_adsAllowed) return;
    _loadInterstitial();
  }

  void _listenProChanges() {
    if (_listeningPro) return;
    _listeningPro = true;
    ProController.instance.addListener(_onProChanged);
  }

  void _onProChanged() {
    if (!_adsAllowed) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _loadingInterstitial = false;
      if (kDebugMode) {
        debugPrint('AdService: ads blocked (Pro or Remote Config) — cleared');
      }
      return;
    }
    // Cancel / expire / remote ads ON → preload again.
    if (_interstitialAd == null && !_loadingInterstitial) {
      _loadInterstitial();
    }
  }

  void _loadInterstitial() {
    if (!_adsAllowed) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      return;
    }
    if (_interstitialAd != null || _loadingInterstitial) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          if (kDebugMode) {
            debugPrint('Interstitial failed to load: $error');
          }
        },
      ),
    );
  }

  /// Feature / tool / printable select.
  Future<void> showSelectInterstitialThen(FutureOr<void> Function() action) {
    return _showInterstitialOrContinue(action);
  }

  /// Print / Save / Download / Convert.
  Future<void> showInterstitialThen(FutureOr<void> Function() action) {
    return _showInterstitialOrContinue(action);
  }

  Future<void> _showInterstitialOrContinue(
    FutureOr<void> Function() action,
  ) async {
    if (!_adsAllowed) {
      await action();
      return;
    }

    if (_showingInterstitial) {
      await action();
      return;
    }

    if (_interstitialAd == null) {
      _loadInterstitial();
      final deadline = DateTime.now().add(const Duration(seconds: 4));
      while (_interstitialAd == null && DateTime.now().isBefore(deadline)) {
        if (!_loadingInterstitial) {
          _loadInterstitial();
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }

    final ad = _interstitialAd;
    if (ad == null) {
      if (kDebugMode) {
        debugPrint('Interstitial unavailable — continuing action');
      }
      await action();
      _loadInterstitial();
      return;
    }

    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        _interstitialAd = null;
        _showingInterstitial = false;
        if (!completer.isCompleted) completer.complete();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        shown.dispose();
        _interstitialAd = null;
        _showingInterstitial = false;
        if (!completer.isCompleted) completer.complete();
        _loadInterstitial();
      },
    );

    _interstitialAd = null;
    _showingInterstitial = true;
    try {
      await ad.show();
      await completer.future;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Interstitial show error: $error');
      }
      _showingInterstitial = false;
      try {
        ad.dispose();
      } catch (_) {}
      if (!completer.isCompleted) completer.complete();
      _loadInterstitial();
    }

    try {
      await action();
    } finally {
      if (!_loadingInterstitial && _interstitialAd == null) {
        _loadInterstitial();
      }
    }
  }
}
