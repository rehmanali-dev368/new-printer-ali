import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

class PdfService {
  static Future<Uint8List> textToPdf(String text) async {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      throw Exception('The text file is empty.');
    }

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Text(
            normalized,
            style: const pw.TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
    return document.save();
  }

  static Future<Uint8List> imagesToPdf(List<String> paths) async {
    if (paths.isEmpty) {
      throw Exception('Capture at least one page.');
    }

    final document = pw.Document();
    for (final path in paths) {
      final bytes = await File(path).readAsBytes();
      final image = pw.MemoryImage(bytes);
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (_) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }
    return document.save();
  }

  static int pageCount(Uint8List bytes) {
    final document = _open(bytes);
    try {
      return document.pages.count;
    } finally {
      document.dispose();
    }
  }

  static Uint8List merge(List<Uint8List> files) {
    if (files.length < 2) {
      throw Exception('Select at least 2 PDF files to merge.');
    }

    final output = sf.PdfDocument();
    final opened = <sf.PdfDocument>[];
    try {
      for (final bytes in files) {
        final source = _open(bytes);
        opened.add(source);
        for (var i = 0; i < source.pages.count; i++) {
          _importPage(output, source, i);
        }
      }
      if (output.pages.count == 0) {
        throw Exception('Could not merge the selected PDFs.');
      }
      return Uint8List.fromList(output.saveSync());
    } finally {
      for (final source in opened) {
        source.dispose();
      }
      output.dispose();
    }
  }

  static List<Uint8List> split(Uint8List source) {
    final count = pageCount(source);
    if (count == 0) {
      throw Exception('No pages were found in the selected PDF.');
    }
    return [for (var i = 0; i < count; i++) pages(source, [i])];
  }

  static Uint8List pages(Uint8List source, List<int> indexes) {
    if (indexes.isEmpty) {
      throw Exception('Select at least one page.');
    }

    final input = _open(source);
    final output = sf.PdfDocument();
    try {
      for (final index in indexes) {
        if (index < 0 || index >= input.pages.count) {
          throw Exception('A selected page is out of range.');
        }
        _importPage(output, input, index);
      }
      return Uint8List.fromList(output.saveSync());
    } finally {
      input.dispose();
      output.dispose();
    }
  }

  static Uint8List lock(Uint8List source, String password) {
    final trimmed = password.trim();
    if (trimmed.isEmpty) {
      throw Exception('A password is required to lock the PDF.');
    }

    final document = _open(source);
    try {
      final security = document.security;
      security.userPassword = trimmed;
      security.ownerPassword = trimmed;
      security.algorithm = sf.PdfEncryptionAlgorithm.aesx128Bit;
      return Uint8List.fromList(document.saveSync());
    } finally {
      document.dispose();
    }
  }

  static Uint8List unlock(Uint8List source, String password) {
    final trimmed = password.trim();
    if (trimmed.isEmpty) {
      throw Exception('Enter the password to unlock.');
    }

    final document = _open(source, password: trimmed);
    try {
      final security = document.security;
      security.userPassword = '';
      security.ownerPassword = '';
      return Uint8List.fromList(document.saveSync());
    } finally {
      document.dispose();
    }
  }

  static void _importPage(sf.PdfDocument output, sf.PdfDocument source, int index) {
    final template = source.pages[index].createTemplate();
    final section = output.sections!.add();
    section.pageSettings.size = template.size;
    section.pageSettings.margins.all = 0;
    section.pages.add().graphics.drawPdfTemplate(
      template,
      Offset.zero,
      template.size,
    );
  }

  static sf.PdfDocument _open(Uint8List bytes, {String? password}) {
    try {
      if (password != null && password.isNotEmpty) {
        return sf.PdfDocument(inputBytes: bytes, password: password);
      }
      return sf.PdfDocument(inputBytes: bytes);
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('password') || message.contains('encrypt')) {
        throw Exception(
          password == null
              ? 'Unlock the password-protected PDF before using this tool.'
              : 'Incorrect password. Please enter the correct password.',
        );
      }
      throw Exception('Could not open this PDF.');
    }
  }
}
