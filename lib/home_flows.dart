import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:doc_scan_flutter/doc_scan.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'ads/ad_service.dart';
import 'app_feedback.dart';
import 'labels/label_flow.dart';
import 'printables/printable_screen.dart';
import 'pdf/pdf_library.dart';
import 'pdf/pdf_service.dart';
import 'tools/import_pdf_screen.dart';
import 'tools/pre_screen_ui.dart';

Future<void> openHomeFeature(BuildContext context, String title) async {
  await AdService.instance.showSelectInterstitialThen(() async {
    switch (title) {
      case 'Document':
      case 'Google Drive':
        await _openFile(context, title);
      case 'Photos':
        await _openGallery(context);
      case 'Camera':
        await _openCamera(context);
      case 'Scan Document':
        await _openScan(context);
      case 'Notes':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const _NotesScreen()),
        );
      case 'Webpages':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const _WebScreen(
              title: 'Webpages',
              initialUrl: 'https://www.google.com',
            ),
          ),
        );
      case 'Email':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const _WebScreen(
              title: 'Email',
              initialUrl: 'https://mail.google.com',
            ),
          ),
        );
      case 'Labels':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LabelShapesScreen()),
        );
      case 'Printables':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PrintablesScreen()),
        );
      default:
        break;
    }
  });
}

Future<void> _openFile(BuildContext context, String title) async {
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
  );
  if (picked.isEmpty || !context.mounted) {
    return;
  }
  final file = picked.first;
  final path = await _materialize(file);
  if (!context.mounted) {
    return;
  }
  if (path == null) {
    _toast(context, 'Unable to open that file.');
    return;
  }
  final lower = path.toLowerCase();
  if (lower.endsWith('.pdf')) {
    final bytes = await File(path).readAsBytes();
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImportPdfScreen(
          fileName: p.basename(path),
          bytes: bytes,
          title: title,
          tool: title,
          prefix: title.replaceAll(' ', ''),
        ),
      ),
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => _PhotoReviewScreen(paths: [path], title: title)),
  );
}

Future<void> _openGallery(BuildContext context) async {
  final images = await ImagePicker().pickMultiImage(imageQuality: 90, requestFullMetadata: false);
  if (images.isEmpty || !context.mounted) {
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _PhotoReviewScreen(
        paths: images.map((image) => image.path).toList(),
        title: 'Photos',
      ),
    ),
  );
}

Future<void> _openCamera(BuildContext context) async {
  final image = await ImagePicker().pickImage(
    source: ImageSource.camera,
    imageQuality: 90,
    requestFullMetadata: false,
  );
  if (image == null || !context.mounted) {
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _PhotoReviewScreen(paths: [image.path], title: 'Camera'),
    ),
  );
}

Future<void> _openScan(BuildContext context) async {
  try {
    final pages = await DocumentScanner.scan(format: DocScanFormat.jpeg);
    if (pages == null || pages.isEmpty || !context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PhotoReviewScreen(paths: pages, title: 'Scan Document'),
      ),
    );
  } catch (error) {
    if (context.mounted) {
      _toast(context, error.toString().replaceFirst('Exception: ', ''));
    }
  }
}

Future<String?> _materialize(PlatformFile file) async {
  if (file.path != null && file.path!.isNotEmpty && File(file.path!).existsSync()) {
    return file.path;
  }
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) {
    return null;
  }
  final folder = Directory.systemTemp;
  final name = file.name.replaceAll(RegExp(r'[^\w.\-]+'), '_');
  final out = File(p.join(folder.path, '${DateTime.now().microsecondsSinceEpoch}_$name'));
  await out.writeAsBytes(bytes, flush: true);
  return out.path;
}

void _toast(BuildContext context, String message, {bool success = false}) {
  AppPopup.notice(
    context,
    title: success ? 'Saved' : 'Something went wrong',
    message: message,
    kind: success ? AppNotice.success : AppNotice.error,
  );
}

