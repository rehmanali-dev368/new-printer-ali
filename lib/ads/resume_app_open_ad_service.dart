import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../pro/pro_controller.dart';
import 'remote_config_service.dart';

/// App-open ad after the user returns from background (≥10s), same as
/// Smart-printer-3rd minimize flow. Skipped for Pro / Remote Config OFF.
class ResumeAppOpenAdManager {
  ResumeAppOpenAdManager._();
  static final ResumeAppOpenAdManager instance = ResumeAppOpenAdManager._();

  static const _androidTestAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';
  static const _androidProductionAdUnitId =
      'ca-app-pub-5457165373760928/8973430820';

  String get _androidAdUnitId =>
      kDebugMode ? _androidTestAdUnitId : _androidProductionAdUnitId;

  AppOpenAd? _appOpenAd;
  bool _isLoading = false;
  bool _isShowing = false;
  Completer<bool>? _loadCompleter;

  bool get _adsAllowed =>
      !ProController.instance.isPro && RemoteConfigService.instance.showAds;

  Future<bool> loadAd() {
    if (!Platform.isAndroid) return Future.value(false);

    if (!_adsAllowed) {
      _disposeCurrentAd();
      return Future.value(false);
    }

    if (_appOpenAd != null) return Future.value(true);
    if (_isLoading) {
      return _loadCompleter?.future ?? Future.value(false);
    }

    _isLoading = true;
    _loadCompleter = Completer<bool>();

    AppOpenAd.load(
      adUnitId: _androidAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isLoading = false;
          _loadCompleter?.complete(true);
          _loadCompleter = null;
        },
        onAdFailedToLoad: (error) {
          if (kDebugMode) {
            debugPrint('Resume app-open ad failed to load: $error');
          }
          _isLoading = false;
          _loadCompleter?.complete(false);
          _loadCompleter = null;
        },
      ),
    );

    return _loadCompleter!.future;
  }

  Future<bool> showOnResumeIfAvailable() async {
    if (!_adsAllowed || _isShowing) return false;

    final isLoaded = await loadAd();
    if (!isLoaded || _appOpenAd == null) return false;

    final completer = Completer<void>();
    var didShow = false;
    _isShowing = true;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => didShow = true,
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        _isShowing = false;
        if (!completer.isCompleted) completer.complete();
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) {
          debugPrint('Resume app-open ad failed to show: $error');
        }
        ad.dispose();
        _appOpenAd = null;
        _isShowing = false;
        if (!completer.isCompleted) completer.complete();
        loadAd();
      },
    );

    _appOpenAd!.show();
    await completer.future;
    return didShow;
  }

  void _disposeCurrentAd() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}

class MinimizeAppOpenAdService with WidgetsBindingObserver {
  MinimizeAppOpenAdService._();
  static final MinimizeAppOpenAdService instance = MinimizeAppOpenAdService._();

  static const _requiredBackgroundTime = Duration(seconds: 10);
  static const _resumeShowDelay = Duration(milliseconds: 300);

  final ResumeAppOpenAdManager _manager = ResumeAppOpenAdManager.instance;

  bool _started = false;
  bool _isInBackground = false;
  bool _isHandlingResume = false;
  DateTime? _backgroundEnteredAt;
  Timer? _resumeTimer;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _manager.loadAd();
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _resumeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!_isInBackground) {
        _isInBackground = true;
        _backgroundEnteredAt = DateTime.now();
      }
      _resumeTimer?.cancel();
      _manager.loadAd();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  void _onAppResumed() {
    if (!_isInBackground || _isHandlingResume) return;
    _isInBackground = false;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeShowDelay, _handleResume);
  }

  Future<void> _handleResume() async {
    if (_isHandlingResume) return;
    _isHandlingResume = true;
    try {
      final enteredAt = _backgroundEnteredAt;
      if (enteredAt == null) return;
      if (DateTime.now().difference(enteredAt) < _requiredBackgroundTime) {
        return;
      }
      final hasAd = await _manager.loadAd();
      if (!hasAd) return;
      await _manager.showOnResumeIfAvailable();
      _manager.loadAd();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Minimize app-open flow error: $error');
      }
    } finally {
      _isHandlingResume = false;
    }
  }
}
