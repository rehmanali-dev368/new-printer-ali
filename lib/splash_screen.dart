import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'ads/app_open_ad_service.dart';
import 'app_shell.dart';
import 'onboarding_screen.dart' show OnboardingScreen, OnboardingStore;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _maxSplashBudget = Duration(seconds: 8);
  static const _minBeforeAd = Duration(seconds: 3);
  static const _minWhenNoAd = Duration(seconds: 5);
  static const _postAdSplash = Duration(seconds: 2);

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    final stopwatch = Stopwatch()..start();

    await Future<void>.delayed(_minBeforeAd);

    final remainingForAd = _remainingBudget(stopwatch);
    final adShown = remainingForAd > Duration.zero
        ? await AppOpenAdManager.instance.showAdIfAvailable(loadTimeout: remainingForAd)
        : false;

    if (adShown) {
      final postAdWait = _postAdSplash < _remainingBudget(stopwatch)
          ? _postAdSplash
          : _remainingBudget(stopwatch);
      if (postAdWait > Duration.zero) {
        await Future<void>.delayed(postAdWait);
      }
    } else {
      final noAdTarget = _minWhenNoAd - stopwatch.elapsed;
      if (noAdTarget > Duration.zero) {
        final waitForNoAd = noAdTarget < _remainingBudget(stopwatch)
            ? noAdTarget
            : _remainingBudget(stopwatch);
        if (waitForNoAd > Duration.zero) {
          await Future<void>.delayed(waitForNoAd);
        }
      }
    }

    await _routeNext();
  }

  Duration _remainingBudget(Stopwatch stopwatch) {
    final remaining = _maxSplashBudget - stopwatch.elapsed;
    return remaining > Duration.zero ? remaining : Duration.zero;
  }

  Future<void> _routeNext() async {
    if (_hasNavigated || !mounted) {
      return;
    }
    _hasNavigated = true;

    final seen = await OnboardingStore.seen();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => seen ? const AppShell() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned(
              top: 168,
              left: 0,
              right: 0,
              child: Center(
                child: Image(
                  image: AssetImage('assets/images/splashicon.png'),
                  width: 176,
                  height: 176,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 104,
              child: Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CupertinoActivityIndicator(
                    radius: 18,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 56,
              right: 56,
              bottom: 76,
              child: Text(
                'Print Fast. Print Smart. Print Perfect.',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 54,
              child: Text(
                'Loading Content',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF949191),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
