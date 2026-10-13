import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../ads/ad_service.dart';
import '../ads/banner_ad_widget.dart';
import '../app_feedback.dart';
import '../pdf/pdf_library.dart';

const _primary = Color(0xFF3B82F6);

class PrintableEditorScreen extends StatefulWidget {
  const PrintableEditorScreen({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  State<PrintableEditorScreen> createState() => _PrintableEditorScreenState();
}

class _PrintableEditorScreenState extends State<PrintableEditorScreen> {
  double _brightness = 0;
  double _saturation = 1;
  int _rotationQuarterTurns = 0;
  double? _cropAspectRatio;
  String _cropMode = 'FREE';
  Rect _cropRect = const Rect.fromLTWH(0.1, 0.12, 0.8, 0.76);
  bool _hideOverlayForExport = false;
  final _previewKey = GlobalKey();

  final List<_EditState> _history = [];
  int _historyIndex = -1;
  _EditTool _activeTool = _EditTool.none;

  @override
  void initState() {
    super.initState();
    _pushHistory();
  }

  void _pushHistory() {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(
      _EditState(
        brightness: _brightness,
        saturation: _saturation,
        rotationQuarterTurns: _rotationQuarterTurns,
        cropAspectRatio: _cropAspectRatio,
        cropMode: _cropMode,
        cropRect: _cropRect,
      ),
    );
    _historyIndex = _history.length - 1;
  }

  void _restoreFrom(_EditState state) {
    setState(() {
      _brightness = state.brightness;
      _saturation = state.saturation;
      _rotationQuarterTurns = state.rotationQuarterTurns;
      _cropAspectRatio = state.cropAspectRatio;
      _cropMode = state.cropMode;
      _cropRect = state.cropRect;
    });
  }

  void _undo() {
    if (_historyIndex <= 0) {
      return;
    }
    _historyIndex -= 1;
    _restoreFrom(_history[_historyIndex]);
  }

  void _redo() {
    if (_historyIndex >= _history.length - 1) {
      return;
    }
    _historyIndex += 1;
    _restoreFrom(_history[_historyIndex]);
  }

  void _rotate() {
    setState(() => _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4);
    _pushHistory();
  }

  void _setCropRatio(String mode, double? ratio) {
    setState(() {
      _cropMode = mode;
      _cropAspectRatio = ratio;
    });
    _pushHistory();
  }

  Future<void> _openEditedPreview() async {
    final pngBytes = await _renderEditedPng();
    if (!mounted) {
      return;
    }
    if (pngBytes == null) {
      await AppPopup.notice(
        context,
        title: 'Could not edit',
        message: 'This printable could not be prepared.',
        kind: AppNotice.error,
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PrintableEditedPreviewScreen(
          imageBytes: pngBytes,
          onSave: () => _saveImage(pngBytes),
          onPrint: () => _printImage(pngBytes),
        ),
      ),
    );
  }

  Future<bool> _saveImage(Uint8List bytes) async {
    try {
      await PdfLibrary.instance.save(
        bytes: bytes,
        tool: 'Printables',
        prefix: 'Printable',
        extension: 'png',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _printImage(Uint8List bytes) async {
    if (!mounted) {
      return;
    }
    AppLoader.show(context, message: 'Preparing print…');
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (_) => pw.Center(
            child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
          ),
        ),
      );
      final pdfBytes = await pdf.save();
      await PdfLibrary.instance.save(bytes: pdfBytes, tool: 'Printables', prefix: 'Printable');
      AppLoader.hide();
      if (!mounted) {
        return;
      }
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } catch (error) {
      AppLoader.hide();
      if (!mounted) {
        return;
      }
      await AppPopup.notice(
        context,
        title: 'Could not print',
        message: error.toString().replaceFirst('Exception: ', ''),
        kind: AppNotice.error,
      );
    }
  }

  Future<Uint8List?> _renderEditedPng() async {
    if (!mounted) {
      return null;
    }
    setState(() => _hideOverlayForExport = true);
    await Future<void>.delayed(const Duration(milliseconds: 16));
    final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      if (mounted) {
        setState(() => _hideOverlayForExport = false);
      }
      return null;
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (mounted) {
      setState(() => _hideOverlayForExport = false);
    }
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(tooltip: 'Undo', onPressed: _undo, icon: const Icon(Icons.undo_rounded)),
          IconButton(tooltip: 'Redo', onPressed: _redo, icon: const Icon(Icons.redo_rounded)),
          IconButton(
            tooltip: 'Apply',
            onPressed: _openEditedPreview,
            icon: const Icon(Icons.check_circle, color: _primary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const BannerAdWidget(
            margin: EdgeInsets.only(top: 10, bottom: 6, left: 12, right: 12),
          ),
          Expanded(child: Center(child: _buildPreview())),
          _buildToolPanel(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    Widget image = Image.network(
      widget.imageUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: _primary),
          ),
        );
      },
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.broken_image, color: Colors.black38, size: 48),
      ),
    );
    image = ColorFiltered(colorFilter: ColorFilter.matrix(_colorMatrix()), child: image);
    image = Transform.rotate(angle: _rotationQuarterTurns * math.pi / 2, child: image);

