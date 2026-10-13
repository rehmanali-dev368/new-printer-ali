import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ads/ad_service.dart';
import 'ads/banner_ad_widget.dart';
import 'page_style.dart';
import 'tools/feature_flows.dart';
import 'tools/tool_flow.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF9FCFF),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, pageTopGap(context), 20, 0),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tools',
                      textAlign: TextAlign.center,
                      style: pageTitleStyle,
                    ),
                    SizedBox(height: 12),
                    BannerAdWidget(
                      margin: EdgeInsets.only(bottom: 12),
                    ),
                    Expanded(child: _ToolsBody()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _runToolSelect(
  BuildContext context,
  Future<void> Function() action,
) {
  return AdService.instance.showSelectInterstitialThen(action);
}

class _ToolsBody extends StatelessWidget {
  const _ToolsBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 19, 0, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading('Conversions'),
          const SizedBox(height: 14),
          _ToolGrid(
            items: [
              _ToolData(
                'Image to PDF',
                'assets/home_icons/to_image_pdf.png',
                () => _runToolSelect(context, () => openImageToPdf(context)),
              ),
              _ToolData(
                'PDF to Image',
                'assets/home_icons/from_pdf_image.png',
                () => _runToolSelect(context, () => openPdfToImage(context)),
              ),
              _ToolData(
                'Word to PDF',
                'assets/home_icons/to_word_pdf.png',
                () => _runToolSelect(context, () => openWordToPdf(context)),
              ),
              _ToolData(
                'XLS to PDF',
                'assets/home_icons/to_xls_pdf.png',
                () => _runToolSelect(context, () => openXlsToPdf(context)),
              ),
              _ToolData(
                'PPT to PDF',
                'assets/home_icons/to_ppt_pdf.png',
                () => _runToolSelect(context, () => openPptToPdf(context)),
              ),
              _ToolData(
                'Txt to PDF',
                'assets/home_icons/to_text_pdf.png',
                () => _runToolSelect(context, () => openTextToPdf(context)),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const _SectionHeading('Tools'),
          const SizedBox(height: 14),
          _ToolGrid(
            items: [
              _ToolData(
                'Merge PDF',
                'assets/home_icons/tool_merge.png',
                () => _runToolSelect(context, () => openMergePdf(context)),
              ),
              _ToolData(
                'Split PDF',
                'assets/home_icons/tool_split.png',
                () => _runToolSelect(context, () => openSplitPdf(context)),
              ),
              _ToolData(
                'Delete Pages',
                'assets/home_icons/tool_delete.png',
                () => _runToolSelect(context, () => openRemovePages(context)),
              ),
              _ToolData(
                'Compress PDF',
                'assets/home_icons/tool_compress.png',
                () => _runToolSelect(context, () => openCompressPdf(context)),
              ),
              _ToolData(
                'Print PDF',
                'assets/home_icons/tool_print.png',
                () => _runToolSelect(context, () => openPrintPdf(context)),
              ),
              _ToolData(
                'Import PDF',
                'assets/home_icons/tool_new.png',
                () => _runToolSelect(context, () => openImportPdf(context)),
              ),
              _ToolData(
                'Lock',
                'assets/home_icons/tool_lock.png',
                () => _runToolSelect(context, () => openLockPdf(context)),
              ),
              _ToolData(
                'Unlock',
                'assets/home_icons/tool_unlock.png',
                () => _runToolSelect(context, () => openUnlockPdf(context)),
              ),
              _ToolData(
                'Reorder PDF',
                'assets/home_icons/tool_edit.png',
                () => _runToolSelect(context, () => openReorderPdf(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        fontSize: 20,
        height: 1,
        letterSpacing: 0.2,
        color: Color(0xFF000000),
      ),
    );
  }
}

class _ToolData {
  const _ToolData(this.title, this.iconPath, this.onTap);

  final String title;
  final String iconPath;
  final VoidCallback onTap;
}

class _ToolGrid extends StatelessWidget {
  const _ToolGrid({required this.items});

  final List<_ToolData> items;

  static const double _designCardSize = 114;
  static const double _spacing = 10;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = math.min(
          _designCardSize,
          (constraints.maxWidth - _spacing * 2) / 3,
        );
        final gridWidth = cardSize * 3 + _spacing * 2;
        final rowCount = (items.length / 3).ceil();
        final gridHeight = rowCount * cardSize + (rowCount - 1) * _spacing;

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: gridWidth,
            height: gridHeight,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: _spacing,
                mainAxisSpacing: _spacing,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                return _ToolCard(item: items[index], size: cardSize);
              },
            ),
          ),
        );
      },
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.item, required this.size});

  final _ToolData item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scale = size / _ToolGrid._designCardSize;
    final radius = 16.94 * scale;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFEEECEC), width: 0.6),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: const Color(0xFF3B82F6).withValues(alpha: 0.08),
          highlightColor: const Color(0xFF3B82F6).withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 16, 6, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  item.iconPath,
                  width: 34.171875 * scale,
                  height: 38.119140625 * scale,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 14 * scale,
                    height: 1,
                    letterSpacing: -0.28 * scale,
                    color: const Color(0xFF000000),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
