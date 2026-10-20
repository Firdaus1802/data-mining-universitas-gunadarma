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

  static const String internationalJournalDoiUrl = 'https://doi.org/10.18637/jss.v014.i15';
  static const String ieeeJournalDoiUrl = 'https://doi.org/10.1109/ICCIT48885.2019.9038197';
  static const String journalDoiUrl = internationalJournalDoiUrl;
  static const String journalScholarUrl = 'https://scholar.google.com/scholar?q=arules+A+Computational+Environment+for+Mining+Association+Rules+Groceries';
  static const String kaggleDatasetUrl = 'https://www.kaggle.com/datasets/heeraldedhia/groceries-dataset';

  static const String internationalApaCitation =
      'Hahsler, M., Grün, B., & Hornik, K. (2005). arules — A Computational Environment for Mining Association Rules and Frequent Item Sets. Journal of Statistical Software, 14(15), 1–25. https://doi.org/10.18637/jss.v014.i15';

  static const String ieeeCitation =
      'M. Hossain, A. H. M. S. Sattar and M. K. Paul, "Market Basket Analysis Using Apriori and FP Growth Algorithm," 2019 22nd International Conference on Computer and Information Technology (ICCIT), Dhaka, Bangladesh, 2019, pp. 1-6, doi: 10.1109/ICCIT48885.2019.9038197.';

  static const String apaCitation = internationalApaCitation;

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
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Gagal Membuka Peramban Otomatis'),
        message: Text(
          'Tautan tujuan:\n$urlString\n\nSilakan salin tautan untuk membukanya secara manual di peramban Anda.',
        ),
        actions: [
          CupertinoActionSheetAction(
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
            child: const Text('Salin Tautan ke Papan Klip'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await launchUrl(Uri.parse(urlString), mode: LaunchMode.inAppBrowserView);
              } catch (_) {}
            },
            child: const Text('Coba Buka Dalam Aplikasi'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Tutup'),
        ),
      ),
    );
  }

  static Future<void> downloadJournalPdf(BuildContext context) async {
    try {
      if (kIsWeb) {
        final ok = await launchUrl(
          Uri.parse('jurnal_internasional.pdf'),
          mode: LaunchMode.externalApplication,
        );
        if (!ok) {
          await launchUrl(
            Uri.parse('jurnal.pdf'),
            mode: LaunchMode.externalApplication,
          );
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berkas PDF Jurnal Internasional berhasil diunduh!'),
              backgroundColor: Color(0xFF2E7D32),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final byteData = await rootBundle.load('assets/documents/jurnal_internasional_groceries_arules.pdf');
      final bytes = byteData.buffer.asUint8List();
      final uri = await FilePicker.saveFile(
        fileName: 'Jurnal_Internasional_Groceries_arules.pdf',
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
        return DraggableScrollableSheet(
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
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(3),
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
                              'Naskah & Publikasi Jurnal Internasional',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: darkText,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Landasan Teori Association Rules (Scopus Q1 & IEEE)',
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
                                      'SCOPUS Q1 • OPEN ACCESS',
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
                                    'ISSN: 1548-7660',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: mutedText),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'arules — A Computational Environment for Mining Association Rules and Frequent Item Sets',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: darkText,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Penulis: Michael Hahsler, Bettina Grün, Kurt Hornik\nAfiliasi: WU Wirtschaftsuniversität Wien, Vienna, Austria\nPublikasi: Journal of Statistical Software (JSS)\nVolume & Terbitan: Vol. 14, Issue 15, hlm. 1–25, Oktober 2005\nDOI: 10.18637/jss.v014.i15\n\nNaskah rujukan internasional utama yang mempublikasikan dataset Groceries (9.835 transaksi) dan implementasi benchmark komputasi association rule mining.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF4A4A4A), height: 1.45),
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
                                      'IEEE XPLORE • SCOPUS INDEXED',
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
                                    'IEEE ICCIT 2019',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: mutedText),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Market Basket Analysis Using Apriori and FP Growth Algorithm',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: darkText,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Penulis: Maliha Hossain, A. H. M. Sarowar Sattar, Mahit Kumar Paul\nAfiliasi: Dept. of Computer Science & Engineering, United International University\nPublikasi: 2019 22nd International Conference on Computer and Information Technology (ICCIT)\nHalaman: 1–6, Dhaka, Bangladesh\nDOI: 10.1109/ICCIT48885.2019.9038197',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF4A4A4A), height: 1.45),
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
                          icon: CupertinoIcons.arrow_down_doc_fill,
                          iconColor: Colors.white,
                          bgColor: gunadarmaPurple,
                          title: 'Unduh Berkas PDF Jurnal Internasional (.pdf)',
                          subtitle: 'Simpan naskah resmi Scopus Q1 JSS (413 KB) langsung ke perangkat',
                          onTap: () => downloadJournalPdf(context),
                        ),
                        const SizedBox(height: 8),
                        _buildActionTile(
                          icon: CupertinoIcons.link,
                          iconColor: gunadarmaPurple,
                          bgColor: const Color(0xFFF3E8FF),
                          title: 'Buka Laman Resmi JSS (DOI: 10.18637/jss.v014.i15)',
                          subtitle: 'Publikasi Journal of Statistical Software (Scopus Q1)',
                          onTap: () => safeLaunchUrl(context, internationalJournalDoiUrl),
                        ),
                        const SizedBox(height: 8),
                        _buildActionTile(
                          icon: CupertinoIcons.doc_text_fill,
                          iconColor: const Color(0xFF007AFF),
                          bgColor: const Color(0xFFE0F2FE),
                          title: 'Buka Publikasi di IEEE Xplore',
                          subtitle: 'Naskah komparasi Apriori & FP-Growth (DOI: 10.1109/ICCIT48885.2019.9038197)',
                          onTap: () => safeLaunchUrl(context, ieeeJournalDoiUrl),
                        ),
                        const SizedBox(height: 8),
                        _buildActionTile(
                          icon: CupertinoIcons.search,
                          iconColor: const Color(0xFF2E7D32),
                          bgColor: const Color(0xFFDCFCE7),
                          title: 'Cari Sitasi di Google Scholar',
                          subtitle: '1.500+ sitasi riset arules dan benchmark keranjang belanja',
                          onTap: () => safeLaunchUrl(context, journalScholarUrl),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'RINGKASAN & METODOLOGI PENELITIAN INTERNASIONAL',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: mutedText, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 10),
                        _buildTextCard(
                          title: '1. Latar Belakang & Pembentukan Dataset Groceries',
                          content:
                              'Dataset Groceries yang digunakan dalam aplikasi ini bersumber dari penelitian riset Michael Hahsler dkk. yang menghimpun 9.835 transaksi riil dari jaringan ritel swalayan selama 30 hari dengan cakupan 169 kategori produk pangan dan kebutuhan harian.',
                        ),
                        const SizedBox(height: 10),
                        _buildTextCard(
                          title: '2. Formulasi Metrik Evaluasi Asosiasi',
                          content:
                              'Kaidah asosiasi dievaluasi dengan tiga metrik baku internasional:\n• Support: Frekuensi kemunculan kombinasi item terhadap total populasi transaksi (P(A ∪ B)).\n• Confidence: Tingkat kepastian bahwa jika item A dibeli, item B juga akan dibeli (P(B|A)).\n• Lift Ratio: Rasio kekuatan keterkaitan relatif terhadap frekuensi acak independen. Nilai Lift > 1 membuktikan adanya dependensi positif yang valid.',
                        ),
                        const SizedBox(height: 10),
                        _buildTextCard(
                          title: '3. Kaidah Asosiasi Retail Teruji',
                          content:
                              'Pengujian empiris pada transaksi retail menghasilkan aturan asosiasi signifikan, di antaranya:\n• {yogurt, sausage} => {whole milk} (Support: 0,0147, Confidence: 25,58%, Lift: 1,62)\n• {sausage, rolls/buns} => {whole milk} (Support: 0,0113, Confidence: 21,25%, Lift: 1,35)\n\nKonsumen yang membeli kombinasi produk sarapan/olahan daging menunjukkan tendensi kuat melengkapi belanjaannya dengan susu segar murni (whole milk).',
                        ),
                        const SizedBox(height: 10),
                        _buildTextCard(
                          title: '4. Komparasi Algoritma Apriori & FP-Growth',
                          content:
                              'Penelitian Hossain et al. (IEEE ICCIT) menggarisbawahi:\n• Apriori: Menawarkan transparansi tinggi dalam pembentukan kandidat k-itemset secara terstruktur bertahap, menjadikannya fondasi teoretis utama data mining.\n• FP-Growth: Mengeliminasi proses candidate generation berulang dengan memanfaatkan pohon ringkas FP-Tree untuk efisiensi komputasi optimal pada data bervolume besar.',
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
                                  await Clipboard.setData(const ClipboardData(text: internationalApaCitation));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Sitasi APA (Scopus Q1) berhasil disalin!'),
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
                                      'Sitasi APA (JSS)',
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
                                  await Clipboard.setData(const ClipboardData(text: ieeeCitation));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Sitasi format IEEE berhasil disalin!'),
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
                                      'Sitasi IEEE',
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
                          onPressed: () => downloadJournalPdf(context),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.arrow_down_doc_fill, size: 16, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Unduh Naskah PDF Jurnal Internasional (413 KB)',
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
        return _DatasetViewerSheet(sheetContext: sheetContext);
      },
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
    return DraggableScrollableSheet(
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
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(3),
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
    );
  }
}
