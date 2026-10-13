import 'package:flutter/material.dart';

const _blue = Color(0xFF3B82F6);

enum AppNotice { info, success, error }

class AppLoader {
  static OverlayEntry? _entry;

  static void show(BuildContext context, {String message = 'Please wait…'}) {
    hide();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }
    _entry = OverlayEntry(
      builder: (_) => _Barrier(child: AppLoaderCard(message: message)),
    );
    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}

class AppLoaderCard extends StatelessWidget {
  const AppLoaderCard({super.key, this.message = 'Please wait…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minWidth: 132, maxWidth: 196),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EEF7)),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: _blue,
                backgroundColor: const Color(0xFFE8F0FE),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13.5,
                height: 1.25,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppPopup {
  static Future<void> notice(
    BuildContext context, {
    required String title,
    required String message,
    AppNotice kind = AppNotice.info,
  }) {
    final style = _noticeStyle(kind);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _PopupShell(
          icon: style.icon,
          iconColor: style.color,
          iconBackground: style.background,
          title: title,
          message: message,
          actions: [
            _PopupButton(
              label: 'OK',
              filled: true,
              color: style.color,
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'OK',
    String cancelLabel = 'Cancel',
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final color = danger ? const Color(0xFFE11D48) : _blue;
        return _PopupShell(
          icon: danger ? Icons.delete_outline_rounded : Icons.help_outline_rounded,
          iconColor: color,
          iconBackground: danger ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
          title: title,
          message: message,
          actions: [
            _PopupButton(
              label: cancelLabel,
              filled: false,
              color: const Color(0xFF6B7280),
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            _PopupButton(
              label: confirmLabel,
              filled: true,
              color: color,
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _NoticeStyle {
  const _NoticeStyle(this.icon, this.color, this.background);

  final IconData icon;
  final Color color;
  final Color background;
}

_NoticeStyle _noticeStyle(AppNotice kind) {
  switch (kind) {
    case AppNotice.success:
      return const _NoticeStyle(Icons.check_rounded, Color(0xFF16A34A), Color(0xFFDCFCE7));
    case AppNotice.error:
      return const _NoticeStyle(Icons.error_outline_rounded, Color(0xFFE11D48), Color(0xFFFEE2E2));
    case AppNotice.info:
      return const _NoticeStyle(Icons.info_outline_rounded, _blue, Color(0xFFEFF6FF));
  }
}

class _Barrier extends StatelessWidget {
  const _Barrier({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x40000000),
      child: Center(child: child),
    );
  }
}

class _PopupShell extends StatelessWidget {
  const _PopupShell({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    required this.actions,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Icon(icon, color: iconColor, size: 28),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PopupButton extends StatelessWidget {
  const _PopupButton({
    required this.label,
    required this.filled,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: filled
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                label,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                label,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }
}
