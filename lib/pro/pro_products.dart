import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Play Console subscription product IDs for Smart Printer.
class ProProducts {
  ProProducts._();

  static const String weekly = 'printer_weekly_plan';
  static const String monthly = 'printer_monthly_plan';
  static const String yearly = 'printer_yearly_plan';

  static const Set<String> all = {weekly, monthly, yearly};
}

/// Loads subscription prices from Google Play with retries.
class ProBilling {
  ProBilling._();
  static final ProBilling instance = ProBilling._();

  final InAppPurchase _iap = InAppPurchase.instance;

  ProductDetails? weekly;
  ProductDetails? monthly;
  ProductDetails? yearly;
  String? lastError;
  bool isLoading = false;

  bool get hasAnyPrice =>
      weekly != null || monthly != null || yearly != null;

  Future<bool> loadPrices({int maxAttempts = 3}) async {
    if (isLoading) return hasAnyPrice;
    isLoading = true;
    lastError = null;

    try {
      final available = await _iap.isAvailable();
      if (!available) {
        lastError = 'Play Store not available on this device';
        if (kDebugMode) {
          debugPrint('ProBilling: store unavailable');
        }
        return false;
      }

      ProductDetailsResponse? response;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        response = await _iap.queryProductDetails(ProProducts.all);
        final err = response.error;
        final hasProducts = response.productDetails.isNotEmpty;
        final isNetwork = err != null &&
            (err.message.toLowerCase().contains('network') ||
                err.code.toLowerCase().contains('network'));

        if (err == null || hasProducts) break;

        if (kDebugMode) {
          debugPrint(
            'ProBilling: attempt $attempt/$maxAttempts failed — ${err.message}',
          );
        }
        if (!isNetwork || attempt == maxAttempts) break;
        await Future<void>.delayed(Duration(seconds: attempt));
      }

      if (response == null) {
        lastError = 'Could not load prices';
        return false;
      }

      if (response.notFoundIDs.isNotEmpty && kDebugMode) {
        debugPrint('ProBilling: not found in Play Console: ${response.notFoundIDs}');
      }

      weekly = null;
      monthly = null;
      yearly = null;

      for (final product in response.productDetails) {
        if (product.id == ProProducts.weekly) weekly = product;
        if (product.id == ProProducts.monthly) monthly = product;
        if (product.id == ProProducts.yearly) yearly = product;
        if (kDebugMode) {
          debugPrint(
            'ProBilling: ${product.id} = ${product.price} (${product.currencyCode})',
          );
        }
      }

      if (!hasAnyPrice) {
        lastError = response.error?.message ??
            (response.notFoundIDs.isNotEmpty
                ? 'Products not found in Play Console'
                : 'Prices unavailable');
        return false;
      }

      lastError = null;
      return true;
    } catch (e) {
      lastError = 'Failed to load prices';
      if (kDebugMode) {
        debugPrint('ProBilling: loadPrices error — $e');
      }
      return false;
    } finally {
      isLoading = false;
    }
  }

  ProductDetails? productFor(String id) {
    if (id == ProProducts.weekly) return weekly;
    if (id == ProProducts.monthly) return monthly;
    if (id == ProProducts.yearly) return yearly;
    return null;
  }
}
