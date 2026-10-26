import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_shell.dart';
import 'pro_controller.dart';
import 'pro_products.dart';

enum _ProPlan { weekly, monthly, yearly }

/// Pro paywall — matches the provided Get Pro Access design.
class UpgradeProScreen extends StatefulWidget {
  const UpgradeProScreen({super.key, this.openHomeOnClose = false});

  /// After splash / first open, close should open Home instead of popping.
  final bool openHomeOnClose;

  @override
  State<UpgradeProScreen> createState() => _UpgradeProScreenState();
}

class _UpgradeProScreenState extends State<UpgradeProScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF497FE5);
  static const Color _restoreGrey = Color(0xFF9CA3AF);

  static const String _privacyUrl =
      'https://sites.google.com/view/applicationsprivacypolicy/home';
  static const String _termsUrl =
      'https://sites.google.com/view/applicationterms/home';

  static const _features = [
    'Supports 10,000+ Printers',
    'Unlimited Prints, Saves and Shares',
    'Unlock All PDF Tools',
    'Unlimited Scan Documents',
    'Ad Free Experience',
  ];

  _ProPlan _selected = _ProPlan.yearly;
  bool _loadingPrices = true;
  bool _buying = false;
  bool _restoring = false;
  String? _priceError;

  ProductDetails? _weekly;
  ProductDetails? _monthly;
  ProductDetails? _yearly;
  late final AnimationController _ctaController;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  final InAppPurchase _iap = InAppPurchase.instance;

  @override
  void initState() {
    super.initState();
    ProController.instance.addListener(_onProChanged);
    _purchaseSub = _iap.purchaseStream.listen(_onPurchaseUpdates);
    _ctaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _loadPrices();
  }

  @override
  void dispose() {
    ProController.instance.removeListener(_onProChanged);
    _purchaseSub?.cancel();
    _ctaController.dispose();
    super.dispose();
  }

  void _onPurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (!ProProducts.all.contains(purchase.productID)) continue;
      if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        if (!mounted) return;
        setState(() => _buying = false);
        if (purchase.status == PurchaseStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                purchase.error?.message ?? 'Purchase failed. Please try again.',
              ),
            ),
          );
        }
      }
    }
  }

  void _onProChanged() {
    if (!mounted) return;
    if (ProController.instance.isPro) {
      _finish();
    }
  }

  Future<void> _loadPrices() async {
    setState(() {
      _loadingPrices = true;
      _priceError = null;
    });

    final billing = ProBilling.instance;
    final ok = await billing.loadPrices();
    if (!mounted) return;

    setState(() {
      _weekly = billing.weekly;
      _monthly = billing.monthly;
      _yearly = billing.yearly;
      _priceError = ok ? null : (billing.lastError ?? 'Prices unavailable');
      _loadingPrices = false;
    });
  }

  ProductDetails? get _selectedProduct {
    switch (_selected) {
      case _ProPlan.weekly:
        return _weekly;
      case _ProPlan.monthly:
        return _monthly;
      case _ProPlan.yearly:
        return _yearly;
    }
  }

  Future<void> _restorePurchases() async {
    if (_restoring || _buying) return;
    setState(() => _restoring = true);
    try {
      await ProController.instance.restore();
      if (!mounted) return;
      final isPro = ProController.instance.isPro;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPro
                ? 'Pro activated. Enjoy unlimited access.'
                : 'No active subscription found.',
          ),
        ),
      );
      if (isPro) _finish();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to restore purchases.')),
      );
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _buySelected() async {
    final product = _selectedProduct;
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price unavailable. Try again later.')),
      );
      return;
    }
    setState(() => _buying = true);
    try {
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started && mounted) {
        setState(() => _buying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed. Please try again.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _buying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase error: $e')),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  void _finish() {
    if (!mounted) return;
    setState(() => _buying = false);
    if (widget.openHomeOnClose || !Navigator.of(context).canPop()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  void _onContinueFree() {
    if (!widget.openHomeOnClose && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  String _displayPrice(ProductDetails? product) {
    if (product == null) return '--';
    final price = product.price.trim();
    if (price.isEmpty) return '--';
    return price.replaceAll(RegExp(r'[.,]00(?=\D|$)'), '');
  }

  String _currencySymbol(ProductDetails? product) {
    if (product == null) return r'$';
    final price = product.price.trim();
    final match = RegExp(r'^[^\d\s.,]+').firstMatch(price);
    if (match != null) return match.group(0)!;
    return product.currencySymbol.isNotEmpty ? product.currencySymbol : r'$';
  }

  String _formatMoney(ProductDetails? product, double amount) {
    final symbol = _currencySymbol(product);
    if (amount >= 100) {
      return '$symbol${amount.toStringAsFixed(0)}';
    }
    final fixed = amount.toStringAsFixed(2);
    final trimmed = fixed.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return '$symbol$trimmed';
  }

  /// Weekly equivalent of yearly for "Just $0.58 per week".
  String _yearlyWeeklyLabel() {
    final yearly = _yearly;
    if (yearly == null) return 'Just -- per week';
    final perWeek = yearly.rawPrice / 52.0;
    return 'Just ${_formatMoney(yearly, perWeek)} per week';
  }

  /// Yearly savings vs paying weekly for 52 weeks (else vs 12× monthly).
  /// Example: weekly 550 × 52 = 28600, yearly 4150 → ~85% off.
  String? get _yearlyOffBadge {
    final yearly = _yearly;
    if (yearly == null || yearly.rawPrice <= 0) return null;

    double referenceYearCost;
    if (_weekly != null && _weekly!.rawPrice > 0) {
      referenceYearCost = _weekly!.rawPrice * 52;
    } else if (_monthly != null && _monthly!.rawPrice > 0) {
      referenceYearCost = _monthly!.rawPrice * 12;
    } else {
      return null;
    }

    if (referenceYearCost <= yearly.rawPrice) return null;

    final pct =
        ((1 - (yearly.rawPrice / referenceYearCost)) * 100).round().clamp(1, 99);
    return '$pct% off';
  }

  TextStyle get _figtreeTitle => GoogleFonts.figtree(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: 0,
      );

  TextStyle get _figtreeBody => GoogleFonts.figtree(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.0,
        letterSpacing: 0,
        color: Colors.black,
      );

  @override
  Widget build(BuildContext context) {
    final busy = _buying;
    final media = MediaQuery.of(context);
    // Clear Android gesture / 3-button nav and iOS home indicator.
    final bottomPad = math.max(media.viewPadding.bottom, 16.0);
    final topPad = media.viewPadding.top;

    return PopScope(
      canPop: !widget.openHomeOnClose && Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _finish();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFD6E8FF),
                Color(0xFFF5F9FF),
                Color(0xFFFFFFFF),
              ],
              stops: [0.0, 0.35, 1.0],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: topPad, bottom: bottomPad),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const designW = 390.0;
                const designH = 844.0;
                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: designW,
                      height: designH,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                            child: SizedBox(
                              height: 36,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: (_restoring || _buying)
                                      ? null
                                      : _restorePurchases,
                                  style: TextButton.styleFrom(
                                    foregroundColor: _restoreGrey,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: _restoring
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: _restoreGrey,
                                          ),
                                        )
                                      : Text(
                                          'Restore',
                                          style: GoogleFonts.figtree(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: _restoreGrey,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 16, 20, 0),
                              child: LayoutBuilder(
                                builder: (context, inner) {
                                  return FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.topCenter,
                                    child: SizedBox(
                                      width: inner.maxWidth,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 10),
                                          Image.asset(
                                            'assets/images/pro_icon.png',
                                            width: 210,
                                            height: 140,
                                            fit: BoxFit.contain,
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: 280,
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: 'Get Pro ',
                                                    style: _figtreeTitle
                                                        .copyWith(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: 'Access',
                                                    style: _figtreeTitle
                                                        .copyWith(
                                                      color: _accent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Get unlimited access to all premium features',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.figtree(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              height: 1.25,
                                              color:
                                                  const Color(0xFF1A1A1A),
                                            ),
                                          ),
                                          const SizedBox(height: 30),
                                          Center(
                                            child: IntrinsicWidth(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  for (var i = 0;
                                                      i < _features.length;
                                                      i++)
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.only(
                                                        bottom: i ==
                                                                _features
                                                                        .length -
                                                                    1
                                                            ? 0
                                                            : 10,
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize
                                                                .min,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .check_rounded,
                                                            size: 20,
                                                            color: _accent,
                                                          ),
                                                          const SizedBox(
                                                              width: 10),
                                                          Text(
                                                            _features[i],
                                                            style:
                                                                _figtreeBody,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 36),
                                          if (_loadingPrices)
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                  bottom: 8),
                                              child: SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  color: _accent,
                                                ),
                                              ),
                                            )
                                          else if (_priceError != null)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      bottom: 8),
                                              child: Text(
                                                _priceError!,
                                                textAlign:
                                                    TextAlign.center,
                                                style: GoogleFonts.figtree(
                                                  fontSize: 12,
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                          _PlanCard(
                                            title: 'Weekly Plan',
                                            priceTop:
                                                _displayPrice(_weekly),
                                            priceBottom: 'per week',
                                            selected: _selected ==
                                                _ProPlan.weekly,
                                            onTap: () => setState(
                                              () => _selected =
                                                  _ProPlan.weekly,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          _PlanCard(
                                            title: 'Yearly Plan',
                                            subtitle:
                                                _yearlyWeeklyLabel(),
                                            priceTop:
                                                _displayPrice(_yearly),
                                            priceBottom: 'per year',
                                            selected: _selected ==
                                                _ProPlan.yearly,
                                            badge: _yearlyOffBadge,
                                            onTap: () => setState(
                                              () => _selected =
                                                  _ProPlan.yearly,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          _PlanCard(
                                            title: 'Monthly Plan',
                                            priceTop:
                                                _displayPrice(_monthly),
                                            priceBottom: 'per month',
                                            selected: _selected ==
                                                _ProPlan.monthly,
                                            onTap: () => setState(
                                              () => _selected =
                                                  _ProPlan.monthly,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: AnimatedBuilder(
                                    animation: _ctaController,
                                    builder: (context, _) {
                                      final t = _ctaController.value;
                                      final zoomWave =
                                          Curves.easeInOut.transform(
                                        t < 0.5 ? t * 2 : (1 - t) * 2,
                                      );
                                      final scale =
                                          busy ? 1.0 : 1 + (0.03 * zoomWave);
                                      return Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: busy
                                                ? _accent.withValues(
                                                    alpha: 0.7)
                                                : _accent,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x0F000000),
                                                offset: Offset(0, 4),
                                                blurRadius: 12,
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            clipBehavior: Clip.antiAlias,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                if (!busy) ...[
                                                  _ButtonCenterRipple(
                                                    progress: t,
                                                  ),
                                                  _ButtonCenterRipple(
                                                    progress:
                                                        (t + 0.5) % 1.0,
                                                  ),
                                                ],
                                                InkWell(
                                                  onTap: busy
                                                      ? null
                                                      : _buySelected,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20),
                                                  splashFactory: InkRipple
                                                      .splashFactory,
                                                  splashColor: Colors.white
                                                      .withValues(
                                                          alpha: 0.28),
                                                  highlightColor:
                                                      Colors.white
                                                          .withValues(
                                                              alpha: 0.10),
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    height: 56,
                                                    child: Center(
                                                      child: busy
                                                          ? const SizedBox(
                                                              width: 22,
                                                              height: 22,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                strokeWidth:
                                                                    2.4,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            )
                                                          : Text(
                                                              'Subscribe Now',
                                                              style: GoogleFonts
                                                                  .figtree(
                                                                fontSize:
                                                                    20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                height: 1.0,
                                                                letterSpacing:
                                                                    0,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: 362,
                                  height: 17,
                                  child: Text(
                                    'No commitment. Cancel anytime',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    style: GoogleFonts.figtree(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.0,
                                      letterSpacing: 0,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      _FooterLink(
                                        label: 'Privacy policy',
                                        onTap: () =>
                                            _openUrl(_privacyUrl),
                                      ),
                                      const _FooterDot(),
                                      _FooterLink(
                                        label: 'Continue for Free',
                                        onTap: _onContinueFree,
                                      ),
                                      const _FooterDot(),
                                      _FooterLink(
                                        label: 'Terms of Use',
                                        onTap: () =>
                                            _openUrl(_termsUrl),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.priceTop,
    required this.priceBottom,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  final String title;
  final String priceTop;
  final String priceBottom;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  static const Color _selectBorder = Color(0xFF007BFF);
  static const Color _selectBg = Color(0xFFE4EEFD);
  static const Color _idleBorder = Color(0xFFE1E1E1);
  static const double _badgeOverlap = 10;

  static TextStyle get _priceStyle => GoogleFonts.figtree(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: 0,
        color: Colors.black,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: badge != null ? _badgeOverlap : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: selected ? _selectBg : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected ? _selectBorder : _idleBorder,
                    width: selected ? 1.5 : 0.72,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selected
                          ? const Color(0x0F11984F)
                          : const Color(0x0F000000),
                      offset: const Offset(0, 2),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: subtitle == null
                          ? Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.figtree(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.figtree(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.figtree(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 60,
                        minHeight: 28,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            priceTop,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.right,
                            style: _priceStyle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            priceBottom,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.right,
                            style: _priceStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -_badgeOverlap,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A00),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.figtree(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  const _FooterDot();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        '|',
        style: GoogleFonts.figtree(
          fontSize: 12,
          color: const Color(0xFFC5C9D4),
        ),
      ),
    );
  }
}

class _ButtonCenterRipple extends StatelessWidget {
  const _ButtonCenterRipple({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final opacity = (1 - progress) * 0.52;
    final radius = 0.05 + (2.85 * progress);
    final ringStart = (0.78 * progress).clamp(0.0, 1.0);
    final ringEnd = (ringStart + 0.20).clamp(0.0, 1.0);
    return IgnorePointer(
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: radius,
              colors: [
                Colors.white.withValues(alpha: opacity * 0.18),
                Colors.white.withValues(alpha: opacity * 0.55),
                Colors.white.withValues(alpha: opacity),
                Colors.white.withValues(alpha: 0),
              ],
              stops: [0.0, ringStart, ringEnd, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: GoogleFonts.figtree(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}
