import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_shell.dart';
import 'pro/pro_controller.dart';
import 'pro/upgrade_pro_screen.dart';

class OnboardingStore {
  static Future<bool> seen() async {
    try {
      final file = await _file().timeout(const Duration(milliseconds: 400));
      return file.existsSync();
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      final file = await _file();
      await file.writeAsString('1', flush: true);
    } catch (_) {}
  }

  static Future<File> _file() async {
    final root = await getApplicationDocumentsDirectory();
    return File(p.join(root.path, 'onboarding_seen'));
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = <_OnboardPage>[
    _OnboardPage(
      image: 'assets/onboarding/home.png',
      title: 'Print Smarter, Anywhere',
      subtitle: 'Print documents, photos, and more with just a few taps.',
    ),
    _OnboardPage(
      image: 'assets/onboarding/files.png',
      title: 'Print & Convert Any File',
      subtitle: 'Easily print & convert documents, photos, and more from your phone.',
    ),
    _OnboardPage(
      image: 'assets/onboarding/scan.png',
      title: 'Scan and Print Documents',
      subtitle: 'Print documents, photos, and more with just a few taps.',
    ),
    _OnboardPage(
      image: 'assets/onboarding/printers.png',
      title: 'Connect to Any Printer',
      subtitle: 'Effortlessly connect to over 10,000+ supported printers of all brands.',
    ),
  ];

  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    OnboardingStore.markSeen();
    final next = ProController.instance.isPro
        ? const AppShell()
        : const UpgradeProScreen(openHomeOnClose: true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  void _continue() {
    if (_index >= _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    final media = MediaQuery.of(context);
    final bottom = media.padding.bottom;
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    const top = 40.0;
    final bottomPad = bottom > 0 ? bottom : 12.0;
    const belowImage = 10.0 + 28.0 + 10.0 + 35.0 + 52.0 + 56.0 + 16.0 + 6.0;
    final maxImageHeight = screenHeight - top - bottomPad - belowImage;
    final scale = (maxImageHeight / 580).clamp(0.0, 1.0);
    final widthScale = (screenWidth / 402).clamp(0.0, 1.0);
    final imageScale = scale < widthScale ? scale : widthScale;
    final imageWidth = 402 * imageScale;
    final imageHeight = 580 * imageScale;
    final buttonWidth = (screenWidth - 30).clamp(0.0, 362.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: top),
          SizedBox(
            width: imageWidth,
            height: imageHeight,
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                return _OnboardArt(image: _pages[index].image);
              },
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                page.title,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                  height: 1,
                  letterSpacing: 0.24,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 243,
            height: 35,
            child: Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                height: 1,
                letterSpacing: 0.16,
                color: Color(0xFF959595),
              ),
            ),
          ),
          const SizedBox(height: 52),
          SizedBox(
            width: buttonWidth,
            height: 56,
            child: ElevatedButton(
              onPressed: _continue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  height: 1,
                  letterSpacing: -0.4,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index ? const Color(0xFF3B82F6) : const Color(0xFFD6E4FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
            ],
          ),
          SizedBox(height: bottomPad),
        ],
      ),
    );
  }
}

class _OnboardArt extends StatelessWidget {
  const _OnboardArt({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0.58, 0.74, 0.96],
        ).createShader(bounds);
      },
      child: Image.asset(image, fit: BoxFit.contain),
    );
  }
}

class _OnboardPage {
  const _OnboardPage({required this.image, required this.title, required this.subtitle});

  final String image;
  final String title;
  final String subtitle;
}
