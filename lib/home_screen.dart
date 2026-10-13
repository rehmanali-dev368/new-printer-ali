import 'package:flutter/material.dart';

import 'ads/banner_ad_widget.dart';
// import 'app_feedback.dart';
import 'home_flows.dart';
import 'page_style.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _actions = <_PrinterAction>[
    _PrinterAction(
      title: 'Document',
      color: Color(0xFF3B82F6),
      icon: 'assets/icons/document.png',
    ),
    _PrinterAction(
      title: 'Photos',
      color: Color(0xFF8B5CF6),
      icon: 'assets/icons/photos.png',
    ),
    _PrinterAction(
      title: 'Scan Document',
      color: Color(0xFF06B6D4),
      icon: 'assets/icons/scan.png',
    ),
    _PrinterAction(
      title: 'Camera',
      color: Color(0xFFDBC235),
      icon: 'assets/icons/camera.png',
    ),
    _PrinterAction(
      title: 'Labels',
      color: Color(0xFFF97316),
      icon: 'assets/icons/labels.png',
    ),
    _PrinterAction(
      title: 'Printables',
      color: Color(0xFFEC4899),
      icon: 'assets/icons/printables.png',
    ),
    _PrinterAction(
      title: 'Notes',
      color: Color(0xFFEAB308),
      icon: 'assets/icons/notes.png',
    ),
    _PrinterAction(
      title: 'Webpages',
      color: Color(0xFF14B8A6),
      icon: 'assets/icons/webpages.png',
    ),
    _PrinterAction(
      title: 'Google Drive',
      color: Color(0xFF22C55E),
      icon: 'assets/icons/google_drive.png',
    ),
    _PrinterAction(
      title: 'Email',
      color: Color(0xFFEF4444),
      icon: 'assets/icons/email.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final topGap = pageTopGap(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFF),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, topGap, 20, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                _HomeHeader(),
                SizedBox(height: 16),
                BannerAdWidget(margin: EdgeInsets.only(bottom: 12)),
                _ActionGrid(actions: _actions),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Smart Printer',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 24,
                letterSpacing: 0.24,
                color: Color(0xFF000000),
                height: 1,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

// class _ProButton extends StatelessWidget {
//   const _ProButton();
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => _showComingSoon(context, 'Pro'),
//       child: Container(
//         width: 42,
//         height: 42,
//         decoration: const BoxDecoration(
//           shape: BoxShape.circle,
//           gradient: RadialGradient(
//             radius: 0.5,
//             colors: [Color(0xFFD3C3C3), Color(0xFFFFFFFF)],
//           ),
//           border: Border.fromBorderSide(
//             BorderSide(color: Color(0xFFD4D4D4)),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Color(0x0F000000),
//               blurRadius: 12,
//             ),
//           ],
//         ),
//         child: const Center(
//           child: SizedBox(
//             width: 30,
//             height: 26,
//             child: Stack(
//               children: [
//                 Positioned(
//                   left: 5.09,
//                   top: 5.37,
//                   width: 20.625164031982422,
//                   height: 14.783540725708008,
//                   child: Image(
//                     image: AssetImage('assets/icons/crown.png'),
//                     fit: BoxFit.fill,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<_PrinterAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final cardWidth = (constraints.maxWidth - gap) / 2;
        final cardHeight = cardWidth * 128 / 176;

        return Column(
          children: [
            for (var i = 0; i < actions.length; i += 2) ...[
              if (i > 0) const SizedBox(height: gap),
              SizedBox(
                height: cardHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: _ActionCard(action: actions[i]),
                    ),
                    const SizedBox(width: gap),
                    SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: _ActionCard(action: actions[i + 1]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final _PrinterAction action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / 176;

        return Material(
          color: action.color,
          borderRadius: BorderRadius.circular(20 * scale),
          child: InkWell(
            onTap: () => openHomeFeature(context, action.title),
            borderRadius: BorderRadius.circular(20 * scale),
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            child: Stack(
              children: [
                Positioned(
                  left: 20 * scale,
                  top: 20 * scale,
                  child: Container(
                    width: 52 * scale,
                    height: 52 * scale,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(12 * scale),
                    ),
                    child: Image.asset(
                      action.icon,
                      width: 32 * scale,
                      height: 32 * scale,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  left: 132 * scale,
                  top: 20 * scale,
                  child: Container(
                    width: 24 * scale,
                    height: 24 * scale,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(32 * scale),
                    ),
                    child: Image.asset(
                      'assets/icons/arrow_up_right.png',
                      width: 16 * scale,
                      height: 16 * scale,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  left: 20 * scale,
                  top: 97 * scale,
                  right: 12 * scale,
                  child: Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 16 * scale,
                      letterSpacing: 0.16 * scale,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PrinterAction {
  const _PrinterAction({
    required this.title,
    required this.color,
    required this.icon,
  });

  final String title;
  final Color color;
  final String icon;
}

// void _showComingSoon(BuildContext context, String title) {
//   AppPopup.notice(
//     context,
//     title: title,
//     message: 'This option is coming soon.',
//   );
// }