class _PhotoReviewScreen extends StatefulWidget {
  const _PhotoReviewScreen({required this.paths, required this.title});

  final List<String> paths;
  final String title;

  @override
  State<_PhotoReviewScreen> createState() => _PhotoReviewScreenState();
}

class _PhotoReviewScreenState extends State<_PhotoReviewScreen> {
  bool _busy = false;

  Future<void> _save({required bool print}) async {
    if (_busy) {
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      setState(() => _busy = true);
      try {
        final bytes = await PdfService.imagesToPdf(widget.paths);
        final job = await PdfLibrary.instance.save(
          bytes: bytes,
          tool: widget.title,
          prefix: widget.title.replaceAll(' ', ''),
        );
        if (!mounted) {
          return;
        }
        if (print) {
          await Printing.layoutPdf(onLayout: (_) async => bytes);
        } else {
          _toast(context, 'Saved to History.', success: true);
        }
        if (mounted) {
          Navigator.of(context).pop(job);
        }
      } catch (error) {
        if (mounted) {
          _toast(context, error.toString().replaceFirst('Exception: ', ''));
        }
      } finally {
        if (mounted) {
          setState(() => _busy = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: preBackground,
      appBar: preScreenAppBar(context, widget.title),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.paths.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEECEC)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(widget.paths[index]), fit: BoxFit.cover),
                      ),
                    );
                  },
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
                          label: 'Save PDF',
                          onPressed: _busy ? null : () => _save(print: false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PreScreenRedButton(
                          label: 'Print',
                          onPressed: _busy ? null : () => _save(print: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_busy) const PreScreenBusyOverlay(message: 'Preparing PDF…'),
        ],
      ),
    );
  }
}

class _NotesScreen extends StatefulWidget {
  const _NotesScreen();

  @override
  State<_NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<_NotesScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _print() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) {
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      setState(() => _busy = true);
      try {
        final bytes = await PdfService.textToPdf(text);
        await PdfLibrary.instance.save(bytes: bytes, tool: 'Notes', prefix: 'Note');
        if (!mounted) {
          return;
        }
        await Printing.layoutPdf(onLayout: (_) async => bytes);
      } catch (error) {
        if (mounted) {
          _toast(context, error.toString().replaceFirst('Exception: ', ''));
        }
      } finally {
        if (mounted) {
          setState(() => _busy = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final empty = _controller.text.trim().isEmpty;
    return Scaffold(
      backgroundColor: preBackground,
      appBar: preScreenAppBar(context, 'Notes'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEEECEC), width: 0.6),
                ),
                child: TextField(
                  controller: _controller,
                  onChanged: (_) => setState(() {}),
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, height: 1.4),
                  decoration: const InputDecoration(
                    hintText: 'Type or paste any text here',
                    hintStyle: TextStyle(fontFamily: 'Poppins', color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PreScreenRedButton(
              label: 'Print',
              onPressed: empty || _busy ? null : _print,
              loading: _busy,
              loadingLabel: 'Preparing…',
            ),
          ],
        ),
      ),
    );
  }
}

class _WebScreen extends StatefulWidget {
  const _WebScreen({required this.title, required this.initialUrl});

  final String title;
  final String initialUrl;

