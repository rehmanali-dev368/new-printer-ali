import 'dart:io';
import 'dart:typed_data';

import 'package:doc_scan_flutter/doc_scan.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';

import '../ads/ad_service.dart';
import '../app_feedback.dart';
import '../pdf/pdf_library.dart';
import '../pdf/pdf_service.dart';
import 'import_pdf_screen.dart';
import 'pre_screen_ui.dart';

const _pageColor = preBackground;
const _blue = prePrimary;

Future<void> openSmartScan(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const _ScanPagesScreen(idCard: false)),
  );
}

Future<void> openScanIdCard(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const _ScanPagesScreen(idCard: true)),
  );
}

Future<void> openImportPdf(BuildContext context) {
  return _openPdfReview(context, title: 'Import PDF');
}

Future<void> openPrintPdf(BuildContext context) {
  return _openPdfReview(
    context,
    title: 'Print PDF',
    tool: 'Print PDF',
    prefix: 'PrintPDF',
    saveLabel: 'Save Copy',
  );
}

Future<void> _openPdfReview(
  BuildContext context, {
  required String title,
  String tool = 'Import PDF',
  String prefix = 'ImportedPDF',
  String saveLabel = 'Save PDF',
}) {
  return _openPdfPicker(
    context,
    title: title,
    actionLabel: 'Continue',
    onContinue: (paths) async {
      final bytes = await File(paths.first).readAsBytes();
      if (!context.mounted) {
        return const [];
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImportPdfScreen(
            fileName: p.basename(paths.first),
            bytes: bytes,
            title: title,
            tool: tool,
            prefix: prefix,
            saveLabel: saveLabel,
          ),
        ),
      );
      return const [];
    },
  );
}

Future<void> openMergePdf(BuildContext context) {
  return _openPdfPicker(
    context,
    title: 'Merge PDF',
    actionLabel: 'Merge',
    allowMultiple: true,
    minFiles: 2,
    onContinue: (paths) async {
      final files = <Uint8List>[];
      for (final path in paths) {
        files.add(await File(path).readAsBytes());
      }
      final merged = PdfService.merge(files);
      final job = await PdfLibrary.instance.save(
        bytes: merged,
        tool: 'Merge PDF',
        prefix: 'MergedPDF',
      );
      return [job];
    },
  );
}

Future<void> openSplitPdf(BuildContext context) {
  return _openPdfPicker(
    context,
    title: 'Split PDF',
    actionLabel: 'Split',
    onContinue: (paths) async {
      final bytes = await File(paths.first).readAsBytes();
      final parts = PdfService.split(bytes);
      final jobs = <PdfJob>[];
      for (var i = 0; i < parts.length; i++) {
        jobs.add(
          await PdfLibrary.instance.save(
            bytes: parts[i],
            tool: 'Split PDF',
            prefix: 'SplitPDF_page_${i + 1}',
          ),
        );
      }
      return jobs;
    },
  );
}

Future<void> openLockPdf(BuildContext context) {
  return _openPdfPicker(
    context,
    title: 'Lock PDF',
    actionLabel: 'Continue',
    onContinue: (paths) async {
      final password = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => const _PasswordScreen(
            title: 'Lock PDF',
            confirm: true,
            actionLabel: 'Lock PDF',
          ),
        ),
      );
      if (password == null) {
        return const [];
      }
      final bytes = await File(paths.first).readAsBytes();
      final locked = PdfService.lock(bytes, password);
      final job = await PdfLibrary.instance.save(
        bytes: locked,
        tool: 'Lock PDF',
        prefix: 'LockedPDF',
      );
      return [job];
    },
  );
}

Future<void> openUnlockPdf(BuildContext context) {
  return _openPdfPicker(
    context,
    title: 'Unlock PDF',
    actionLabel: 'Continue',
    onContinue: (paths) async {
      final password = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => const _PasswordScreen(
            title: 'Unlock PDF',
            confirm: false,
            actionLabel: 'Unlock PDF',
          ),
        ),
      );
      if (password == null) {
        return const [];
      }
      final bytes = await File(paths.first).readAsBytes();
      final unlocked = PdfService.unlock(bytes, password);
      final job = await PdfLibrary.instance.save(
        bytes: unlocked,
        tool: 'Unlock PDF',
        prefix: 'UnlockedPDF',
      );
      return [job];
    },
  );
}