    if (_activeTool == _EditTool.crop && _cropMode == 'FREE') {
      image = _hideOverlayForExport
          ? _applyFreeCrop(image)
          : _FreeCropOverlay(
              rect: _cropRect,
              onRectChanged: (rect) => _cropRect = rect,
              child: image,
            );
    } else if (_cropAspectRatio != null) {
      image = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: _cropAspectRatio!,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(width: 360, height: 360 / _cropAspectRatio!, child: image),
          ),
        ),
      );
    } else {
      image = ClipRRect(borderRadius: BorderRadius.circular(16), child: image);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: RepaintBoundary(key: _previewKey, child: image),
    );
  }

  Widget _applyFreeCrop(Widget image) {
    final rect = _cropRect;
    final alignment = Alignment((rect.left + rect.width / 2) * 2 - 1, (rect.top + rect.height / 2) * 2 - 1);
    return ClipRect(
      child: Align(
        alignment: alignment,
        widthFactor: rect.width,
        heightFactor: rect.height,
        child: image,
      ),
    );
  }

  List<double> _colorMatrix() {
    final saturation = _saturation;
    final inverse = 1 - saturation;
    final red = 0.213 * inverse;
    final green = 0.715 * inverse;
    final blue = 0.072 * inverse;
    final shift = _brightness * 255;
    return [
      red + saturation, green, blue, 0, shift,
      red, green + saturation, blue, 0, shift,
      red, green, blue + saturation, 0, shift,
      0, 0, 0, 1, 0,
    ];
  }

  Widget _buildToolPanel() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_activeTool == _EditTool.brightness)
              _SliderRow(
                value: _brightness,
                min: -1,
                max: 1,
                label: 'Brightness',
                onChanged: (value) => setState(() => _brightness = value),
                onChangeEnd: (_) => _pushHistory(),
              )
            else if (_activeTool == _EditTool.saturation)
              _SliderRow(
                value: _saturation,
                min: 0,
                max: 2,
                label: 'Saturation',
                onChanged: (value) => setState(() => _saturation = value),
                onChangeEnd: (_) => _pushHistory(),
              )
            else if (_activeTool == _EditTool.crop)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _CropPicker(selectedMode: _cropMode, onSelect: _setCropRatio),
              )
            else
              const SizedBox(height: 8),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ToolButton(
                  icon: Icons.brightness_6_outlined,
                  label: 'Brightness',
                  selected: _activeTool == _EditTool.brightness,
                  onTap: () => setState(() => _activeTool = _EditTool.brightness),
                ),
                _ToolButton(
                  icon: Icons.crop,
                  label: 'Crop',
                  selected: _activeTool == _EditTool.crop,
                  onTap: () => setState(() => _activeTool = _EditTool.crop),
                ),
                _ToolButton(
                  icon: Icons.water_drop_outlined,
                  label: 'Saturation',
                  selected: _activeTool == _EditTool.saturation,
                  onTap: () => setState(() => _activeTool = _EditTool.saturation),
                ),
                _ToolButton(
                  icon: Icons.rotate_right,
                  label: 'Rotate',
                  selected: _activeTool == _EditTool.rotate,
                  onTap: () {
                    setState(() => _activeTool = _EditTool.rotate);
                    _rotate();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _primary : Colors.black87;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final double min;
  final double max;
  final String label;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          activeColor: _primary,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}

class _CropPicker extends StatelessWidget {
  const _CropPicker({required this.selectedMode, required this.onSelect});

  final String selectedMode;
  final void Function(String mode, double? ratio) onSelect;

  static const _options = <(String, double?)>[
    ('FREE', null),
    ('ORIGINAL', null),
    ('SQUARE', 1),
    ('3:4', 3 / 4),
    ('4:3', 4 / 3),
    ('9:16', 9 / 16),
    ('16:9', 16 / 9),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final option = _options[index];
          final selected = selectedMode == option.$1;
          return GestureDetector(
            onTap: () => onSelect(option.$1, option.$2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _primary : const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  option.$1,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FreeCropOverlay extends StatefulWidget {
  const _FreeCropOverlay({required this.child, required this.rect, required this.onRectChanged});

  final Widget child;
  final Rect rect;
  final ValueChanged<Rect> onRectChanged;

  @override
  State<_FreeCropOverlay> createState() => _FreeCropOverlayState();
}

class _FreeCropOverlayState extends State<_FreeCropOverlay> {
  late Rect _rect = widget.rect;
  Rect _startRect = Rect.zero;
  Offset _startFocal = Offset.zero;

  @override
  void didUpdateWidget(covariant _FreeCropOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rect != widget.rect) {
      _rect = widget.rect;
    }
  }

  void _updateRect(Rect rect) {
    final clamped = Rect.fromLTWH(
      rect.left.clamp(0.0, 1.0 - rect.width),
      rect.top.clamp(0.0, 1.0 - rect.height),
      rect.width.clamp(0.1, 1.0),
      rect.height.clamp(0.1, 1.0),
    );
    setState(() => _rect = clamped);
    widget.onRectChanged(clamped);
  }

  void _updateFromCorner(_Handle handle, Offset delta, double width, double height) {
    final dx = delta.dx / width;
    final dy = delta.dy / height;
    final next = switch (handle) {
      _Handle.topLeft => Rect.fromLTRB(_rect.left + dx, _rect.top + dy, _rect.right, _rect.bottom),
      _Handle.topRight => Rect.fromLTRB(_rect.left, _rect.top + dy, _rect.right + dx, _rect.bottom),
      _Handle.bottomLeft => Rect.fromLTRB(_rect.left + dx, _rect.top, _rect.right, _rect.bottom + dy),
      _Handle.bottomRight => Rect.fromLTRB(_rect.left, _rect.top, _rect.right + dx, _rect.bottom + dy),
    };
    _updateRect(next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final left = _rect.left * width;
        final top = _rect.top * height;
        final boxWidth = _rect.width * width;
        final boxHeight = _rect.height * height;

        return GestureDetector(
          onScaleStart: (details) {
            _startRect = _rect;
            _startFocal = details.localFocalPoint;
          },
          onScaleUpdate: (details) {
            final dx = details.focalPointDelta.dx / width;
            final dy = details.focalPointDelta.dy / height;
            if (details.pointerCount >= 2) {
              final nextWidth = (_startRect.width * details.scale).clamp(0.1, 1.0);
              final nextHeight = (_startRect.height * details.scale).clamp(0.1, 1.0);
              final focal = Offset(_startFocal.dx / width, _startFocal.dy / height);
              final center = Offset(_startRect.left + _startRect.width / 2, _startRect.top + _startRect.height / 2);
              _updateRect(
                Rect.fromCenter(center: center + (focal - center), width: nextWidth, height: nextHeight),
              );
            } else {
              _updateRect(Rect.fromLTWH(_rect.left + dx, _rect.top + dy, _rect.width, _rect.height));
            }
          },
          child: Stack(
            children: [
              Positioned.fill(child: widget.child),
              Positioned(
                left: left,
                top: top,
                width: boxWidth,
                height: boxHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              _CornerHandle(left: left - 8, top: top - 8, onDrag: (delta) => _updateFromCorner(_Handle.topLeft, delta, width, height)),
              _CornerHandle(left: left + boxWidth - 8, top: top - 8, onDrag: (delta) => _updateFromCorner(_Handle.topRight, delta, width, height)),
              _CornerHandle(left: left - 8, top: top + boxHeight - 8, onDrag: (delta) => _updateFromCorner(_Handle.bottomLeft, delta, width, height)),
              _CornerHandle(left: left + boxWidth - 8, top: top + boxHeight - 8, onDrag: (delta) => _updateFromCorner(_Handle.bottomRight, delta, width, height)),
            ],
          ),
        );
      },
    );
  }
}

enum _Handle { topLeft, topRight, bottomLeft, bottomRight }

class _CornerHandle extends StatelessWidget {
  const _CornerHandle({required this.left, required this.top, required this.onDrag});

  final double left;
  final double top;
  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          height: 16,
          width: 16,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
        ),
      ),
    );
  }
}

