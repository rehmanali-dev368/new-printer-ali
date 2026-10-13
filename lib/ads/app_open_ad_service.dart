import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_service.dart';

class AppOpenAdManager {
  AppOpenAdManager._();
  static final AppOpenAdManager instance = AppOpenAdManager._();

  AppOpenAd? _appOpenAd;
  bool _showing = false;
  bool _loading = false;
  Completer<bool>? _loadCompleter;

  Future<bool> loadAd() {
    if (_appOpenAd != null) {
      return Future.value(true);
    }
    if (_loading) {
      return _loadCompleter?.future ?? Future.value(false);
    }

    _loadCompleter = Completer<bool>();
    _loading = true;

    try {
      AppOpenAd.load(
        adUnitId: AdService.instance.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _loading = false;
            if (!(_loadCompleter?.isCompleted ?? true)) {
              _loadCompleter?.complete(true);
            }
            _loadCompleter = null;
          },
          onAdFailedToLoad: (error) {
            if (kDebugMode) {
              debugPrint('App open ad failed to load: $error');
            }
            _loading = false;
            if (!(_loadCompleter?.isCompleted ?? true)) {
              _loadCompleter?.complete(false);
            }
            _loadCompleter = null;
          },
        ),
      );
    } on PlatformException catch (error) {
      if (kDebugMode) {
        debugPrint('App open ad load platform error: $error');
      }
      _loading = false;
      if (!(_loadCompleter?.isCompleted ?? true)) {
        _loadCompleter?.complete(false);
      }
      _loadCompleter = null;
      return Future.value(false);
    }

    return _loadCompleter!.future;
  }

  Future<bool> showAdIfAvailable({Duration? loadTimeout}) async {
    if (_showing) {
      return false;
    }

    final loadFuture = loadAd();
    final loaded = loadTimeout == null
        ? await loadFuture
        : await loadFuture.timeout(loadTimeout, onTimeout: () => false);
    if (!loaded || _appOpenAd == null) {
      return false;
    }

    final completer = Completer<void>();
    var didShow = false;
    _showing = true;
    final ad = _appOpenAd!;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        _appOpenAd = null;
        _showing = false;
        if (!completer.isCompleted) {
          completer.complete();
        }
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        shown.dispose();
        _appOpenAd = null;
        _showing = false;
        if (!completer.isCompleted) {
          completer.complete();
        }
        loadAd();
      },
      onAdShowedFullScreenContent: (_) {
        didShow = true;
      },
    );

    try {
      await ad.show();
      await completer.future;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('App open show error: $error');
      }
      _showing = false;
      _appOpenAd = null;
      try {
        ad.dispose();
      } catch (_) {}
      if (!completer.isCompleted) {
        completer.complete();
      }
      loadAd();
      return false;
    }
    return didShow;
  }
}