Future<void> openReorderPdf(BuildContext context) {
  return _openPdfPicker(
    context,
    title: 'Reorder PDF',
    actionLabel: 'Continue',
    onContinue: (paths) async {
      final bytes = await File(paths.first).readAsBytes();
      if (!context.mounted) {
        return const [];
      }
      final order = await Navigator.of(context).push<List<int>>(
        MaterialPageRoute(
          builder: (_) => _PageOrderScreen(
            title: 'Reorder PDF',
            pageCount: PdfService.pageCount(bytes),
            removing: false,
          ),
        ),
      );
      if (order == null || order.isEmpty) {
        return const [];
      }
      final reordered = PdfService.pages(bytes, order);
      final job = await PdfLibrary.instance.save(
        bytes: reordered,
        tool: 'Reorder PDF',
        prefix: 'ReorderedPDF',
      );
      return [job];
    },
  );
}

Future<void> openRemovePages(BuildContext context) {
  return _openPdfPicker(
    context,
    title: 'Remove Pages',
    actionLabel: 'Continue',
    onContinue: (paths) async {
      final bytes = await File(paths.first).readAsBytes();
      if (!context.mounted) {
        return const [];
      }
      final kept = await Navigator.of(context).push<List<int>>(
        MaterialPageRoute(
          builder: (_) => _PageOrderScreen(
            title: 'Remove Pages',
            pageCount: PdfService.pageCount(bytes),
            removing: true,
          ),
        ),
      );
      if (kept == null || kept.isEmpty) {
        return const [];
      }
      final result = PdfService.pages(bytes, kept);
      final job = await PdfLibrary.instance.save(
        bytes: result,
        tool: 'Remove Pages',
        prefix: 'TrimmedPDF',
      );
      return [job];
    },
  );
}

Future<void> _openPdfPicker(
  BuildContext context, {
  required String title,
  required String actionLabel,
  required Future<List<PdfJob>> Function(List<String> paths) onContinue,
  bool allowMultiple = false,
  int minFiles = 1,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _PdfPickScreen(
        title: title,
        actionLabel: actionLabel,
        allowMultiple: allowMultiple,
        minFiles: minFiles,
        onContinue: onContinue,
      ),
    ),
  );
}

class _PdfPickScreen extends StatefulWidget {
  const _PdfPickScreen({
    required this.title,
    required this.actionLabel,
    required this.allowMultiple,
    required this.minFiles,
    required this.onContinue,
  });

  final String title;
  final String actionLabel;
  final bool allowMultiple;
  final int minFiles;
  final Future<List<PdfJob>> Function(List<String> paths) onContinue;

  @override
  State<_PdfPickScreen> createState() => _PdfPickScreenState();
}

class _PdfPickScreenState extends State<_PdfPickScreen> {
  final List<String> _files = [];
  bool _busy = false;

  Future<void> _addFiles() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final picked = widget.allowMultiple
          ? await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: const ['pdf'],
            )
          : [
              ?await FilePicker.pickFile(
                type: FileType.custom,
                allowedExtensions: const ['pdf'],
              ),
            ];
      if (!mounted || picked.isEmpty) {
        return;
      }
      final paths = <String>[];
      for (final file in picked) {
        final path = file.path;
        if (path != null) {
          paths.add(path);
          continue;
        }
        final bytes = await file.readAsBytes();
        final temp = File(
          p.join(
            Directory.systemTemp.path,
            '${DateTime.now().microsecondsSinceEpoch}_${file.name}',
          ),
        );
        await temp.writeAsBytes(bytes, flush: true);
        paths.add(temp.path);
      }
      if (!mounted) {
        return;
      }
      if (paths.isEmpty) {
        _showMessage('Could not read the selected file.');
        return;
      }
      setState(() {
        if (widget.allowMultiple) {
          for (final path in paths) {
            if (!_files.contains(path)) {
              _files.add(path);
            }
          }
        } else {
          _files
            ..clear()
            ..add(paths.first);
        }
      });
    } catch (error) {
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _continue() async {
    if (_busy || _files.length < widget.minFiles) {
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      setState(() => _busy = true);
      try {
        final jobs = await widget.onContinue(List<String>.from(_files));
        if (!mounted || jobs.isEmpty) {
          return;
        }
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => _ResultScreen(jobs: jobs)),
        );
      } catch (error) {
        _showMessage(_cleanError(error));
      } finally {
        if (mounted) {
          setState(() => _busy = false);
        }
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    AppPopup.notice(
      context,
      title: 'Please check',
      message: message,
      kind: AppNotice.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _files.length >= widget.minFiles;
    return _ToolScaffold(
      title: widget.title,
      busy: _busy,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          AddFilesDropZone(
            label: _files.isEmpty
                ? (widget.allowMultiple ? 'Add PDFs' : 'Add PDF')
                : 'Add more files',
            hint: widget.allowMultiple ? 'Choose one or more files' : 'Choose a PDF from your phone',
            onTap: _busy ? null : _addFiles,
          ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Files', style: preSectionStyle),
            const SizedBox(height: 12),
            for (var i = 0; i < _files.length; i++) ...[
              UploadedFileCard(
                path: _files[i],
                onDelete: _busy ? null : () => setState(() => _files.removeAt(i)),
              ),
              if (i != _files.length - 1) const SizedBox(height: 10),
            ],
          ],
        ],
      ),
      bottom: PreScreenRedButton(
        label: widget.actionLabel,
        onPressed: ready && !_busy ? _continue : null,
        loading: _busy && ready,
        loadingLabel: 'Please wait…',
      ),
    );
  }
}