  @override
  State<_WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<_WebScreen> {
  final _pageKey = GlobalKey();
  late final WebViewController _controller;
  late final TextEditingController _url;
  bool _loading = true;
  bool _printing = false;
  int _currentPage = 0;
  int _totalPages = 0;

  bool get _isEmail => widget.initialUrl.contains('mail.google.com');

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.initialUrl);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _loading = true);
            }
          },
          onPageFinished: (url) {
            if (!mounted) {
              return;
            }
            setState(() {
              _loading = false;
              if (!_isEmail) {
                _url.text = url;
              }
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _load(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final url = trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';
    setState(() => _loading = true);
    _controller.loadRequest(Uri.parse(url));
  }

  Future<void> _printPage() async {
    if (_printing || _pageKey.currentContext == null) {
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted || _pageKey.currentContext == null) {
        return;
      }
      setState(() {
        _printing = true;
        _currentPage = 0;
        _totalPages = 0;
      });
      try {
        final shots = await _capturePages();
        final bytes = shots.isEmpty ? await _textFallback() : await _shotsToPdf(shots);
        await PdfLibrary.instance.save(
          bytes: bytes,
          tool: widget.title,
          prefix: _isEmail ? 'Email' : 'WebPage',
        );
        if (!mounted) {
          return;
        }
        await Printing.layoutPdf(onLayout: (_) async => bytes);
      } catch (_) {
        if (mounted) {
          _toast(context, 'Could not print this page.');
        }
      } finally {
        if (mounted) {
          setState(() => _printing = false);
        }
      }
    });
  }

  Future<List<Uint8List>> _capturePages() async {
    final raw = await _controller.runJavaScriptReturningResult(
      'document.body ? document.body.scrollHeight.toString() : "0"',
    );
    final totalHeight = double.tryParse(raw.toString().replaceAll('"', '')) ?? 0;
    if (totalHeight <= 0 || !mounted) {
      return const [];
    }
    final viewHeight = MediaQuery.sizeOf(context).height;
    final pages = min((totalHeight / viewHeight).ceil(), 8);
    setState(() => _totalPages = pages);
    final boundary = _pageKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      return const [];
    }
    final shots = <Uint8List>[];
    for (var i = 0; i < pages; i++) {
      if (!mounted) {
        break;
      }
      setState(() => _currentPage = i + 1);
      await _controller.runJavaScript('window.scrollTo(0, ${i * viewHeight});');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) {
        continue;
      }
      shots.add(data.buffer.asUint8List());
    }
    await _controller.runJavaScript('window.scrollTo(0, 0);');
    return shots;
  }

  Future<Uint8List> _shotsToPdf(List<Uint8List> shots) async {
    final pdf = pw.Document();
    for (final shot in shots) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.Image(pw.MemoryImage(shot), fit: pw.BoxFit.contain),
          ),
        ),
      );
    }
    return pdf.save();
  }

  Future<Uint8List> _textFallback() async {
    final raw = await _controller.runJavaScriptReturningResult(
      'document.body && document.body.innerText ? document.body.innerText.slice(0, 12000) : document.title',
    );
    final text = raw.toString().replaceAll('"', '').trim();
    return PdfService.textToPdf(text.isEmpty ? _url.text : text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: preBackground,
      appBar: preScreenAppBar(context, widget.title),
      body: Stack(
        children: [
          Column(
            children: [
              if (!_isEmail)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Browse & Print',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFEEECEC)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.language, size: 20, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _url,
                                textInputAction: TextInputAction.go,
                                onSubmitted: _load,
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'https://example.com',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _loading ? null : () => _load(_url.text),
                              child: const Text(
                                'Go',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RepaintBoundary(
                  key: _pageKey,
                  child: WebViewWidget(controller: _controller),
                ),
              ),
            ],
          ),
          if (_printing)
            Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: const Color(0x59000000),
                  child: Center(
                    child: AppLoaderCard(
                      message: _totalPages > 0
                          ? 'Page $_currentPage / $_totalPages'
                          : 'Preparing print…',
                    ),
                  ),
                ),
              ),
            )
          else if (_loading)
            const Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: Color(0x59000000),
                  child: Center(child: AppLoaderCard(message: 'Loading page…')),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: PreScreenRedButton(
            label: _isEmail ? 'Print Email' : 'Print Full Page',
            onPressed: _printing || _loading ? null : _printPage,
            loading: _printing,
            loadingLabel: _totalPages > 0 ? 'Page $_currentPage / $_totalPages' : 'Preparing…',
          ),
        ),
      ),
    );
  }
}