enum _EditTool { none, brightness, saturation, crop, rotate }

class _EditState {
  _EditState({
    required this.brightness,
    required this.saturation,
    required this.rotationQuarterTurns,
    required this.cropAspectRatio,
    required this.cropMode,
    required this.cropRect,
  });

  final double brightness;
  final double saturation;
  final int rotationQuarterTurns;
  final double? cropAspectRatio;
  final String cropMode;
  final Rect cropRect;
}

class _PrintableEditedPreviewScreen extends StatefulWidget {
  const _PrintableEditedPreviewScreen({
    required this.imageBytes,
    required this.onSave,
    required this.onPrint,
  });

  final Uint8List imageBytes;
  final Future<bool> Function() onSave;
  final Future<void> Function() onPrint;

  @override
  State<_PrintableEditedPreviewScreen> createState() => _PrintableEditedPreviewScreenState();
}

class _PrintableEditedPreviewScreenState extends State<_PrintableEditedPreviewScreen> {
  bool _saving = false;
  bool _printing = false;

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      setState(() => _saving = true);
      final ok = await widget.onSave();
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      await AppPopup.notice(
        context,
        title: ok ? 'Saved' : 'Could not save',
        message: ok ? 'Printable saved. You can find it in History.' : 'This printable could not be saved.',
        kind: ok ? AppNotice.success : AppNotice.error,
      );
    });
  }

  Future<void> _print() async {
    if (_printing) {
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      setState(() => _printing = true);
      await widget.onPrint();
      if (!mounted) {
        return;
      }
      setState(() => _printing = false);
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Preview', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving || _printing ? null : _save,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _saving ? 'Saving...' : 'Save',
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _printing || _saving ? null : _print,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _printing ? 'Printing...' : 'Print',
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                      ),
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
