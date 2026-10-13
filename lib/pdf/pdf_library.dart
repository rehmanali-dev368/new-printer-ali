import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PdfJob {
  const PdfJob({
    required this.title,
    required this.path,
    required this.tool,
    required this.createdAt,
  });

  final String title;
  final String path;
  final String tool;
  final DateTime createdAt;

  Map<String, String> toJson() => {
    'title': title,
    'path': path,
    'tool': tool,
    'createdAt': createdAt.toIso8601String(),
  };

  static PdfJob? fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final path = json['path'];
    final tool = json['tool'];
    final createdAt = json['createdAt'];
    if (title is! String || path is! String || tool is! String || createdAt is! String) {
      return null;
    }
    return PdfJob(
      title: title,
      path: path,
      tool: tool,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
    );
  }
}

class PdfLibrary extends ChangeNotifier {
  PdfLibrary._();

  static final instance = PdfLibrary._();

  final List<PdfJob> jobs = [];
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    try {
      final file = await _indexFile();
      if (!await file.exists()) {
        return;
      }
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      final rawJobs = decoded['jobs'];
      if (rawJobs is! List) {
        return;
      }
      jobs
        ..clear()
        ..addAll(
          rawJobs
              .whereType<Map>()
              .map((item) => PdfJob.fromJson(Map<String, dynamic>.from(item)))
              .whereType<PdfJob>()
              .where((job) => File(job.path).existsSync()),
        );
      notifyListeners();
    } catch (error, stack) {
      debugPrint('Could not load PDF history: $error\n$stack');
    }
  }

  Future<PdfJob> save({
    required Uint8List bytes,
    required String tool,
    required String prefix,
    String extension = 'pdf',
    String? fileName,
  }) async {
    await load();
    final folder = await _folder();
    final safePrefix = prefix.replaceAll(RegExp(r'[^\w\-]+'), '');
    final safeExtension = extension.replaceAll('.', '').toLowerCase();
    final custom = _safeFileName(fileName);
    var name = custom == null
        ? '${safePrefix}_${DateTime.now().millisecondsSinceEpoch}.$safeExtension'
        : '$custom.$safeExtension';
    var file = File(p.join(folder.path, name));
    if (await file.exists()) {
      name =
          '${p.basenameWithoutExtension(name)}_${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
      file = File(p.join(folder.path, name));
    }
    await file.writeAsBytes(bytes, flush: true);
    final job = PdfJob(
      title: name,
      path: file.path,
      tool: tool,
      createdAt: DateTime.now(),
    );
    jobs.insert(0, job);
    await _writeIndex();
    notifyListeners();
    return job;
  }

  Future<Uint8List> read(PdfJob job) {
    return File(job.path).readAsBytes();
  }

  Future<void> delete(PdfJob job) async {
    await load();
    final file = File(job.path);
    if (await file.exists()) {
      await file.delete();
    }
    jobs.removeWhere((item) => item.path == job.path && item.createdAt == job.createdAt);
    await _writeIndex();
    notifyListeners();
  }

  Future<void> clear() async {
    await load();
    for (final job in List<PdfJob>.from(jobs)) {
      final file = File(job.path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    jobs.clear();
    await _writeIndex();
    notifyListeners();
  }

  String? _safeFileName(String? fileName) {
    final raw = fileName?.trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }
    final withoutExtension = raw.replaceAll(RegExp(r'\.[A-Za-z0-9]{1,5}$'), '');
    final cleaned = withoutExtension.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    if (cleaned.isEmpty || cleaned == '_') {
      return null;
    }
    return cleaned;
  }

  Future<Directory> _folder() async {
    final root = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(root.path, 'smart_printer'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder;
  }

  Future<File> _indexFile() async {
    final folder = await _folder();
    return File(p.join(folder.path, 'history.json'));
  }

  Future<void> _writeIndex() async {
    final file = await _indexFile();
    final payload = jsonEncode({
      'jobs': jobs.map((job) => job.toJson()).toList(),
    });
    await file.writeAsString(payload, flush: true);
  }
}
