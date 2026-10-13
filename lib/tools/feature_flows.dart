import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_render/pdf_render.dart' as pdf_render;
import 'package:printing/printing.dart';

import '../ads/ad_service.dart';
import '../app_feedback.dart';
import '../pdf/pdf_library.dart';
import '../pdf/pdf_service.dart';
import 'doc_convert_api.dart';
import 'pre_screen_ui.dart';

const _bg = preBackground;
const _blue = prePrimary;

Future<void> openImageToPdf(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const _ImagePdfScreen()),
  );
}

Future<void> openPdfToImage(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const _PdfToImageScreen()),
  );
}

Future<void> openWordToPdf(BuildContext context) {
  return _openOfficeTool(
    context,
    title: 'Word to PDF',
    description: 'Choose a Word file and convert it to PDF.',
    pickLabel: 'Choose Word',
    extensions: const ['doc', 'docx'],
    targetFormat: 'pdf',
    outputExtension: 'pdf',
    outputHint: 'The .pdf extension will be added automatically.',
    prefix: 'WordPDF',
    successMessage: 'PDF file has been saved.',
  );
}

Future<void> openXlsToPdf(BuildContext context) {
  return _openOfficeTool(
    context,
    title: 'XLS to PDF',
    description: 'Choose an Excel file and convert it to PDF.',
    pickLabel: 'Choose Excel',
    extensions: const ['xls', 'xlsx'],
    targetFormat: 'pdf',
    outputExtension: 'pdf',
    outputHint: 'The .pdf extension will be added automatically.',
    prefix: 'XlsPDF',
    successMessage: 'PDF file has been saved.',
  );
}

Future<void> openPptToPdf(BuildContext context) {
  return _openOfficeTool(
    context,
    title: 'PPT to PDF',
    description: 'Choose a PowerPoint file and convert it to PDF.',
    pickLabel: 'Choose PPT',
    extensions: const ['ppt', 'pptx'],
    targetFormat: 'pdf',
    outputExtension: 'pdf',
    outputHint: 'The .pdf extension will be added automatically.',
    prefix: 'PptPDF',
    successMessage: 'PDF file has been saved.',
  );
}

Future<void> openTextToPdf(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const _TextToPdfScreen()),
  );
}

Future<void> openEpubToPdf(BuildContext context) {
  return _openOfficeTool(
    context,
    title: 'EPUB to PDF',
    description: 'Choose an EPUB file and convert it to PDF.',
    pickLabel: 'Choose EPUB',
    extensions: const ['epub'],
    targetFormat: 'pdf',
    outputExtension: 'pdf',
    outputHint: 'The .pdf extension will be added automatically.',
    prefix: 'EpubPDF',
    successMessage: 'PDF file has been saved.',
  );
}

Future<void> openPdfToWord(BuildContext context) {
  return _openOfficeTool(
    context,
    title: 'PDF to Word',
    description: 'Choose a PDF and convert it to Word.',
    pickLabel: 'Choose PDF',
    extensions: const ['pdf'],
    targetFormat: 'docx',
    outputExtension: 'docx',
    outputHint: 'The .docx extension will be added automatically.',
    prefix: 'PDFToWord',
    successMessage: 'Word file has been saved.',
  );
}

Future<void> openPdfToXls(BuildContext context) {
  return _openOfficeTool(
    context,
    title: 'PDF to XLS',
    description: 'Choose a PDF and convert its text to a spreadsheet.',
    pickLabel: 'Choose PDF',
    extensions: const ['pdf'],
    targetFormat: 'xlsx',
    outputExtension: 'xlsx',
    outputHint: 'The .xlsx extension will be added automatically.',
    prefix: 'PDFToXls',
    successMessage: 'Spreadsheet file has been saved.',
  );
}

Future<void> openPdfToPpt(BuildContext context) {
  return _openOfficeTool(
    context,
    title: 'PDF to PPT',
    description: 'Choose a PDF and convert it to PowerPoint.',
    pickLabel: 'Choose PDF',
    extensions: const ['pdf'],
    targetFormat: 'pptx',
    outputExtension: 'pptx',
    outputHint: 'The .pptx extension will be added automatically.',
    prefix: 'PDFToPpt',
    successMessage: 'PowerPoint file has been saved.',
  );
}

