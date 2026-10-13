import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_feedback.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _privacyUrl =
      'https://sites.google.com/view/appsrepublicapps/privacy-policy';
  static const _termsUrl =
      'https://sites.google.com/view/appsrepublicapps/terms-conditions';
  static const _supportEmail = 'appsrepublic99@gmail.com';

  // static const _languages = <_Language>[
  //   _Language('en', 'English', '🇺🇸'),
  //   _Language('ru', 'Russian', '🇷🇺'),
  //   _Language('hi', 'Hindi', '🇮🇳'),
  //   _Language('fr', 'French', '🇫🇷'),
  //   _Language('pt', 'Portuguese', '🇵🇹'),
  //   _Language('it', 'Italian', '🇮🇹'),
  //   _Language('es', 'Spanish', '🇪🇸'),
  //   _Language('pl', 'Polish', '🇵🇱'),
  //   _Language('de', 'German', '🇩🇪'),
  //   _Language('fil', 'Filipino', '🇵🇭'),
  //   _Language('th', 'Thai', '🇹🇭'),
  //   _Language('he', 'Hebrew', '🇮🇱'),
  //   _Language('ar', 'Arabic', '🇸🇦'),
  //   _Language('ja', 'Japanese', '🇯🇵'),
  //   _Language('ko', 'Korean', '🇰🇷'),
  //   _Language('vi', 'Vietnamese', '🇻🇳'),
  // ];
  //
  // String _languageCode = 'en';
  //
  // _Language get _language =>
  //     _languages.firstWhere((item) => item.code == _languageCode);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF9FCFF),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF090808)),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF090808),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _AppHeader(),
          const SizedBox(height: 20),
          _MenuGroup(
            items: [
              _MenuItem(
                icon: Icons.lightbulb_outline,
                title: 'Privacy Policy',
                subtitle: 'Read how your data is used',
                onTap: () => _openUrl(_privacyUrl),
              ),
              _MenuItem(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle: 'Read the terms of use',
                onTap: () => _openUrl(_termsUrl),
              ),
              _MenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Email us for help',
                onTap: _emailSupport,
              ),
            ],
          ),
          // const SizedBox(height: 14),
          // _LanguageCard(
          //   flag: _language.flag,
          //   label: _language.label,
          //   onTap: _pickLanguage,
          // ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      await AppPopup.notice(
        context,
        title: 'Could not open',
        message: 'The link could not be opened on this phone.',
        kind: AppNotice.error,
      );
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: const {
        'subject': 'Smart Printer support',
        'body': 'Hello, I need help with Smart Printer.',
      },
    );
    final launched = await launchUrl(uri);
    if (!launched && mounted) {
      await AppPopup.notice(
        context,
        title: 'Could not open email',
        message: 'No email app is available on this phone.',
        kind: AppNotice.error,
      );
    }
  }

  // Future<void> _pickLanguage() async {
  //   final picked = await showModalBottomSheet<String>(
  //     context: context,
  //     showDragHandle: true,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.white,
  //     builder: (sheetContext) {
  //       final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.5;
  //       return SafeArea(
  //         child: ConstrainedBox(
  //           constraints: BoxConstraints(maxHeight: maxHeight),
  //           child: ListView(
  //             shrinkWrap: true,
  //             padding: const EdgeInsets.only(bottom: 12),
  //             children: [
  //               for (final language in _languages)
  //                 ListTile(
  //                   contentPadding: const EdgeInsets.symmetric(horizontal: 16),
  //                   leading: Text(language.flag, style: const TextStyle(fontSize: 20)),
  //                   title: Text(
  //                     language.label,
  //                     style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
  //                   ),
  //                   trailing: Icon(
  //                     language.code == _languageCode
  //                         ? Icons.check_circle_rounded
  //                         : Icons.radio_button_unchecked,
  //                     color: language.code == _languageCode
  //                         ? const Color(0xFF2F8CFF)
  //                         : const Color(0xFF9CA3AF),
  //                   ),
  //                   onTap: () => Navigator.pop(sheetContext, language.code),
  //                 ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  //   if (picked != null) {
  //     setState(() => _languageCode = picked);
  //   }
  // }

}

// class _Language {
//   const _Language(this.code, this.label, this.flag);
//
//   final String code;
//   final String label;
//   final String flag;
// }

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/splashicon.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Smart Printer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Print, scan, and convert files',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xE6FFFFFF),
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            InkWell(
              onTap: items[i].onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(items[i].icon, size: 20, color: Colors.black87),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].title,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].subtitle,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.black45),
                  ],
                ),
              ),
            ),
            if (i != items.length - 1)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF1F2F6)),
          ],
        ],
      ),
    );
  }
}

// class _LanguageCard extends StatelessWidget {
//   const _LanguageCard({required this.flag, required this.label, required this.onTap});
//
//   final String flag;
//   final String label;
//   final VoidCallback onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(16),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: const Color(0xFFE7ECF5)),
//             boxShadow: const [
//               BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4)),
//             ],
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 34,
//                 height: 34,
//                 alignment: Alignment.center,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF2F6FF),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(Icons.language, color: Color(0xFF156BEA)),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Language',
//                       style: TextStyle(
//                         fontFamily: 'Poppins',
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Color(0xFF1F2937),
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       '$flag  $label',
//                       style: const TextStyle(
//                         fontFamily: 'Poppins',
//                         fontSize: 12,
//                         color: Color(0xFF6B7280),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
