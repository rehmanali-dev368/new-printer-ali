import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../ads/ad_service.dart';
import '../ads/banner_ad_widget.dart';
import '../app_feedback.dart';
import '../pro/pro_controller.dart';
import '../pro/pro_navigation.dart';
import 'printable_editor_screen.dart';

Future<void> _openPrintable(BuildContext context, String imageUrl) async {
  await AdService.instance.showSelectInterstitialThen(() async {
    if (!context.mounted) {
      return;
    }
    AppLoader.show(context, message: 'Opening…');
    try {
      await precacheImage(NetworkImage(imageUrl), context).timeout(const Duration(seconds: 20));
    } catch (_) {
      // Still open the editor; it has its own error UI if the image fails.
    }
    AppLoader.hide();
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PrintableEditorScreen(imageUrl: imageUrl)),
    );
  });
}

const printablesCdnBaseUrl = 'https://djgw7epkj4fdy.cloudfront.net';
const printablesFallbackThumbUrl =
    '$printablesCdnBaseUrl/SmartPrinterData/Printables/Birthday/Thumbnails/1.png';

String printableImageUrl(String parent, String folder, String kind, int index) {
  final safeParent = Uri.encodeComponent(parent);
  final safeFolder = Uri.encodeComponent(folder);
  return '$printablesCdnBaseUrl/SmartPrinterData/$safeParent/$safeFolder/$kind/$index.png';
}

class PrintablesScreen extends StatefulWidget {
  const PrintablesScreen({super.key});

  @override
  State<PrintablesScreen> createState() => _PrintablesScreenState();
}

class _PrintablesScreenState extends State<PrintablesScreen> {
  static const _assetCategoriesPath = 'assets/json/Categories.json';
  static const _remoteCategoriesUrl = '$printablesCdnBaseUrl/SmartPrinterData/Categories.json';

