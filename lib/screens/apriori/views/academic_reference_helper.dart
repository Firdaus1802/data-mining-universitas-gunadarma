import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AcademicReferenceHelper {
  static const Color gunadarmaPurple = Color(0xFF4A148C);
  static const Color darkText = Color(0xFF1C1C1E);
  static const Color mutedText = Color(0xFF8E8E93);
  static const Color cardBorder = Color(0xFFE5E5EA);

  static const String nationalJournalUrl =
      'https://ejurnal.lkpkaryaprima.id/index.php/juktisi/article/view/1033/830';
  static const String nationalJournalDirectPdfUrl =
      'https://ejurnal.lkpkaryaprima.id/index.php/juktisi/article/download/1033/830';
  static const String nationalJournalDoiUrl = 'https://doi.org/10.62712/juktisi.v5i1.1033';

  static const String internationalJournalUrl = 'https://ijiis.org/index.php/IJIIS/article/view/252';
  static const String internationalJournalDirectPdfUrl =
      'https://ijiis.org/index.php/IJIIS/article/download/252/160';
  static const String internationalJournalDoiUrl = 'https://doi.org/10.47738/ijiis.v8i2.252';

  static const String journalDoiUrl = nationalJournalDoiUrl;
  static const String journalScholarUrl =
      'https://scholar.google.com/scholar?q=Implementasi+Algoritma+Apriori+Warung+Kelontong+Maju+Jaya+JUKTISI';
  static const String kaggleDatasetUrl = 'https://www.kaggle.com/datasets/heeraldedhia/groceries-dataset';

  static const String nationalApaCitation =
      'Nafisah, D., Asriningati, D., Maulia, S. D., Bintang P, M. A., & Arifin, M. (2026). Implementasi Algoritma Apriori Untuk Analisis Pola Pembelian Pada Data Transaksi Warung Kelontong Maju Jaya. Jurnal Komputer Teknologi Informasi Sistem Komputer (JUKTISI), 5(1), 1146–1151. https://doi.org/10.62712/juktisi.v5i1.1033';

  static const String internationalApaCitation =
      'Prasetio, A. B., Aboobaider, B. M., & Ahmad, A. (2025). Interpretable Product Recommendation through Association Rule Mining: An Apriori-Based Analysis on Retail Transaction Data. International Journal of Informatics and Information Systems, 8(2), 67–74. https://doi.org/10.47738/ijiis.v8i2.252';

  static const String apaCitation = nationalApaCitation;

  static Future<void> safeLaunchUrl(BuildContext context, String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        final fallbackOk = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallbackOk && context.mounted) {
          showUrlFallback(context, urlString);
        }
      }
    } catch (_) {
      if (context.mounted) {
        showUrlFallback(context, urlString);
      }
    }
  }

  static void showUrlFallback(BuildContext context, String urlString) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Buka Tautan Eksternal'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            urlString,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: urlString));
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tautan berhasil disalin ke papan klip.'),
                    backgroundColor: gunadarmaPurple,
                  ),
                );
              }
            },
            child: const Text('Salin Tautan'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  static void showPdfDirectPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1D1D6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Naskah & Jurnal Ilmiah',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  color: darkText,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Akses dokumen PDF atau kunjungi laman OJS',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: mutedText,
                                ),
                              ),
                            ],
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE5E5EA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.xmark,
                                size: 13,
                                color: Color(0xFF3C3C43),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildJournalCard(
                        context: context,
                        tag: 'JURNAL NASIONAL (UTAMA)',
                        tagColor: gunadarmaPurple,
                        tagBg: const Color(0xFFF3E8FF),
                        title:
                            'Implementasi Algoritma Apriori Untuk Analisis Pola Pembelian Pada Data Transaksi Warung Kelontong Maju Jaya',
                        meta: 'JUKTISI (2026) • Durrotun Nafisah et al. • 310 KB',
                        onOpenPdf: () {
                          Navigator.of(sheetContext).pop();
                          directOpenNationalPdf(context);
                        },
                        onOpenWeb: () => safeLaunchUrl(context, nationalJournalUrl),
                        onDownload: () => downloadNationalJournalPdf(context),
                      ),
                      const SizedBox(height: 10),
                      _buildJournalCard(
                        context: context,
                        tag: 'JURNAL PEMBANDING (INTERNASIONAL)',
                        tagColor: const Color(0xFF166534),
                        tagBg: const Color(0xFFDCFCE7),
                        title:
                            'Interpretable Product Recommendation through Association Rule Mining: An Apriori-Based Analysis on Retail Transaction Data',
                        meta: 'IJIIS (2025) • Agung Budi Prasetio et al. • 381 KB',
                        onOpenPdf: () {
                          Navigator.of(sheetContext).pop();
                          directOpenInternationalPdf(context);
                        },
                        onOpenWeb: () => safeLaunchUrl(context, internationalJournalUrl),
                        onDownload: () => downloadInternationalJournalPdf(context),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              color: const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(10),
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                showDatasetModal(context);
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.table, size: 14, color: darkText),
                                  SizedBox(width: 5),
                                  Text(
                                    'Dataset CSV',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: darkText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              color: const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(10),
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                showJournalModal(context);
                              },
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.info_circle, size: 14, color: darkText),
                                  SizedBox(width: 5),
                                  Text(
                                    'Sitasi & Detail',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: darkText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> directOpenNationalPdf(BuildContext context) async {
    try {
      if (kIsWeb) {
        final ok = await launchUrl(
          Uri.parse('jurnal_nasional.pdf'),
          mode: LaunchMode.externalApplication,
        );
        if (!ok) {
          await launchUrl(
            Uri.parse(nationalJournalDirectPdfUrl),
            mode: LaunchMode.externalApplication,
          );
        }
        return;
      }

      final ok = await launchUrl(
        Uri.parse(nationalJournalDirectPdfUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) {
        await downloadNationalJournalPdf(context);
      }
    } catch (_) {
      if (context.mounted) {
        await downloadNationalJournalPdf(context);
      }
    }
  }

  static Future<void> directOpenInternationalPdf(BuildContext context) async {
    try {
      if (kIsWeb) {
        final ok = await launchUrl(
          Uri.parse('jurnal_internasional.pdf'),
          mode: LaunchMode.externalApplication,
        );
        if (!ok) {
          await launchUrl(
            Uri.parse(internationalJournalDirectPdfUrl),
            mode: LaunchMode.externalApplication,
          );
        }
        return;
      }

      final ok = await launchUrl(
        Uri.parse(internationalJournalDirectPdfUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) {
        await downloadInternationalJournalPdf(context);
      }
    } catch (_) {
      if (context.mounted) {
        await downloadInternationalJournalPdf(context);
      }
    }
  }

  static void downloadJournalPdf(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1D1D6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unduh Berkas Riset & Data',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  color: darkText,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Simpan dokumen PDF atau CSV ke perangkat',
                                style: TextStyle(fontSize: 11.5, color: mutedText),
                              ),
                            ],
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE5E5EA),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.xmark, size: 13, color: Color(0xFF3C3C43)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildDownloadTile(
                        icon: CupertinoIcons.doc_text_fill,
                        iconColor: gunadarmaPurple,
                        bgColor: const Color(0xFFF3E8FF),
                        title: 'PDF Jurnal Nasional (JUKTISI)',
                        subtitle: 'Warung Kelontong Maju Jaya • 310 KB',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          downloadNationalJournalPdf(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildDownloadTile(
                        icon: CupertinoIcons.doc_text_fill,
                        iconColor: const Color(0xFF166534),
                        bgColor: const Color(0xFFDCFCE7),
                        title: 'PDF Jurnal Pembanding (IJIIS)',
                        subtitle: 'Retail Transaction Analysis • 381 KB',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          downloadInternationalJournalPdf(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildDownloadTile(
                        icon: CupertinoIcons.table,
                        iconColor: const Color(0xFF007AFF),
                        bgColor: const Color(0xFFE0F2FE),
                        title: 'Dataset Transaksi Groceries (.csv)',
                        subtitle: '1.000 Transaksi Riil Kaggle • 29.3 KB',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          downloadDatasetCsv(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> downloadNationalJournalPdf(BuildContext context) async {
    try {
      if (kIsWeb) {
        final ok = await launchUrl(
          Uri.parse('jurnal_nasional.pdf'),
          mode: LaunchMode.externalApplication,
        );
        if (!ok) {
          await launchUrl(
            Uri.parse(nationalJournalDirectPdfUrl),
            mode: LaunchMode.externalApplication,
          );
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berkas PDF Jurnal Nasional berhasil dibuka!'),
              backgroundColor: Color(0xFF2E7D32),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final byteData = await rootBundle.load('assets/documents/jurnal_nasional_warung_maju_jaya.pdf');
      final bytes = byteData.buffer.asUint8List();
      final uri = await FilePicker.saveFile(
        fileName: 'Jurnal_Nasional_Warung_Maju_Jaya.pdf',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        mimeType: 'application/pdf',
        dialogTitle: 'Simpan Naskah PDF Jurnal Nasional',
      );

      if (context.mounted) {
        if (uri != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Naskah PDF Jurnal Nasional berhasil disimpan!'),
              backgroundColor: Color(0xFF2E7D32),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Penyimpanan berkas PDF dibatalkan.'),
              backgroundColor: Color(0xFF757575),
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan berkas PDF. Silakan periksa izin penyimpanan.'),
            backgroundColor: Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  static Future<void> downloadInternationalJournalPdf(BuildContext context) async {
    try {
      if (kIsWeb) {
        final ok = await launchUrl(
          Uri.parse('jurnal_internasional.pdf'),
          mode: LaunchMode.externalApplication,
        );
        if (!ok) {
          await launchUrl(
            Uri.parse(internationalJournalDirectPdfUrl),
            mode: LaunchMode.externalApplication,
          );
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berkas PDF Jurnal Internasional berhasil dibuka!'),
              backgroundColor: Color(0xFF2E7D32),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final byteData = await rootBundle.load('assets/documents/jurnal_internasional_interpretable_retail.pdf');
      final bytes = byteData.buffer.asUint8List();
      final uri = await FilePicker.saveFile(
        fileName: 'Jurnal_Internasional_Interpretable_Retail.pdf',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        mimeType: 'application/pdf',
        dialogTitle: 'Simpan Naskah PDF Jurnal Internasional',
      );

      if (context.mounted) {
        if (uri != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Naskah PDF Jurnal Internasional berhasil disimpan!'),
              backgroundColor: Color(0xFF2E7D32),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Penyimpanan berkas PDF dibatalkan.'),
              backgroundColor: Color(0xFF757575),
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan berkas PDF. Silakan periksa izin penyimpanan.'),
            backgroundColor: Color(0xFFFF3B30),
          ),
        );
      }
    }
  }

  static Future<String> loadDatasetString() async {
    return await rootBundle.loadString('assets/data/dataset_groceries_1000.csv');
  }

  static Future<void> downloadDatasetCsv(BuildContext context) async {
    try {
      if (kIsWeb) {
        final ok = await launchUrl(
          Uri.parse('dataset.csv'),
          mode: LaunchMode.externalApplication,
        );
        if (!ok) {
          await launchUrl(
            Uri.parse('assets/assets/data/dataset_groceries_1000.csv'),
            mode: LaunchMode.externalApplication,
          );
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dataset CSV berhasil dibuka / diunduh!'),
              backgroundColor: Color(0xFF2E7D32),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final rawCsv = await loadDatasetString();
      final bytes = Uint8List.fromList(utf8.encode(rawCsv));
      final uri = await FilePicker.saveFile(
        fileName: 'dataset_groceries_1000.csv',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        mimeType: 'text/csv',
        dialogTitle: 'Simpan File Dataset Groceries (1.000 Transaksi)',
      );

      if (context.mounted) {
        if (uri != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dataset berhasil diunduh dan disimpan ke perangkat.'),
              backgroundColor: Color(0xFF2E7D32),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Penyimpanan berkas dibatalkan oleh pengguna.'),
              backgroundColor: Color(0xFF757575),
            ),
          );
        }
      }
    } catch (_) {
      try {
        final rawCsv = await loadDatasetString();
        await Clipboard.setData(ClipboardData(text: rawCsv));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dataset 1.000 transaksi berhasil disalin ke papan klip.'),
              backgroundColor: gunadarmaPurple,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (_) {}
    }
  }

  static Future<void> copyDatasetCsv(BuildContext context) async {
    try {
      final rawCsv = await loadDatasetString();
      await Clipboard.setData(ClipboardData(text: rawCsv));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seluruh 1.000 baris CSV dataset disalin ke papan klip!'),
            backgroundColor: gunadarmaPurple,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {}
  }

  static void showJournalModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.5,
              maxChildSize: 0.96,
              builder: (ctx, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D1D6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Naskah & Publikasi Jurnal Ilmiah',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: darkText,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Jurnal Nasional & Jurnal Pembanding Internasional',
                              style: TextStyle(fontSize: 12, color: mutedText),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Color(0xFF8E8E93), size: 28),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: gunadarmaPurple,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'JURNAL NASIONAL (UTAMA)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'e-ISSN: 2963-7104',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: mutedText),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Implementasi Algoritma Apriori Untuk Analisis Pola Pembelian Pada Data Transaksi Warung Kelontong Maju Jaya',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: darkText,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Penulis: Durrotun Nafisah, Dian Asriningati, Seila Desy Maulia, M. Alvino Bintang P, Muhammad Arifin\nAfiliasi: Program Studi Sistem Informasi, Universitas Muria Kudus\nPublikasi: Jurnal Komputer Teknologi Informasi Sistem Komputer (JUKTISI)\nVolume & Terbitan: Vol. 5, No. 1, Juni 2026, Hal. 1146–1151\nDOI: 10.62712/juktisi.v5i1.1033\n\nPenelitian empiris analisis keranjang belanja (Market Basket Analysis) toko kelontong ritel untuk menentukan aturan asosiasi (Support, Confidence, Lift Ratio) dan penataan tata letak barang dagangan.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF4A4A4A), height: 1.45),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      color: gunadarmaPurple,
                                      borderRadius: BorderRadius.circular(8),
                                      onPressed: () => directOpenNationalPdf(context),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(CupertinoIcons.eye_fill, size: 14, color: Colors.white),
                                          SizedBox(width: 6),
                                          Text(
                                            'Buka PDF Langsung',
                                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      color: const Color(0xFFF3E8FF),
                                      borderRadius: BorderRadius.circular(8),
                                      onPressed: () => downloadNationalJournalPdf(context),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(CupertinoIcons.arrow_down_doc_fill, size: 14, color: gunadarmaPurple),
                                          SizedBox(width: 6),
                                          Text(
                                            'Unduh PDF',
                                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: gunadarmaPurple),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF166534),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'JURNAL PEMBANDING (INTERNASIONAL)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'ISSN: 2579-7069',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: mutedText),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Interpretable Product Recommendation through Association Rule Mining: An Apriori-Based Analysis on Retail Transaction Data',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: darkText,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Penulis: Agung Budi Prasetio, Burhanuddin bin Mohd Aboobaider, Asmala bin Ahmad\nAfiliasi: Institut Teknologi Tangerang Selatan & Universiti Teknikal Malaysia Melaka (UTeM)\nPublikasi: International Journal of Informatics and Information Systems (IJIIS)\nVolume & Halaman: Vol. 8, No. 2, March 2025, pp. 67–74\nDOI: 10.47738/ijiis.v8i2.252\n\nStudi komparasi internasional mengenai sistem rekomendasi produk retail berbasis algoritma Apriori dengan fokus interpretabilitas pola asosiasi belanja konsumen.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF4A4A4A), height: 1.45),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      color: const Color(0xFF166534),
                                      borderRadius: BorderRadius.circular(8),
                                      onPressed: () => directOpenInternationalPdf(context),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(CupertinoIcons.eye_fill, size: 14, color: Colors.white),
                                          SizedBox(width: 6),
                                          Text(
                                            'Buka PDF Langsung',
                                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(8),
                                      onPressed: () => downloadInternationalJournalPdf(context),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(CupertinoIcons.arrow_down_doc_fill, size: 14, color: Color(0xFF166534)),
                                          SizedBox(width: 6),
                                          Text(
                                            'Unduh PDF',
                                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'PILIHAN AKSES NASKAH & DOKUMEN PDF',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: mutedText, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 10),
                        _buildActionTile(
                          icon: CupertinoIcons.doc_text_fill,
                          iconColor: Colors.white,
                          bgColor: gunadarmaPurple,
                          title: 'Buka PDF Jurnal Nasional (310 KB)',
                          subtitle: 'Buka naskah Warung Kelontong Maju Jaya (JUKTISI)',
                          onTap: () => directOpenNationalPdf(context),
                        ),
                        const SizedBox(height: 8),
                        _buildActionTile(
                          icon: CupertinoIcons.doc_text_fill,
                          iconColor: Colors.white,
                          bgColor: const Color(0xFF166534),
                          title: 'Buka PDF Jurnal Pembanding Internasional (381 KB)',
                          subtitle: 'Buka naskah Retail Recommendation Analysis (IJIIS)',
                          onTap: () => directOpenInternationalPdf(context),
                        ),
                        const SizedBox(height: 8),
                        _buildActionTile(
                          icon: CupertinoIcons.link,
                          iconColor: gunadarmaPurple,
                          bgColor: const Color(0xFFF3E8FF),
                          title: 'Laman Resmi Jurnal Nasional (JUKTISI)',
                          subtitle: 'https://ejurnal.lkpkaryaprima.id/index.php/juktisi/article/view/1033/830',
                          onTap: () => safeLaunchUrl(context, nationalJournalUrl),
                        ),
                        const SizedBox(height: 8),
                        _buildActionTile(
                          icon: CupertinoIcons.globe,
                          iconColor: const Color(0xFF007AFF),
                          bgColor: const Color(0xFFE0F2FE),
                          title: 'Laman Resmi Jurnal Pembanding (IJIIS)',
                          subtitle: 'https://ijiis.org/index.php/IJIIS/article/view/252',
                          onTap: () => safeLaunchUrl(context, internationalJournalUrl),
                        ),
                        const SizedBox(height: 8),
                        _buildActionTile(
                          icon: CupertinoIcons.arrow_up_right_square,
                          iconColor: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFEF3C7),
                          title: 'Buka Link Dataset di Kaggle',
                          subtitle: 'https://www.kaggle.com/datasets/heeraldedhia/groceries-dataset',
                          onTap: () => safeLaunchUrl(context, kaggleDatasetUrl),
                        ),
                        const SizedBox(height: 8),
                        _buildActionTile(
                          icon: CupertinoIcons.arrow_down_doc_fill,
                          iconColor: const Color(0xFF007AFF),
                          bgColor: const Color(0xFFE0F2FE),
                          title: 'Unduh Berkas Dataset (.csv)',
                          subtitle: 'Simpan file CSV 1.000 transaksi ke perangkat',
                          onTap: () => downloadDatasetCsv(context),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'RINGKASAN & METODOLOGI PENELITIAN',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: mutedText, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 10),
                        _buildTextCard(
                          title: '1. Latar Belakang & Urgensi Warung Kelontong & Ritel',
                          content:
                              'Pertumbuhan transaksi harian pada usaha ritel dan warung kelontong menghasilkan volume data belanja yang melimpah. Analisis pola asosiasi (Market Basket Analysis) diperlukan untuk menemukan kombinasi produk yang paling sering dibeli bersamaan guna optimalisasi penataan tata letak barang dagangan dan promosi bundling.',
                        ),
                        const SizedBox(height: 10),
                        _buildTextCard(
                          title: '2. Formulasi Metrik Evaluasi Asosiasi',
                          content:
                              'Kaidah asosiasi diuji melalui tiga metrik baku:\n• Support: Frekuensi kemunculan kombinasi item dari total keseluruhan transaksi (P(A ∪ B)).\n• Confidence: Tingkat kepastian bahwa jika item A dibeli, item B juga akan dibeli (P(B|A)).\n• Lift Ratio: Ukuran kevalidan asosiasi terhadap probabilitas acak independen. Nilai Lift > 1 menandakan aturan asosiasi positif yang kuat dan signifikan.',
                        ),
                        const SizedBox(height: 10),
                        _buildTextCard(
                          title: '3. Kaidah Asosiasi & Rekomendasi Penataan Produk',
                          content:
                              'Penerapan algoritma Apriori menghasilkan aturan asosiasi nyata pada transaksi kelontong dan ritel, memungkinkan penempatan produk komplementer pada etalase yang berdekatan untuk meningkatkan basket size dan efisiensi belanja konsumen.',
                        ),
                        const SizedBox(height: 10),
                        _buildTextCard(
                          title: '4. Sintesis Riset Nasional & Internasional',
                          content:
                              'Penelitian JUKTISI (2026) dan IJIIS (2025) saling menguatkan bahwa algoritma Apriori menghasilkan rekomendasi produk yang transparan, mudah diinterpretasikan oleh pemilik toko/manajemen ritel, serta terbukti efektif untuk dataset transaksi skala nyata.',
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: CupertinoButton(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                color: const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(12),
                                onPressed: () async {
                                  await Clipboard.setData(const ClipboardData(text: nationalApaCitation));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Sitasi Jurnal Nasional (JUKTISI) berhasil disalin!'),
                                        backgroundColor: gunadarmaPurple,
                                      ),
                                    );
                                  }
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.doc_on_clipboard, size: 16, color: gunadarmaPurple),
                                    SizedBox(width: 6),
                                    Text(
                                      'Sitasi Nasional',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: gunadarmaPurple),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CupertinoButton(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                                onPressed: () async {
                                  await Clipboard.setData(const ClipboardData(text: internationalApaCitation));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Sitasi Jurnal Pembanding (IJIIS) berhasil disalin!'),
                                        backgroundColor: Color(0xFF007AFF),
                                      ),
                                    );
                                  }
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(CupertinoIcons.doc_on_clipboard, size: 16, color: Color(0xFF007AFF)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Sitasi Internasional',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF007AFF)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          color: gunadarmaPurple,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () => showPdfDirectPicker(context),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.doc_text_fill, size: 16, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Buka Berkas PDF Jurnal',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  },
);
}

  static void showDatasetModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _DatasetViewerSheet(sheetContext: sheetContext),
          ),
        );
      },
    );
  }

  static Widget _buildJournalCard({
    required BuildContext context,
    required String tag,
    required Color tagColor,
    required Color tagBg,
    required String title,
    required String meta,
    required VoidCallback onOpenPdf,
    required VoidCallback onOpenWeb,
    required VoidCallback onDownload,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: tagColor,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: darkText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meta,
            style: const TextStyle(
              fontSize: 11,
              color: mutedText,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: tagColor,
                  borderRadius: BorderRadius.circular(8),
                  onPressed: onOpenPdf,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.doc_text_fill, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Buka PDF',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 5,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: tagBg,
                  borderRadius: BorderRadius.circular(8),
                  onPressed: onOpenWeb,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.globe, size: 13, color: tagColor),
                      const SizedBox(width: 4),
                      Text(
                        'Laman OJS',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: tagColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
                onPressed: onDownload,
                child: const Icon(CupertinoIcons.arrow_down_to_line, size: 14, color: darkText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildDownloadTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: darkText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10.5, color: mutedText),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.arrow_down_circle_fill, size: 18, color: Color(0xFF007AFF)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: darkText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: mutedText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, size: 16, color: Color(0xFFC7C7CC)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildTextCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: darkText),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF4B5563), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _DatasetViewerSheet extends StatefulWidget {
  final BuildContext sheetContext;

  const _DatasetViewerSheet({required this.sheetContext});

  @override
  State<_DatasetViewerSheet> createState() => _DatasetViewerSheetState();
}

class _DatasetViewerSheetState extends State<_DatasetViewerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _allRows = [];
  List<String> _filteredRows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRows();
    _searchCtrl.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onFilterChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRows() async {
    try {
      final raw = await AcademicReferenceHelper.loadDatasetString();
      final lines = raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() {
          _allRows = lines;
          _filteredRows = lines;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onFilterChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredRows = _allRows;
      } else {
        _filteredRows = _allRows.where((r) => r.toLowerCase().contains(q)).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.96,
          builder: (ctx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dataset Transaksi Groceries',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AcademicReferenceHelper.darkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total ${_allRows.length} Transaksi Riil Swalayan',
                          style: const TextStyle(fontSize: 12, color: AcademicReferenceHelper.mutedText),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(widget.sheetContext).pop(),
                      icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Color(0xFF8E8E93), size: 28),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: AcademicReferenceHelper.gunadarmaPurple,
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () => AcademicReferenceHelper.downloadDatasetCsv(context),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.arrow_down_doc_fill, size: 15, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Unduh File CSV',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () => AcademicReferenceHelper.copyDatasetCsv(context),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.doc_on_clipboard, size: 15, color: AcademicReferenceHelper.gunadarmaPurple),
                            SizedBox(width: 6),
                            Text(
                              'Salin Semua Baris',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AcademicReferenceHelper.gunadarmaPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                      onPressed: () => AcademicReferenceHelper.safeLaunchUrl(
                        context,
                        AcademicReferenceHelper.kaggleDatasetUrl,
                      ),
                      child: const Icon(CupertinoIcons.arrow_up_right_square, size: 16, color: Color(0xFF007AFF)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CupertinoSearchTextField(
                  controller: _searchCtrl,
                  placeholder: 'Cari transaksi berdasarkan nama produk...',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menampilkan ${_filteredRows.length} dari ${_allRows.length} baris',
                      style: const TextStyle(fontSize: 11, color: AcademicReferenceHelper.mutedText),
                    ),
                    const Text(
                      'Format: CSV Item-separated',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AcademicReferenceHelper.mutedText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : _filteredRows.isEmpty
                        ? const Center(
                            child: Text(
                              'Tidak ada transaksi yang cocok.',
                              style: TextStyle(color: AcademicReferenceHelper.mutedText),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: _filteredRows.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final rowText = _filteredRows[idx];
                              final items = rowText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '#${idx + 1}',
                                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: items.map((it) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3E8FF),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFE9D5FF), width: 0.8),
                                            ),
                                            child: Text(
                                              it,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AcademicReferenceHelper.gunadarmaPurple,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
        ),
      ),
    );
  }
}
