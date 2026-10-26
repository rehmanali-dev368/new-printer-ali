import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pro_products.dart';

/// Tracks Pro subscription state and syncs with Play Store.
///
/// While [isPro] is true: no ads, no Pro paywall. When the user cancels or the
/// plan expires, [refreshFromStore] clears Pro and ads/paywall return.
class ProController extends ChangeNotifier with WidgetsBindingObserver {
  ProController._();
  static final ProController instance = ProController._();

  static Set<String> get proProductIds => ProProducts.all;

  static const String _isProKey = 'is_pro_user';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<void>? _restoreCompleter;

  bool _isPro = false;
  bool _ready = false;
  bool _syncInProgress = false;
  bool _restoreFoundActive = false;
  bool _observingLifecycle = false;

  bool get isPro => _isPro;
  bool get ready => _ready;

  Future<void> init() async {
    if (_ready) return;
    _listenPurchases();
    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool(_isProKey) ?? false;
    _ready = true;
    notifyListeners();
    // Sync with Play before first navigation so cancel/expire is respected.
    try {
      await refreshFromStore().timeout(const Duration(seconds: 8));
    } catch (_) {
      if (kDebugMode) {
        debugPrint('ProController: initial store sync timed out — using cache');
      }
    }
  }

  Future<void> restore() => refreshFromStore();

  /// Re-check Play Store and sync local Pro flag (active sub only).
  Future<void> refreshFromStore() async {
    final available = await _iap.isAvailable();
    if (!available) return;
    if (_syncInProgress) return;

    _syncInProgress = true;
    try {
      final hasActivePro = await _resolveActiveProFromStore();
      await _setPro(hasActivePro);
    } finally {
      _syncInProgress = false;
    }
  }

  Future<bool> _resolveActiveProFromStore() async {
    if (Platform.isAndroid) {
      return _queryActiveProAndroid();
    }

    _restoreFoundActive = false;
    _restoreCompleter = Completer<void>();
    await _iap.restorePurchases();
    await _restoreCompleter!.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {},
    );
    return _restoreFoundActive;
  }

  Future<bool> _queryActiveProAndroid() async {
    final addition =
        _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    if (response.error != null) {
      if (kDebugMode) {
        debugPrint(
          'ProController: queryPastPurchases failed — keeping current Pro state',
        );
      }
      return _isPro;
    }
    return response.pastPurchases.any(_isActiveProPurchase);
  }

  bool _isActiveProPurchase(PurchaseDetails purchase) {
    if (!proProductIds.contains(purchase.productID)) return false;
    if (purchase.status == PurchaseStatus.pending) return false;
    if (purchase.status == PurchaseStatus.error ||
        purchase.status == PurchaseStatus.canceled) {
      return false;
    }

    if (Platform.isAndroid && purchase is GooglePlayPurchaseDetails) {
      return purchase.billingClientPurchase.purchaseState ==
          PurchaseStateWrapper.purchased;
    }

    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
  }

  void _listenPurchases() {
    _purchaseSub ??= _iap.purchaseStream.listen(
      (purchases) async {
        for (final purchase in purchases) {
          if (!proProductIds.contains(purchase.productID)) continue;

          if (_isActiveProPurchase(purchase)) {
            if (_syncInProgress) {
              _restoreFoundActive = true;
            } else {
              await _setPro(true);
            }
          }

          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        }

        if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
          _restoreCompleter!.complete();
        }
      },
      onError: (_) {
        if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
          _restoreCompleter!.complete();
        }
      },
    );
  }

  Future<void> _setPro(bool value) async {
    if (_isPro == value) return;
    _isPro = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isProKey, value);
    notifyListeners();

    if (kDebugMode) {
      debugPrint(
        value
            ? 'ProController: Pro active — ads & paywall disabled'
            : 'ProController: Pro inactive — ads & paywall restored',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshFromStore());
    }
  }

  @override
  void dispose() {
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observingLifecycle = false;
    }
    _purchaseSub?.cancel();
    super.dispose();
  }
}