Future<void> openPdfToTxt(BuildContext context) {
  return _openOfficeTool(
    context,
    title: 'PDF to TXT',
    description: 'Choose a PDF and extract its text.',
    pickLabel: 'Choose PDF',
    extensions: const ['pdf'],
    targetFormat: 'txt',
    outputExtension: 'txt',
    outputHint: 'The .txt extension will be added automatically.',
    prefix: 'PDFToTxt',
    successMessage: 'Text file has been saved.',
  );
}

Future<void> openPdfToEpub(BuildContext context) {
  return _openOfficeTool(
    context,
    title: 'PDF to EPUB',
    description: 'Choose a PDF and convert it to EPUB.',
    pickLabel: 'Choose PDF',
    extensions: const ['pdf'],
    targetFormat: 'epub',
    outputExtension: 'epub',
    outputHint: 'The .epub extension will be added automatically.',
    prefix: 'PDFToEpub',
    successMessage: 'EPUB file has been saved.',
  );
}

Future<void> _openOfficeTool(
  BuildContext context, {
  required String title,
  required String description,
  required String pickLabel,
  required List<String> extensions,
  required String targetFormat,
  required String outputExtension,
  required String outputHint,
  required String prefix,
  required String successMessage,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _OfficeToolScreen(
        title: title,
        description: description,
        pickLabel: pickLabel,
        extensions: extensions,
        targetFormat: targetFormat,
        outputExtension: outputExtension,
        outputHint: outputHint,
        prefix: prefix,
        successMessage: successMessage,
      ),
    ),
  );
}

Future<void> openCompressPdf(BuildContext context) async {
  final path = await _pickPath(const ['pdf']);
  if (!context.mounted || path == null) {
    return;
  }
  final size = await File(path).length();
  if (!context.mounted) {
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _CompressScreen(pdfPath: path, originalSize: size),
    ),
  );
}

Future<String?> _pickPath(List<String> extensions) async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: extensions,
  );
  if (file == null) {
    return null;
  }
  final path = file.path;
  if (path != null) {
    return path;
  }
  final bytes = await file.readAsBytes();
  final temp = File(
    p.join(
      Directory.systemTemp.path,
      '${DateTime.now().microsecondsSinceEpoch}_${file.name}',
    ),
  );
  await temp.writeAsBytes(bytes, flush: true);
  return temp.path;
}

class _TextToPdfScreen extends StatefulWidget {
  const _TextToPdfScreen();

  @override
  State<_TextToPdfScreen> createState() => _TextToPdfScreenState();
}

