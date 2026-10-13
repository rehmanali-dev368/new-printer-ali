import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../ads/ad_service.dart';
import '../app_feedback.dart';
import '../pdf/pdf_library.dart';

class LabelShapeOption {
  const LabelShapeOption({
    required this.title,
    required this.type,
    required this.iconBuilder,
  });

  final String title;
  final LabelShapeType type;
  final Widget Function(bool selected) iconBuilder;
}

enum LabelShapeType { rectangle, circle, ellipse, square }

class LabelTemplate {
  const LabelTemplate({
    required this.title,
    required this.subtitle,
    required this.shape,
    required this.badge,
    required this.rows,
    required this.columns,
    required this.previewBuilder,
  });

  final String title;
  final String subtitle;
  final LabelShapeType shape;
  final bool badge;
  final int rows;
  final int columns;
  final Widget Function(bool selected, LabelShapeType shape) previewBuilder;
}

class LabelShapesScreen extends StatefulWidget {
  const LabelShapesScreen({super.key});

  @override
  State<LabelShapesScreen> createState() => _LabelShapesScreenState();
}

class _LabelShapesScreenState extends State<LabelShapesScreen> {
  final List<LabelShapeOption> _shapes = const [
    LabelShapeOption(
      title: 'Rectangle',
      type: LabelShapeType.rectangle,
      iconBuilder: _RectangleShapePreview.new,
    ),
    LabelShapeOption(
      title: 'Circle',
      type: LabelShapeType.circle,
      iconBuilder: _CircleShapePreview.new,
    ),
    LabelShapeOption(
      title: 'Ellipse',
      type: LabelShapeType.ellipse,
      iconBuilder: _EllipseShapePreview.new,
    ),
    LabelShapeOption(
      title: 'Square',
      type: LabelShapeType.square,
      iconBuilder: _SquareShapePreview.new,
    ),
  ];