class _ScanPagesScreen extends StatefulWidget {
  const _ScanPagesScreen({required this.idCard});

  final bool idCard;

  @override
  State<_ScanPagesScreen> createState() => _ScanPagesScreenState();
}

class _ScanPagesScreenState extends State<_ScanPagesScreen> {
  final List<String> _images = [];
  final _picker = ImagePicker();
  bool _busy = false;
  bool _askedBack = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (widget.idCard) {
        final scanned = await DocumentScanner.scan(format: DocScanFormat.jpeg);
        if (!mounted || scanned == null || scanned.isEmpty) {
          return;
        }
        setState(() => _images.addAll(scanned));
      } else {
        final image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
          requestFullMetadata: false,
        );
        if (!mounted || image == null) {
          return;
        }
        setState(() => _images.add(image.path));
      }
      if (widget.idCard && _images.length == 1 && !_askedBack) {
        _askedBack = true;
        final scanBack = await AppPopup.confirm(
          context,
          title: 'Scan the back?',
          message: 'You can add the back of the ID card, or skip it.',
          confirmLabel: 'Scan back',
          cancelLabel: 'Skip',
        );
        if (scanBack == true && mounted) {
          setState(() => _busy = false);
          await _capture();
        }
      }
    } catch (error) {
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _createPdf() async {
    if (_busy || _images.isEmpty) {
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      setState(() => _busy = true);
      try {
        final bytes = await PdfService.imagesToPdf(_images);
        final job = await PdfLibrary.instance.save(
          bytes: bytes,
          tool: widget.idCard ? 'Scan ID Card' : 'Smart Scan',
          prefix: widget.idCard ? 'IDScanPDF' : 'ScanPDF',
        );
        if (!mounted) {
          return;
        }
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => _ResultScreen(jobs: [job])),
        );
      } catch (error) {
        _showMessage(_cleanError(error));
      } finally {
        if (mounted) {
          setState(() => _busy = false);
        }
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    AppPopup.notice(
      context,
      title: 'Please check',
      message: message,
      kind: AppNotice.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ToolScaffold(
      title: widget.idCard ? 'Scan ID Card' : 'Smart Scan',
      busy: _busy,
      body: _images.isEmpty
          ? const Center(
              child: Text(
                'Capture a page to start.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(_images[index]), fit: BoxFit.cover),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() => _images.removeAt(index)),
                            icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottom: Row(
        children: [
          Expanded(
            child: _PrimaryButton(
              label: 'Add page',
              filled: false,
              enabled: !_busy,
              onPressed: _capture,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _PrimaryButton(
              label: 'Create PDF',
              enabled: _images.isNotEmpty && !_busy,
              onPressed: _createPdf,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordScreen extends StatefulWidget {
  const _PasswordScreen({
    required this.title,
    required this.confirm,
    required this.actionLabel,
  });

  final String title;
  final bool confirm;
  final String actionLabel;

  @override
  State<_PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<_PasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _password.text.trim();
    if (password.isEmpty) {
      _show('Enter a password.');
      return;
    }
    if (widget.confirm && password != _confirm.text.trim()) {
      _show('Passwords do not match.');
      return;
    }
    Navigator.of(context).pop(password);
  }

  void _show(String message) {
    AppPopup.notice(
      context,
      title: 'Please check',
      message: message,
      kind: AppNotice.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ToolScaffold(
      title: widget.title,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Text(
            widget.confirm
                ? 'Choose a password. You will need it to open this PDF.'
                : 'Enter the password that was used to lock this PDF.',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          PreScreenOptionCard(
            child: Column(
              children: [
                PreScreenField(
                  label: 'Password',
                  controller: _password,
                  hint: 'Enter password',
                  obscure: _hide,
                  onChanged: (_) => setState(() {}),
                  suffix: IconButton(
                    onPressed: () => setState(() => _hide = !_hide),
                    icon: Icon(
                      _hide ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                if (widget.confirm) ...[
                  const SizedBox(height: 14),
                  PreScreenField(
                    label: 'Confirm password',
                    controller: _confirm,
                    hint: 'Type it again',
                    obscure: _hide,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottom: PreScreenRedButton(label: widget.actionLabel, onPressed: _submit),
    );
  }
}

class _PageOrderScreen extends StatefulWidget {
  const _PageOrderScreen({
    required this.title,
    required this.pageCount,
    required this.removing,
  });

  final String title;
  final int pageCount;
  final bool removing;

  @override
  State<_PageOrderScreen> createState() => _PageOrderScreenState();
}

class _PageOrderScreenState extends State<_PageOrderScreen> {
  late final List<int> _order = [for (var i = 0; i < widget.pageCount; i++) i];
  late final Set<int> _removed = {};

  void _save() {
    if (widget.removing) {
      final kept = [
        for (final index in _order)
          if (!_removed.contains(index)) index,
      ];
      if (kept.isEmpty) {
        _show('Keep at least one page.');
        return;
      }
      if (kept.length == widget.pageCount) {
        _show('Select at least one page to remove.');
        return;
      }
      Navigator.of(context).pop(kept);
      return;
    }
    Navigator.of(context).pop(List<int>.from(_order));
  }

  void _show(String message) {
    AppPopup.notice(
      context,
      title: 'Please check',
      message: message,
      kind: AppNotice.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ToolScaffold(
      title: widget.title,
      body: widget.removing ? _removeList() : _reorderList(),
      bottom: PreScreenRedButton(
        label: widget.removing ? 'Remove pages' : 'Save',
        onPressed: widget.pageCount == 0 ? null : _save,
      ),
    );
  }

  Widget _reorderList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      itemCount: _order.length,
      onReorderItem: (oldIndex, newIndex) {
        setState(() {
          final page = _order.removeAt(oldIndex);
          _order.insert(newIndex, page);
        });
      },
      itemBuilder: (context, index) {
        final page = _order[index];
        return Padding(
          key: ValueKey(page),
          padding: const EdgeInsets.only(bottom: 10),
          child: _PageRow(
            label: 'Page ${page + 1}',
            trailing: const Icon(Icons.drag_handle_rounded, color: Color(0xFF94A3B8)),
          ),
        );
      },
    );
  }

  Widget _removeList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      itemCount: _order.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final page = _order[index];
        final selected = _removed.contains(page);
        return _PageRow(
          label: 'Page ${page + 1}',
          trailing: Checkbox(
            value: selected,
            activeColor: _blue,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _removed.add(page);
                } else {
                  _removed.remove(page);
                }
              });
            },
          ),
        );
      },
    );
  }
}

class _ResultScreen extends StatelessWidget {
  const _ResultScreen({required this.jobs});

  final List<PdfJob> jobs;

  Future<void> _print() async {
    await AdService.instance.showInterstitialThen(() async {
      final bytes = await PdfLibrary.instance.read(jobs.first);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final many = jobs.length > 1;
    return _ToolScaffold(
      title: 'Ready',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        children: [
          const Center(
            child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
              child: SizedBox(
                width: 84,
                height: 84,
                child: Icon(Icons.check_rounded, color: _blue, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            many ? '${jobs.length} PDFs saved' : 'PDF saved',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You can print it now, or open it later from History.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          for (final job in jobs) ...[
            _FileCard(name: job.title, onDelete: null),
            const SizedBox(height: 10),
          ],
        ],
      ),
      bottom: Row(
        children: [
          Expanded(
            child: PreScreenOutlineButton(
              label: 'Done',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PreScreenRedButton(label: 'Print', onPressed: _print),
          ),
        ],
      ),
    );
  }
}

class _ToolScaffold extends StatelessWidget {
  const _ToolScaffold({
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
      backgroundColor: _pageColor,
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

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final active = enabled && onPressed != null;
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: filled
          ? FilledButton(
              onPressed: active ? onPressed : null,
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                disabledBackgroundColor: const Color(0xFFD6E4F8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: active ? onPressed : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: _blue,
                side: const BorderSide(color: _blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(label),
            ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.name, required this.onDelete});

  final String name;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }
}

class _PageRow extends StatelessWidget {
  const _PageRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(preCardRadius),
        border: Border.all(color: const Color(0xFFEEECEC), width: 0.6),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: prePrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

String _cleanError(Object error) {
  return error
      .toString()
      .replaceFirst(RegExp(r'^[A-Za-z0-9_]*Exception: '), '');
}