class _TextToPdfScreenState extends State<_TextToPdfScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _convert() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) {
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      setState(() => _saving = true);
      final file = File(
        p.join(
          Directory.systemTemp.path,
          'text_${DateTime.now().millisecondsSinceEpoch}.txt',
        ),
      );
      try {
        await file.writeAsString(text, flush: true);
        final bytes = await DocConvertApi.convert(
          filePath: file.path,
          targetFormat: 'pdf',
        );
        final job = await PdfLibrary.instance.save(
          bytes: bytes,
          tool: 'Text to PDF',
          prefix: 'TextPDF',
        );
        if (!mounted) {
          return;
        }
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => _ReadyScreen(job: job)),
        );
      } catch (error) {
        if (!mounted) {
          return;
        }
        await AppPopup.notice(
          context,
          title: 'Could not convert',
          message: error.toString().replaceFirst('Exception: ', ''),
          kind: AppNotice.error,
        );
      } finally {
        if (await file.exists()) {
          await file.delete();
        }
        if (mounted) {
          setState(() => _saving = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final empty = _controller.text.trim().isEmpty;
    return _Page(
      title: 'Text to PDF',
      busy: _saving,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: TextField(
          controller: _controller,
          onChanged: (_) => setState(() {}),
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            height: 1.45,
            color: Color(0xFF111827),
          ),
          decoration: preScreenInputDecoration(label: 'Type or paste your text').copyWith(
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
      bottom: PreScreenRedButton(
        label: 'Convert',
        onPressed: empty || _saving ? null : _convert,
        loading: _saving,
        loadingLabel: 'Converting…',
      ),
    );
  }
}

class _ImagePdfScreen extends StatefulWidget {
  const _ImagePdfScreen();

  @override
  State<_ImagePdfScreen> createState() => _ImagePdfScreenState();
}

class _ImagePdfScreenState extends State<_ImagePdfScreen> {
  final List<String> _paths = [];
  bool _saving = false;

  Future<void> _addMore() async {
    try {
      final files = await ImagePicker().pickMultiImage(
        imageQuality: 90,
        requestFullMetadata: false,
      );
      if (!mounted || files.isEmpty) {
        return;
      }
      setState(() => _paths.addAll(files.map((file) => file.path)));
    } catch (error) {
      _toast(error);
    }
  }

  Future<void> _capture() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        requestFullMetadata: false,
      );
      if (!mounted || image == null) {
        return;
      }
      setState(() => _paths.add(image.path));
    } catch (error) {
      _toast(error);
    }
  }

  Future<void> _save() async {
    if (_saving || _paths.isEmpty) {
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      setState(() => _saving = true);
      try {
        final bytes = await PdfService.imagesToPdf(_paths);
        final job = await PdfLibrary.instance.save(
          bytes: bytes,
          tool: 'Image to PDF',
          prefix: 'ImagePDF',
        );
        if (!mounted) {
          return;
        }
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => _ReadyScreen(job: job)),
        );
      } catch (error) {
        _toast(error);
      } finally {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
    });
  }

  Future<void> _toast(Object error) async {
    if (!mounted) {
      return;
    }
    await AppPopup.notice(
      context,
      title: 'Could not save',
      message: error.toString().replaceFirst('Exception: ', ''),
      kind: AppNotice.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Image to PDF',
      busy: _saving,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          AddFilesDropZone(
            label: _paths.isEmpty ? 'Add images' : 'Add more images',
            hint: 'From your gallery',
            onTap: _saving ? null : _addMore,
          ),
          const SizedBox(height: 12),
          PreScreenOutlineButton(
            label: 'Take a photo',
            icon: Icons.photo_camera_outlined,
            onPressed: _saving ? null : _capture,
          ),
          if (_paths.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Files', style: preSectionStyle),
            const SizedBox(height: 12),
            for (var i = 0; i < _paths.length; i++) ...[
              UploadedFileCard(
                path: _paths[i],
                onDelete: _saving ? null : () => setState(() => _paths.removeAt(i)),
              ),
              if (i != _paths.length - 1) const SizedBox(height: 10),
            ],
          ],
        ],
      ),
      bottom: PreScreenRedButton(
        label: 'Save PDF',
        onPressed: _paths.isEmpty || _saving ? null : _save,
        loading: _saving,
        loadingLabel: 'Saving…',
      ),
    );
  }
}

class _PdfToImageScreen extends StatefulWidget {
  const _PdfToImageScreen();

  @override
  State<_PdfToImageScreen> createState() => _PdfToImageScreenState();
}

class _PdfToImageScreenState extends State<_PdfToImageScreen> {
  String? _pdfPath;
  List<File>? _images;
  String? _error;
  bool _busy = false;

  Future<void> _pick() async {
    final path = await _pickPath(const ['pdf']);
    if (!mounted || path == null) {
      return;
    }
    setState(() {
      _pdfPath = path;
      _images = null;
      _error = null;
    });
    await _convert();
  }