  LabelShapeType _selected = LabelShapeType.rectangle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Label Shapes'), centerTitle: false),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GridView.builder(
                itemCount: _shapes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final option = _shapes[index];
                  final selected = option.type == _selected;
                  return _SelectableCard(
                    selected: selected,
                    onTap: () => setState(() => _selected = option.type),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        option.iconBuilder(selected),
                        const SizedBox(height: 12),
                        Text(
                          option.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          _BottomPrimaryButton(
            label: 'Next',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LabelTemplatesScreen(shape: _selected),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class LabelTemplatesScreen extends StatefulWidget {
  const LabelTemplatesScreen({super.key, required this.shape});

  final LabelShapeType shape;

  @override
  State<LabelTemplatesScreen> createState() => _LabelTemplatesScreenState();
}

class _LabelTemplatesScreenState extends State<LabelTemplatesScreen> {
  late final List<LabelTemplate> _templates;
  late LabelTemplate _selected;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _templates = _buildTemplates(widget.shape);
    _selected = _templates.first;
  }

  @override
  Widget build(BuildContext context) {
    final shapeTitle = _shapeTitle(widget.shape);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Labels'), centerTitle: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$shapeTitle Label Templates',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                itemCount: _templates.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.86,
                ),
                itemBuilder: (context, index) {
                  final template = _templates[index];
                  final selected = template == _selected;
                  return _SelectableCard(
                    selected: selected,
                    onTap: () => setState(() => _selected = template),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            template.previewBuilder(selected, widget.shape),
                            if (template.badge)
                              const Positioned(
                                top: 6,
                                right: 6,
                                child: _ProBadge(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          template.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          template.subtitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          _BottomPrimaryButton(label: 'Next', onTap: _showAddImageSheet),
        ],
      ),
    );
  }

  void _showAddImageSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add Image',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose an option to add an image.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.photo_library_outlined,
                      label: 'Open Gallery',
                      onTap: () async {
                        Navigator.pop(context);
                        final image = await _picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (!mounted || image == null) return;
                        _openPreview(image);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.camera_alt_outlined,
                      label: 'Open Camera',
                      onTap: () async {
                        Navigator.pop(context);
                        final image = await _picker.pickImage(
                          source: ImageSource.camera,
                        );
                        if (!mounted || image == null) return;
                        _openPreview(image);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPreview(XFile image) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LabelPreviewScreen(
          shape: widget.shape,
          template: _selected,
          image: File(image.path),
        ),
      ),
    );
  }
}

class LabelPreviewScreen extends StatefulWidget {
  const LabelPreviewScreen({
    super.key,
    required this.shape,
    required this.template,
    required this.image,
  });

  final LabelShapeType shape;
  final LabelTemplate template;
  final File image;

  @override
  State<LabelPreviewScreen> createState() => _LabelPreviewScreenState();
}

class _LabelPreviewScreenState extends State<LabelPreviewScreen> {
  bool _printing = false;

  Future<void> _printLabels() async {
    if (_printing) return;
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      setState(() => _printing = true);
      AppLoader.show(context, message: 'Preparing labels…');
      try {
        final bytes = await widget.image.readAsBytes();
        final mem = pw.MemoryImage(bytes);
        final doc = pw.Document();
        const margin = 24.0;
        final pageFormat = PdfPageFormat.a4;
        doc.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: const pw.EdgeInsets.all(margin),
            build: (_) => _PdfLabelGrid(
              memoryImage: mem,
              shape: widget.shape,
              rows: widget.template.rows,
              columns: widget.template.columns,
            ),
          ),
        );
        final saved = await doc.save();
        await PdfLibrary.instance.save(
          bytes: saved,
          tool: 'Labels',
          prefix: 'Label',
        );
        AppLoader.hide();
        await Printing.layoutPdf(onLayout: (_) async => saved);
      } catch (error) {
        AppLoader.hide();
        if (mounted) {
          await AppPopup.notice(
            context,
            title: 'Could not print',
            message: error.toString().replaceFirst('Exception: ', ''),
            kind: AppNotice.error,
          );
        }
      } finally {
        AppLoader.hide();
        if (mounted) {
          setState(() => _printing = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Preview'),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                Text(
                  '${widget.template.title} · ${_shapeTitle(widget.shape)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                _LabelPreviewCard(
                  image: widget.image,
                  shape: widget.shape,
                  template: widget.template,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomPrimaryButton(
        label: _printing ? 'Printing...' : 'Print',
        onTap: _printing ? null : _printLabels,
      ),
    );
  }
}

class LabelEditScreen extends StatefulWidget {
  const LabelEditScreen({
    super.key,
    required this.image,
    required this.template,
  });

  final File image;
  final LabelTemplate template;

  @override
  State<LabelEditScreen> createState() => _LabelEditScreenState();
}

class _LabelEditScreenState extends State<LabelEditScreen> {
  double _rotation = 0;
  double _scale = 1;

  void _reset() {
    setState(() {
      _rotation = 0;
      _scale = 1;
    });
  }

  void _rotate() {
    setState(() => _rotation += 90);
  }

  @override
  Widget build(BuildContext context) {
    final angle = _rotation * 3.141592653589793 / 180;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        actions: [
          IconButton(onPressed: _reset, icon: const Icon(Icons.undo_rounded)),
          IconButton(
            onPressed: _rotate,
            icon: const Icon(Icons.rotate_right_rounded),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.crop_rounded)),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: GestureDetector(
          onScaleUpdate: (details) {
            setState(() => _scale = details.scale.clamp(0.6, 2.2));
          },
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: _scale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(widget.image, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _BottomPrimaryButton(
        label: 'Print',
        onTap: () => Navigator.pop(context),
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.child,
    required this.onTap,
  });

  final bool selected;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF2F80ED) : Colors.black12,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

class _BottomPrimaryButton extends StatelessWidget {
  const _BottomPrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F80ED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 34, color: const Color(0xFF2F80ED)),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PdfLabelGrid extends pw.StatelessWidget {
  _PdfLabelGrid({
    required this.memoryImage,
    required this.shape,
    required this.rows,
    required this.columns,
  });

  final pw.MemoryImage memoryImage;
  final LabelShapeType shape;
  final int rows;
  final int columns;

  double get _cornerRadius {
    switch (shape) {
      case LabelShapeType.circle:
      case LabelShapeType.ellipse:
        return 0;
      case LabelShapeType.square:
        return 8;
      case LabelShapeType.rectangle:
        return 10;
    }
  }

  pw.Widget _clipImage() {
    final image = pw.Image(memoryImage, fit: pw.BoxFit.cover);
    switch (shape) {
      case LabelShapeType.circle:
      case LabelShapeType.ellipse:
        return pw.ClipOval(child: image);
      case LabelShapeType.square:
      case LabelShapeType.rectangle:
        return pw.ClipRRect(
          horizontalRadius: _cornerRadius,
          verticalRadius: _cornerRadius,
          child: image,
        );
    }
  }

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: List.generate(rows, (row) {
        return pw.Expanded(
          child: pw.Row(
            children: List.generate(columns, (col) {
              return pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Center(
                    child: pw.AspectRatio(
                      aspectRatio: _labelAspectRatio(shape),
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.grey400,
                            width: 0.8,
                          ),
                          borderRadius: shape == LabelShapeType.circle
                              ? null
                              : pw.BorderRadius.circular(
                                  shape == LabelShapeType.ellipse
                                      ? 999
                                      : _cornerRadius,
                                ),
                          shape: shape == LabelShapeType.circle
                              ? pw.BoxShape.circle
                              : pw.BoxShape.rectangle,
                        ),
                        child: _clipImage(),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      width: 22,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFFC700), Color(0xFFFF8A00)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.diamond, color: Colors.white, size: 12),
      ),
    );
  }
}

double _labelAspectRatio(LabelShapeType shape) {
  switch (shape) {
    case LabelShapeType.circle:
    case LabelShapeType.square:
      return 1;
    case LabelShapeType.ellipse:
      return 1.55;
    case LabelShapeType.rectangle:
      return 1.7;
  }
}

class _LabelPreviewCard extends StatelessWidget {
  const _LabelPreviewCard({
    required this.image,
    required this.shape,
    required this.template,
  });

  final File image;
  final LabelShapeType shape;
  final LabelTemplate template;

  static const _gap = 8.0;
  static const _pad = 14.0;

  @override
  Widget build(BuildContext context) {
    final tint = const Color(0xFF2F80ED);
    final cols = template.columns;
    final rows = template.rows;
    final aspect = _labelAspectRatio(shape);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        // A4-ish sheet proportions for a professional print preview.
        final sheetHeight = (maxWidth * 1.35).clamp(280.0, 520.0);
        final innerW = maxWidth - _pad * 2;
        final innerH = sheetHeight - _pad * 2;
        final cellW = (innerW - _gap * (cols - 1)) / cols;
        final cellHFromWidth = cellW / aspect;
        final cellHFromHeight = (innerH - _gap * (rows - 1)) / rows;
        final cellH = cellHFromWidth <= cellHFromHeight
            ? cellHFromWidth
            : cellHFromHeight;
        final cellWFinal = cellH * aspect;
        final gridW = cellWFinal * cols + _gap * (cols - 1);
        final gridH = cellH * rows + _gap * (rows - 1);

        return Container(
          width: double.infinity,
          height: sheetHeight,
          padding: const EdgeInsets.all(_pad),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: SizedBox(
              width: gridW,
              height: gridH,
              child: Column(
                children: [
                  for (var r = 0; r < rows; r++) ...[
                    if (r > 0) const SizedBox(height: _gap),
                    Expanded(
                      child: Row(
                        children: [
                          for (var c = 0; c < cols; c++) ...[
                            if (c > 0) const SizedBox(width: _gap),
                            Expanded(
                              child: _LabelImageTile(
                                image: image,
                                shape: shape,
                                tint: tint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LabelImageTile extends StatelessWidget {
  const _LabelImageTile({
    required this.image,
    required this.shape,
    required this.tint,
  });

  final File image;
  final LabelShapeType shape;
  final Color tint;

  BorderRadius get _radius {
    switch (shape) {
      case LabelShapeType.square:
        return BorderRadius.circular(10);
      case LabelShapeType.rectangle:
        return BorderRadius.circular(12);
      case LabelShapeType.circle:
      case LabelShapeType.ellipse:
        return BorderRadius.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = Image.file(
      image,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)),
        ),
      ),
    );

    final Widget clipped;
    switch (shape) {
      case LabelShapeType.circle:
      case LabelShapeType.ellipse:
        clipped = ClipOval(child: imageWidget);
      case LabelShapeType.square:
      case LabelShapeType.rectangle:
        clipped = ClipRRect(borderRadius: _radius, child: imageWidget);
    }

    return AspectRatio(
      aspectRatio: _labelAspectRatio(shape),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: shape == LabelShapeType.circle
              ? BoxShape.circle
              : BoxShape.rectangle,
          borderRadius: shape == LabelShapeType.circle ? null : _radius,
          border: Border.all(color: tint.withValues(alpha: 0.28), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: clipped,
      ),
    );
  }
}

class _RectangleShapePreview extends StatelessWidget {
  const _RectangleShapePreview(this.selected);

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2F80ED) : Colors.black26;
    return SizedBox(
      height: 68,
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(2),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.6,
        children: List.generate(
          4,
          (index) => Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: selected ? 0.95 : 0.35),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleShapePreview extends StatelessWidget {
  const _CircleShapePreview(this.selected);

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2F80ED) : Colors.black26;
    return SizedBox(
      height: 68,
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(4),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
        children: List.generate(
          4,
          (index) => Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: selected ? 0.95 : 0.35),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _EllipseShapePreview extends StatelessWidget {
  const _EllipseShapePreview(this.selected);

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2F80ED) : Colors.black26;
    return SizedBox(
      height: 68,
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(2),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.5,
        children: List.generate(
          4,
          (index) => Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: selected ? 0.95 : 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareShapePreview extends StatelessWidget {
  const _SquareShapePreview(this.selected);

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2F80ED) : Colors.black26;
    return SizedBox(
      height: 68,
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(4),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
        children: List.generate(
          4,
          (index) => Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: selected ? 0.95 : 0.35),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

List<LabelTemplate> _buildTemplates(LabelShapeType shape) {
  final List<LabelTemplate> base = [
    LabelTemplate(
      title: '2 Per Sheet',
      subtitle: '1" x 1.5"',
      shape: shape,
      badge: false,
      rows: 2,
      columns: 1,
      previewBuilder: _TwoRectanglesPreview.new,
    ),
    LabelTemplate(
      title: '4 Per Sheet',
      subtitle: '1" x 2.5"',
      shape: shape,
      badge: false,
      rows: 2,
      columns: 2,
      previewBuilder: _FourRectanglesPreview.new,
    ),
    LabelTemplate(
      title: '6 Per Sheet',
      subtitle: '3.33" x 4"',
      shape: shape,
      badge: false,
      rows: 3,
      columns: 2,
      previewBuilder: _SixRectanglesPreview.new,
    ),
    LabelTemplate(
      title: '8 Per Sheet',
      subtitle: '2" x 3"',
      shape: shape,
      badge: false,
      rows: 4,
      columns: 2,
      previewBuilder: _EightRectanglesPreview.new,
    ),
    LabelTemplate(
      title: '15 Per Sheet',
      subtitle: '8.33" x 10"',
      shape: shape,
      badge: false,
      rows: 5,
      columns: 3,
      previewBuilder: _FifteenRectanglesPreview.new,
    ),
    LabelTemplate(
      title: '18 Per Sheet',
      subtitle: '10" x 12"',
      shape: shape,
      badge: false,
      rows: 6,
      columns: 3,
      previewBuilder: _EighteenRectanglesPreview.new,
    ),
  ];

  return base;
}

String _shapeTitle(LabelShapeType type) {
  switch (type) {
    case LabelShapeType.circle:
      return 'Circle';
    case LabelShapeType.ellipse:
      return 'Ellipse';
    case LabelShapeType.square:
      return 'Square';
    case LabelShapeType.rectangle:
      return 'Rectangle';
  }
}

class _TwoRectanglesPreview extends StatelessWidget {
  const _TwoRectanglesPreview(this.selected, this.shape);
  final bool selected;
  final LabelShapeType shape;

  @override
  Widget build(BuildContext context) {
    return _LabelGridPreview(
      selected: selected,
      shape: shape,
      rows: 2,
      columns: 1,
    );
  }
}

class _FourRectanglesPreview extends StatelessWidget {
  const _FourRectanglesPreview(this.selected, this.shape);
  final bool selected;
  final LabelShapeType shape;

  @override
  Widget build(BuildContext context) {
    return _LabelGridPreview(
      selected: selected,
      shape: shape,
      rows: 2,
      columns: 2,
    );
  }
}

class _SixRectanglesPreview extends StatelessWidget {
  const _SixRectanglesPreview(this.selected, this.shape);
  final bool selected;
  final LabelShapeType shape;

  @override
  Widget build(BuildContext context) {
    return _LabelGridPreview(
      selected: selected,
      shape: shape,
      rows: 3,
      columns: 2,
    );
  }
}

class _EightRectanglesPreview extends StatelessWidget {
  const _EightRectanglesPreview(this.selected, this.shape);
  final bool selected;
  final LabelShapeType shape;

  @override
  Widget build(BuildContext context) {
    return _LabelGridPreview(
      selected: selected,
      shape: shape,
      rows: 4,
      columns: 2,
    );
  }
}

class _FifteenRectanglesPreview extends StatelessWidget {
  const _FifteenRectanglesPreview(this.selected, this.shape);
  final bool selected;
  final LabelShapeType shape;

  @override
  Widget build(BuildContext context) {
    return _LabelGridPreview(
      selected: selected,
      shape: shape,
      rows: 5,
      columns: 3,
    );
  }
}

class _EighteenRectanglesPreview extends StatelessWidget {
  const _EighteenRectanglesPreview(this.selected, this.shape);
  final bool selected;
  final LabelShapeType shape;

  @override
  Widget build(BuildContext context) {
    return _LabelGridPreview(
      selected: selected,
      shape: shape,
      rows: 6,
      columns: 3,
    );
  }
}

class _LabelGridPreview extends StatelessWidget {
  const _LabelGridPreview({
    required this.selected,
    required this.shape,
    required this.rows,
    required this.columns,
  });

  final bool selected;
  final LabelShapeType shape;
  final int rows;
  final int columns;

  double get _aspectRatio {
    switch (shape) {
      case LabelShapeType.circle:
        return 1;
      case LabelShapeType.square:
        return 1;
      case LabelShapeType.ellipse:
        return 1.6;
      case LabelShapeType.rectangle:
        return 2.6;
    }
  }

  BoxDecoration _decoration(Color color) {
    if (shape == LabelShapeType.circle) {
      return BoxDecoration(color: color, shape: BoxShape.circle);
    }
    if (shape == LabelShapeType.ellipse) {
      return BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      );
    }
    final radius = shape == LabelShapeType.square ? 6.0 : 6.0;
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2F80ED) : Colors.black26;
    return SizedBox(
      height: 72,
      child: GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        padding: const EdgeInsets.all(2),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: _aspectRatio,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          rows * columns,
          (index) => Container(
            decoration: _decoration(color.withValues(alpha: selected ? 0.9 : 0.3)),
          ),
        ),
      ),
    );
  }
}
