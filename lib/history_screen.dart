import 'dart:io';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'ads/ad_service.dart';
import 'ads/banner_ad_widget.dart';
import 'app_feedback.dart';
import 'pdf/pdf_library.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    PdfLibrary.instance.addListener(_refresh);
    PdfLibrary.instance.load();
  }

  @override
  void dispose() {
    PdfLibrary.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await AppPopup.confirm(
      context,
      title: 'Delete all',
      message: 'Remove every file from history?',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    AppLoader.show(context, message: 'Deleting…');
    try {
      await PdfLibrary.instance.clear();
    } finally {
      AppLoader.hide();
    }
  }

  Future<void> _reprint(PdfJob job) async {
    if (!job.path.toLowerCase().endsWith('.pdf') || !File(job.path).existsSync()) {
      await AppPopup.notice(
        context,
        title: File(job.path).existsSync() ? 'Saved file' : 'File not found',
        message: File(job.path).existsSync()
            ? 'This file is saved in History.'
            : 'This file is no longer on this phone.',
        kind: AppNotice.error,
      );
      return;
    }
    await AdService.instance.showInterstitialThen(() async {
      if (!mounted) {
        return;
      }
      AppLoader.show(context, message: 'Opening print…');
      try {
        final bytes = await PdfLibrary.instance.read(job);
        AppLoader.hide();
        if (!mounted) {
          return;
        }
        await Printing.layoutPdf(onLayout: (_) async => bytes);
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobs = PdfLibrary.instance.jobs;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FCFF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        foregroundColor: Colors.black,
        title: const Text(
          'History',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        actions: [
          if (jobs.isNotEmpty)
            IconButton(
              tooltip: 'Delete all',
              icon: const Icon(Icons.delete_forever, color: Color(0xFFE64C3C)),
              onPressed: _deleteAll,
            ),
        ],
      ),
      body: Column(
        children: [
          const BannerAdWidget(
            margin: EdgeInsets.fromLTRB(12, 6, 12, 6),
          ),
          Expanded(
            child: jobs.isEmpty
                ? const _EmptyHistory()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: jobs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                final job = jobs[index];
                final exists = File(job.path).existsSync();
                final when = job.createdAt.toIso8601String().replaceFirst('T', ' ').split('.').first;
                return Dismissible(
                  key: ValueKey('${job.path}|${job.createdAt.toIso8601String()}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => PdfLibrary.instance.delete(job),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE64C3C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _reprint(job),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FBFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD6E4FF), width: 0.6),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.print, size: 22, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  when,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(
                            label: exists ? 'Printed' : 'Failed',
                            color: exists ? const Color(0xFF15A144) : const Color(0xFFE64C3C),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 72, color: Color(0xFFCBD5E1)),
          SizedBox(height: 12),
          Text(
            'No history yet',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 6, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: color),
        ),
      ],
    );
  }
}
