import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../app_feedback.dart';

const preBackground = Color(0xFFF9FCFF);
const prePrimary = Color(0xFF3B82F6);
const preCardRadius = 16.94;

const preTitleStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 20,
  height: 1.1,
  letterSpacing: -0.3,
  fontWeight: FontWeight.w700,
  color: Color(0xFF111827),
);

const preSectionStyle = TextStyle(
  fontFamily: 'Poppins',
  fontSize: 16,
  height: 1.15,
  letterSpacing: -0.25,
  fontWeight: FontWeight.w700,
  color: Color(0xFF111827),
);

PreferredSizeWidget preScreenAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: preBackground,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    leading: IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 18,
        color: Color(0xFF111827),
      ),
    ),
    title: Text(title, style: preTitleStyle),
  );
}

class AddFilesDropZone extends StatelessWidget {
  const AddFilesDropZone({super.key, required this.label, this.hint, this.onTap});

  final String label;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(preCardRadius),
        child: CustomPaint(
          painter: const _DashedRRectPainter(
            color: prePrimary,
            radius: preCardRadius,
            strokeWidth: 1.4,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 148,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _CloudAddIcon(),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    hint!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloudAddIcon extends StatelessWidget {
  const _CloudAddIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: prePrimary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add_rounded, size: 26, color: prePrimary),
    );
  }
}

class UploadedFileCard extends StatelessWidget {
  const UploadedFileCard({super.key, required this.path, this.onDelete});

  final String path;
  final VoidCallback? onDelete;

  bool get _isImage {
    final ext = p.extension(path).toLowerCase();
    return const {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp', '.heic'}.contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    final exists = file.existsSync();
    final sizeLabel = exists ? readableFileSize(file.lengthSync()) : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(preCardRadius),
        border: Border.all(color: const Color(0xFFEEECEC), width: 0.6),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 54,
              height: 54,
              color: const Color(0xFFEFF6FF),
              child: _isImage && exists
                  ? Image.file(file, fit: BoxFit.cover, filterQuality: FilterQuality.high)
                  : const Icon(Icons.insert_drive_file_rounded, color: prePrimary, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.basename(path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (sizeLabel.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    sizeLabel,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF9CA3AF)),
            ),
        ],
      ),
    );
  }
}

class PreScreenRedButton extends StatelessWidget {
  const PreScreenRedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.loadingLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: prePrimary,
          disabledBackgroundColor: prePrimary.withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: loading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  ),
                  if (loadingLabel != null) ...[
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        loadingLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: Colors.white,
                  ),
                ),
              ),
      ),
    );
  }
}

class PreScreenBusyOverlay extends StatelessWidget {
  const PreScreenBusyOverlay({super.key, this.message = 'Please wait…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: const Color(0x59000000),
          child: Center(child: AppLoaderCard(message: message)),
        ),
      ),
    );
  }
}

class PreScreenOptionCard extends StatelessWidget {
  const PreScreenOptionCard({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(preCardRadius),
        border: Border.all(color: const Color(0xFFEEECEC), width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: preSectionStyle.copyWith(fontSize: 15)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class PreScreenField extends StatelessWidget {
  const PreScreenField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.suffix,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: onChanged,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
          decoration: _fieldDecoration(hint: hint, suffix: suffix),
        ),
      ],
    );
  }
}

class PreScreenOutlineButton extends StatelessWidget {
  const PreScreenOutlineButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF111827),
          side: const BorderSide(color: Color(0xFFEEECEC)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: prePrimary),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({String? hint, Widget? suffix}) {
  return InputDecoration(
    hintText: hint,
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    hintStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Color(0xFF9CA3AF),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEEECEC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEEECEC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: prePrimary, width: 1.4),
    ),
  );
}

InputDecoration preScreenInputDecoration({
  required String label,
  String? helperText,
  Widget? suffixIcon,
}) {
  return _fieldDecoration(hint: label, suffix: suffixIcon).copyWith(helperText: helperText);
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
  });

  final Color color;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 6.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

String readableFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  final kb = bytes / 1024;
  if (kb < 1024) {
    return '${kb.toStringAsFixed(1)} KB';
  }
  return '${(kb / 1024).toStringAsFixed(1)} MB';
}