  late Future<List<_CategoryGroup>> _categoriesFuture;
  bool _syncing = false;
  int _selectedParent = 0;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _loadCategories();
  }

  Future<List<_CategoryGroup>> _loadCategories() async {
    final live = await _fetchLiveCategories();
    if (live != null && live.isNotEmpty) {
      return live;
    }
    return _jsonReader();
  }

  Future<List<_CategoryGroup>> _jsonReader() async {
    final raw = await rootBundle.loadString(_assetCategoriesPath);
    return _parseCategories(raw);
  }

  List<_CategoryGroup> _parseCategories(String raw) {
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) {
      return const [];
    }
    return (data['categories'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((item) => _CategoryGroup.fromJson(Map<String, dynamic>.from(item)))
        .where((group) => group.name.isNotEmpty && group.items.isNotEmpty)
        .toList();
  }

  Future<void> _refreshCategoriesFromServer() async {
    if (_syncing) {
      return;
    }
    _syncing = true;
    try {
      final parsed = await _loadCategories();
      if (!mounted) {
        return;
      }
      setState(() => _categoriesFuture = Future.value(parsed));
    } finally {
      _syncing = false;
    }
  }

  Future<List<_CategoryGroup>?> _fetchLiveCategories() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(Uri.parse(_remoteCategoriesUrl));
      final response = await request.close().timeout(const Duration(seconds: 12));
      if (response.statusCode != HttpStatus.ok) {
        return null;
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      final parsed = _parseCategories(utf8.decode(builder.takeBytes()));
      if (parsed.isEmpty) {
        return null;
      }
      return parsed;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Printables',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: const [_ProChip()],
      ),
      body: FutureBuilder<List<_CategoryGroup>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text(
                'Failed to load categories',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            );
          }

          final groups = snapshot.data!;
          if (groups.isEmpty) {
            return const Center(
              child: Text('No categories found', style: TextStyle(fontFamily: 'Poppins')),
            );
          }

          final selected = _selectedParent.clamp(0, groups.length - 1).toInt();
          final group = groups[selected];
          return Column(
            children: [
              const BannerAdWidget(
                margin: EdgeInsets.fromLTRB(12, 6, 12, 8),
              ),
              _ParentTabs(
                groups: groups,
                selected: selected,
                onSelected: (index) => setState(() => _selectedParent = index),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF3B82F6),
                  onRefresh: _refreshCategoriesFromServer,
                  child: ListView.builder(
                    key: ValueKey(group.name),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: group.items.length,
                    itemBuilder: (context, index) {
                      final item = group.items[index];
                      return _PrintableSection(
                        key: ValueKey('${group.name}/${item.name}'),
                        parent: group.name,
                        item: item,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProChip extends StatelessWidget {
  const _ProChip();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProController.instance,
      builder: (context, _) {
        if (ProController.instance.isPro) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2F8CFF),
              side: const BorderSide(color: Color(0xFF2F8CFF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => openUpgradePro(context),
            icon: const ImageIcon(
              AssetImage('assets/images/Vector.png'),
              size: 18,
              color: Color(0xFF2F8CFF),
            ),
            label: const Text(
              'PRO',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        );
      },
    );
  }
}

class _ParentTabs extends StatelessWidget {
  const _ParentTabs({
    required this.groups,
    required this.selected,
    required this.onSelected,
  });

  final List<_CategoryGroup> groups;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < groups.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: i == selected
                        ? const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    groups[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: i == selected ? FontWeight.w600 : FontWeight.w500,
                      color: i == selected ? const Color(0xFF0242F5) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrintableSection extends StatelessWidget {
  const _PrintableSection({super.key, required this.parent, required this.item});

  final String parent;
  final _CategoryItem item;

  String _thumbnailUrl(int index) => printableImageUrl(parent, item.name, 'Thumbnails', index);

  String _highResUrl(int index) => printableImageUrl(parent, item.name, 'HighRes', index);

  @override
  Widget build(BuildContext context) {
    final total = item.count <= 0 ? 3 : item.count;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              item.title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _PrintableSeeAllScreen(parent: parent, item: item),
                  ),
                );
              },
              child: const Text(
                'See All',
                style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF3B82F6), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SizedBox(
          height: _cardStyle(parent).rowHeight,
          child: ListView.builder(
            key: ValueKey('$parent/${item.name}'),
            scrollDirection: Axis.horizontal,
            itemCount: total,
            itemBuilder: (context, index) {
              final imageUrl = _thumbnailUrl(index + 1);
              return Padding(
                padding: EdgeInsets.only(right: index == total - 1 ? 0 : 12),
                child: _PrintableCard(
                  key: ValueKey(imageUrl),
                  imageUrl: imageUrl,
                  style: _cardStyle(parent),
                  onTap: () => _openPrintable(context, _highResUrl(index + 1)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _PrintableSeeAllScreen extends StatelessWidget {
  const _PrintableSeeAllScreen({required this.parent, required this.item});

  final String parent;
  final _CategoryItem item;

  String _thumbnailUrl(int index) => printableImageUrl(parent, item.name, 'Thumbnails', index);

  String _highResUrl(int index) => printableImageUrl(parent, item.name, 'HighRes', index);

  @override
  Widget build(BuildContext context) {
    final total = item.count <= 0 ? 0 : item.count;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          item.title,
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: total,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: _cardStyle(parent).gridAspect,
        ),
        itemBuilder: (context, index) {
          final imageUrl = _thumbnailUrl(index + 1);
          return _PrintableCard(
            key: ValueKey(imageUrl),
            imageUrl: imageUrl,
            style: _cardStyle(parent),
            expand: true,
            onTap: () => _openPrintable(context, _highResUrl(index + 1)),
          );
        },
      ),
    );
  }
}

class _CardStyle {
  const _CardStyle({
    required this.rowHeight,
    required this.width,
    required this.cardHeight,
    required this.inset,
    required this.fit,
    required this.gridAspect,
  });

  final double rowHeight;
  final double width;
  final double cardHeight;
  final double inset;
  final BoxFit fit;
  final double gridAspect;
}

_CardStyle _cardStyle(String parent) {
  switch (parent.toLowerCase()) {
    case 'labels':
      // Square labels, shorter row so they read like label sheets.
      return const _CardStyle(
        rowHeight: 108,
        width: 100,
        cardHeight: 100,
        inset: 8,
        fit: BoxFit.contain,
        gridAspect: 1,
      );
    case 'stickers':
      // Square stickers with a little padding so edges stay soft.
      return const _CardStyle(
        rowHeight: 132,
        width: 120,
        cardHeight: 120,
        inset: 10,
        fit: BoxFit.contain,
        gridAspect: 1,
      );
    default:
      // Portrait printables fill the card background.
      return const _CardStyle(
        rowHeight: 156,
        width: 110,
        cardHeight: 156,
        inset: 0,
        fit: BoxFit.cover,
        gridAspect: 0.707,
      );
  }
}

class _PrintableCard extends StatelessWidget {
  const _PrintableCard({
    super.key,
    required this.imageUrl,
    required this.onTap,
    required this.style,
    this.expand = false,
  });

  final String imageUrl;
  final VoidCallback onTap;
  final _CardStyle style;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: expand ? double.infinity : style.width,
        height: expand ? double.infinity : style.cardHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(style.inset),
          child: _PrintableCachedImage(
            imageUrl: imageUrl,
            fallbackUrl: printablesFallbackThumbUrl,
            fit: style.fit,
          ),
        ),
      ),
    );
  }
}

class _CategoryGroup {
  _CategoryGroup({required this.name, required this.title, required this.items});

  final String name;
  final String title;
  final List<_CategoryItem> items;

  factory _CategoryGroup.fromJson(Map<String, dynamic> json) {
    final list = (json['categories'] as List<dynamic>? ?? [])
        .map((item) => _CategoryItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return _CategoryGroup(
      name: (json['categoryName'] as String?) ?? '',
      title: (json['categoryTitle'] as String?) ?? '',
      items: list,
    );
  }
}

class _CategoryItem {
  _CategoryItem({
    required this.name,
    required this.title,
    required this.count,
  });

  final String name;
  final String title;
  final int count;

  factory _CategoryItem.fromJson(Map<String, dynamic> json) {
    return _CategoryItem(
      name: (json['catName'] as String?) ?? '',
      title: (json['catTitle'] as String?) ?? '',
      count: (json['templateCount'] as num?)?.toInt() ?? (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class _PrintableCachedImage extends StatefulWidget {
  const _PrintableCachedImage({
    required this.imageUrl,
    required this.fallbackUrl,
    this.fit = BoxFit.contain,
  });

  final String imageUrl;
  final String fallbackUrl;
  final BoxFit fit;

  @override
  State<_PrintableCachedImage> createState() => _PrintableCachedImageState();
}

class _PrintableCachedImageState extends State<_PrintableCachedImage> {
  late Future<File?> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _resolveImageFile();
  }

  @override
  void didUpdateWidget(covariant _PrintableCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      setState(() => _imageFuture = _resolveImageFile());
    }
  }

  Future<File?> _resolveImageFile() async {
    final primary = await _getOrDownloadImage(widget.imageUrl);
    if (primary != null) {
      return primary;
    }
    return _getOrDownloadImage(widget.fallbackUrl);
  }

  Future<File?> _getOrDownloadImage(String url) async {
    try {
      final file = await _cacheFileForUrl(url);
      if (await file.exists() && await file.length() > 0) {
        return file;
      }
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close().timeout(const Duration(seconds: 10));
        if (response.statusCode != HttpStatus.ok) {
          return null;
        }
        final builder = BytesBuilder(copy: false);
        await for (final chunk in response) {
          builder.add(chunk);
        }
        final bytes = builder.takeBytes();
        await file.writeAsBytes(bytes, flush: true);
        return file;
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      return null;
    }
  }

  Future<File> _cacheFileForUrl(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/printables_thumbs_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    final safeName = url.hashCode.toUnsigned(32).toRadixString(16);
    return File('${cacheDir.path}/$safeName.png');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const ColoredBox(
            color: Color(0xFFF1F3F6),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
              ),
            ),
          );
        }
        final file = snapshot.data;
        if (file == null) {
          return const ColoredBox(
            color: Color(0xFFF1F3F6),
            child: Center(child: Icon(Icons.broken_image, color: Colors.black38)),
          );
        }
        return Image.file(file, fit: widget.fit);
      },
    );
  }
}
