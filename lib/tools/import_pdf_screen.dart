import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../ads/ad_service.dart';
import '../app_feedback.dart';
import '../pdf/pdf_library.dart';
import '../pdf/pdf_service.dart';
import 'pre_screen_ui.dart';

class ImportPdfScreen extends StatefulWidget {
  const ImportPdfScreen({
    super.key,
    required this.fileName,
    required this.bytes,
    this.title = 'Import PDF',
    this.tool = 'Import PDF',
    this.prefix = 'ImportedPDF',
    this.saveLabel = 'Save PDF',
  });

  final String fileName;
  final Uint8List bytes;
  final String title;
  final String tool;
  final String prefix;
  final String saveLabel;

  @override
  State<ImportPdfScreen> createState() => _ImportPdfScreenState();
}

class _ImportPdfScreenState extends State<ImportPdfScreen> {
  bool _saving = false;
  bool _saved = false;
  int? _pages;
  String? _previewError;

  @override
  void initState() {
    super.initState();
    try {
      _pages = PdfService.pageCount(widget.bytes);
    } catch (error) {
      _previewError = error.toString().replaceFirst('Exception: ', '');
    }
  }

  bool _printing = false;

  Future<void> _save() async {
    if (_saving || _saved || _printing) {
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      setState(() => _saving = true);
      try {
        await PdfLibrary.instance.save(
          bytes: widget.bytes,
          tool: widget.tool,
          prefix: widget.prefix,
        );
        if (!mounted) {
          return;
        }
        setState(() => _saved = true);
        await AppPopup.notice(
          context,
          title: 'Saved',
          message: 'PDF saved. You can find it in History.',
          kind: AppNotice.success,
        );
      } catch (error) {
        if (!mounted) {
          return;
        }
        await AppPopup.notice(
          context,
          title: 'Could not save',
          message: error.toString().replaceFirst('Exception: ', ''),
          kind: AppNotice.error,
        );
      } finally {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
    });
  }

  Future<void> _print() async {
    if (_printing || _saving) {
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      setState(() => _printing = true);
      try {
        await PdfLibrary.instance.save(
          bytes: widget.bytes,
          tool: widget.tool,
          prefix: widget.prefix,
        );
        if (!mounted) {
          return;
        }
        await Printing.layoutPdf(onLayout: (_) async => widget.bytes);
      } catch (error) {
        if (!mounted) {
          return;
        }
        await AppPopup.notice(
          context,
          title: 'Could not print',
          message: error.toString().replaceFirst('Exception: ', ''),
          kind: AppNotice.error,
        );
      } finally {
        if (mounted) {
          setState(() => _printing = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final details = [
      _formatBytes(widget.bytes.length),
      if (pages != null) pages == 1 ? '1 page' : '$pages pages',
    ].join('  ·  ');

    return Scaffold(
      backgroundColor: preBackground,
      appBar: preScreenAppBar(context, widget.title),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEEECEC), width: 0.6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.note_add_rounded,
                      color: Color(0xFF3B82F6),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          details,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _previewError == null
                ? PdfPreview(
                    build: (_) => widget.bytes,
                    pdfFileName: widget.fileName,
                    initialPageFormat: PdfPageFormat.a4,
                    dynamicLayout: false,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    allowPrinting: false,
                    allowSharing: false,
                    scrollViewDecoration: const BoxDecoration(color: preBackground),
                    loadingWidget: const Center(
                      child: CircularProgressIndicator(color: prePrimary),
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _previewError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: PreScreenOutlineButton(
                      label: _saving
                          ? 'Saving…'
                          : (_saved ? 'Saved' : widget.saveLabel),
                      onPressed: _saving || _saved || _printing ? null : _save,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PreScreenRedButton(
                      label: 'Print',
                      onPressed: _printing || _saving ? null : _print,
                      loading: _printing,
                      loadingLabel: 'Printing…',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