  Future<void> _convert() async {
    final pdfPath = _pdfPath;
    if (pdfPath == null || _busy) {
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      setState(() => _busy = true);
      try {
        final root = await getApplicationDocumentsDirectory();
        final folder = Directory(
          p.join(
            root.path,
            'smart_printer',
            'images_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
        await folder.create(recursive: true);
        final document = await pdf_render.PdfDocument.openFile(pdfPath);
        final images = <File>[];
        try {
          for (var number = 1; number <= document.pageCount; number++) {
            final page = await document.getPage(number);
            final rendered = await page.render(
              width: (page.width * 2).round().clamp(1, 2000),
              height: (page.height * 2).round().clamp(1, 2000),
            );
            final image = await rendered.createImageDetached();
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            rendered.dispose();
            if (bytes == null) {
              continue;
            }
            final file = File(p.join(folder.path, 'page_$number.png'));
            await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
            images.add(file);
          }
        } finally {
          await document.dispose();
        }
        if (images.isEmpty) {
          throw Exception('Could not convert PDF pages to images.');
        }
        for (final image in images) {
          await PdfLibrary.instance.save(
            bytes: await image.readAsBytes(),
            tool: 'PDF to Image',
            prefix: 'PDFImage_${p.basenameWithoutExtension(image.path)}',
            extension: 'png',
          );
        }
        if (mounted) {
          setState(() => _images = images);
        }
      } catch (error) {
        if (mounted) {
          setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
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
    final images = _images;
    return _Page(
      title: 'PDF to Image',
      busy: _busy,
      body: _pdfPath == null
          ? ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                AddFilesDropZone(
                  label: 'Add PDF',
                  hint: 'Each page is saved as an image',
                  onTap: _busy ? null : _pick,
                ),
              ],
            )
          : _error != null
          ? Center(child: Text(_error!, textAlign: TextAlign.center))
          : images == null
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(images[index], fit: BoxFit.cover),
                );
              },
            ),
      bottom: _pdfPath == null
          ? null
          : PreScreenOutlineButton(
              label: 'Choose another PDF',
              onPressed: _busy ? null : _pick,
            ),
    );
  }
}

class _CompressScreen extends StatefulWidget {
  const _CompressScreen({required this.pdfPath, required this.originalSize});

  final String pdfPath;
  final int originalSize;

  @override
  State<_CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<_CompressScreen> {
  double _quality = 0.75;
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      setState(() => _saving = true);
      try {
        final document = await pdf_render.PdfDocument.openFile(widget.pdfPath);
      final images = <String>[];
      try {
        final scale = _quality.clamp(0.45, 1.0);
        for (var number = 1; number <= document.pageCount; number++) {
          final page = await document.getPage(number);
          final rendered = await page.render(
            width: (page.width * scale).round().clamp(1, 1600),
            height: (page.height * scale).round().clamp(1, 1600),
          );
          final image = await rendered.createImageDetached();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          rendered.dispose();
          if (bytes == null) {
            continue;
          }
          final file = File(
            p.join(
              Directory.systemTemp.path,
              'compress_${number}_${DateTime.now().microsecondsSinceEpoch}.png',
            ),
          );
          await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
          images.add(file.path);
        }
      } finally {
        await document.dispose();
      }
      final pdf = await PdfService.imagesToPdf(images);
      final job = await PdfLibrary.instance.save(
        bytes: pdf,
        tool: 'Compress PDF',
        prefix: 'CompressedPDF',
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => _ReadyScreen(job: job)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      await AppPopup.notice(
        context,
        title: 'Could not convert',
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

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Compress PDF',
      busy: _saving,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          PreScreenOptionCard(
            title: 'File',
            child: Text(
              'Current size  ${_formatBytes(widget.originalSize)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(height: 12),
          PreScreenOptionCard(
            title: 'Quality',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${(_quality * 100).round()}%',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                Slider(
                  value: _quality,
                  min: 0.45,
                  max: 1,
                  divisions: 11,
                  activeColor: _blue,
                  onChanged: _saving ? null : (value) => setState(() => _quality = value),
                ),
                const Text(
                  'Lower quality makes a smaller file. It stays on your phone.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: PreScreenRedButton(
        label: 'Save',
        onPressed: _saving ? null : _save,
        loading: _saving,
        loadingLabel: 'Saving…',
      ),
    );
  }
}

class _OfficeToolScreen extends StatefulWidget {
  const _OfficeToolScreen({
    required this.title,
    required this.description,
    required this.pickLabel,
    required this.extensions,
    required this.targetFormat,
    required this.outputExtension,
    required this.outputHint,
    required this.prefix,
    required this.successMessage,
  });

  final String title;
  final String description;
  final String pickLabel;
  final List<String> extensions;
  final String targetFormat;
  final String outputExtension;
  final String outputHint;
  final String prefix;
  final String successMessage;

  @override
  State<_OfficeToolScreen> createState() => _OfficeToolScreenState();
}

class _OfficeToolScreenState extends State<_OfficeToolScreen> {
  final _nameController = TextEditingController();
  String? _path;
  bool _working = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_working) {
      return;
    }
    final path = await _pickPath(widget.extensions);
    if (!mounted || path == null) {
      return;
    }
    setState(() {
      _path = path;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = 'Converted_${p.basenameWithoutExtension(path)}';
      }
    });
  }

  Future<void> _convert() async {
    final path = _path;
    if (path == null || _working) {
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      setState(() => _working = true);
      try {
        final bytes = await DocConvertApi.convert(
          filePath: path,
          targetFormat: widget.targetFormat,
        );
        final job = await PdfLibrary.instance.save(
          bytes: bytes,
          tool: widget.title,
          prefix: widget.prefix,
          extension: widget.outputExtension,
          fileName: _nameController.text,
        );
        if (!mounted) {
          return;
        }
        if (widget.outputExtension == 'pdf') {
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => _ReadyScreen(job: job)),
          );
          return;
        }
        await AppPopup.notice(
          context,
          title: 'Done',
          message: widget.successMessage,
          kind: AppNotice.success,
        );
      } catch (error) {
        if (!mounted) {
          return;
        }
        await AppPopup.notice(
          context,
          title: 'Could not convert',
          message: error.toString().replaceFirst('Exception: ', ''),
          kind: AppNotice.error,
        );
      } finally {
        if (mounted) {
          setState(() => _working = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;
    return _Page(
      title: widget.title,
      busy: _working,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Text(
            widget.description,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          AddFilesDropZone(
            label: path == null ? widget.pickLabel : 'Replace file',
            hint: 'Tap to choose a file',
            onTap: _working ? null : _pick,
          ),
          if (path != null) ...[
            const SizedBox(height: 20),
            const Text('Files', style: preSectionStyle),
            const SizedBox(height: 12),
            UploadedFileCard(
              path: path,
              onDelete: _working
                  ? null
                  : () => setState(() {
                      _path = null;
                      _nameController.clear();
                    }),
            ),
            const SizedBox(height: 16),
            PreScreenField(
              label: 'File name',
              controller: _nameController,
              hint: widget.outputHint,
            ),
          ],
        ],
      ),
      bottom: PreScreenRedButton(
        label: 'Convert & Save',
        onPressed: path == null || _working ? null : _convert,
        loading: _working,
        loadingLabel: 'Converting…',
      ),
    );
  }
}

class _ReadyScreen extends StatelessWidget {
  const _ReadyScreen({required this.job});

  final PdfJob job;

  @override
  Widget build(BuildContext context) {
    final isPdf = job.path.toLowerCase().endsWith('.pdf');
    return _Page(
      title: 'Ready',
      body: Center(
        child: Text(
          isPdf
              ? 'PDF saved. You can print it or find it in History.'
              : 'File saved. You can find it in History.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, height: 1.4),
        ),
      ),
      bottom: isPdf
          ? PreScreenRedButton(
              label: 'Print',
              onPressed: () async {
                await AdService.instance.showInterstitialThen(() async {
                  final bytes = await PdfLibrary.instance.read(job);
                  await Printing.layoutPdf(onLayout: (_) async => bytes);
                });
              },
            )
          : null,
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.title,
    required this.body,
    this.bottom,
    this.busy = false,
  });

  final String title;
  final Widget body;
  final Widget? bottom;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: preScreenAppBar(context, title),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: body),
              if (bottom != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                    child: bottom,
                  ),
                ),
            ],
          ),
          if (busy) const PreScreenBusyOverlay(),
        ],
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
