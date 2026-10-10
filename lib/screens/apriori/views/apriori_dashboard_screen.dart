import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop/models/apriori_state_manager.dart';

class AprioriDashboardScreen extends StatefulWidget {
  const AprioriDashboardScreen({super.key});

  @override
  State<AprioriDashboardScreen> createState() => _AprioriDashboardScreenState();
}

class _AprioriDashboardScreenState extends State<AprioriDashboardScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _selectedSegment = 0;
  double _minSupport = 10.0;
  double _minConfidence = 50.0;

  final List<List<String>> _transactions = [];
  final List<String> _currentBasket = [];
  final TextEditingController _customItemCtrl = TextEditingController();
  final TextEditingController _csvImportCtrl = TextEditingController();

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  static const Color gunadarmaPurple = Color(0xFF2E1065);
  static const Color accentPurple = Color(0xFF5856D6);
  static const Color cardBorder = Color(0xFFE5E5EA);
  static const Color iosBg = Color(0xFFF2F2F7);
  static const Color darkText = Color(0xFF1C1C1E);
  static const Color mutedText = Color(0xFF8E8E93);

  @override
  void initState() {
    super.initState();
    if (AprioriStateManager.instance.transactions.isNotEmpty) {
      _transactions.clear();
      _transactions.addAll(AprioriStateManager.instance.transactions);
      _minSupport = AprioriStateManager.instance.minSupport;
      _minConfidence = AprioriStateManager.instance.minConfidence;
    }
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _customItemCtrl.dispose();
    _csvImportCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFileFromDevice() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.any,
      );

      if (picked != null) {
        String content = '';
        try {
          final bytes = await picked.readAsBytes();
          if (bytes.isNotEmpty) {
            content = utf8.decode(bytes, allowMalformed: true);
          }
        } catch (_) {}

        if (content.isEmpty && picked.path != null && picked.path!.isNotEmpty) {
          final file = File(picked.path!);
          if (await file.exists()) {
            content = await file.readAsString();
          }
        }

        if (content.trim().isNotEmpty) {
          _processCsvImport(content, overwrite: true);
          _showIOSNotification('File "${picked.name}" berhasil diimpor (${_transactions.length} transaksi).');
        } else {
          _showIOSNotification('File kosong atau format tidak terbaca.', isError: true);
        }
      }
    } catch (e) {
      _showIOSNotification('Gagal memilih file: $e', isError: true);
    }
  }

  void _addItemToBasket(String item) {
    final trimmed = item.trim();
    if (trimmed.isEmpty) return;
    if (!_currentBasket.contains(trimmed)) {
      setState(() {
        _currentBasket.add(trimmed);
        _customItemCtrl.clear();
      });
    } else {
      _showIOSNotification('Item sudah ada di keranjang aktif.');
    }
  }

  void _removeItemFromBasket(String item) {
    setState(() {
      _currentBasket.remove(item);
    });
  }

  void _syncState() {
    final result = _calculateApriori();
    AprioriStateManager.instance.updateAll(
      transactions: _transactions,
      rulesCount: result.rules.length,
      minSupport: _minSupport,
      minConfidence: _minConfidence,
      rules: result.rules
          .map((r) => AprioriRuleSummary(
                antecedent: r.antecedent,
                consequent: r.consequent,
                confidence: r.confidence,
                support: r.support,
                lift: r.lift,
              ))
          .toList(),
    );
  }

  void _saveTransaction() {
    if (_currentBasket.isEmpty) {
      _showIOSNotification('Pilih atau ketik minimal 1 item belanjaan.', isError: true);
      return;
    }

    setState(() {
      _transactions.add(List<String>.from(_currentBasket));
      _currentBasket.clear();
      _customItemCtrl.clear();
    });
    _syncState();
    _showIOSNotification('Struk #${_transactions.length} berhasil disimpan.');
  }

  void _deleteTransaction(int index) {
    setState(() {
      _transactions.removeAt(index);
    });
    _syncState();
    _showIOSNotification('Struk #${index + 1} berhasil dihapus.');
  }

  void _resetAllData() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Reset Dataset'),
        content: const Text('Apakah Anda yakin ingin mengosongkan seluruh dataset transaksi yang tersimpan?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _transactions.clear();
                _currentBasket.clear();
                _customItemCtrl.clear();
              });
              _syncState();
              _showIOSNotification('Dataset berhasil dikosongkan.');
            },
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  void _openCsvImportSheet() {
    _csvImportCtrl.clear();
    bool overwriteExisting = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final rawText = _csvImportCtrl.text;
          final lines = rawText.split('\n').where((l) => l.trim().isNotEmpty).toList();
          final hasSemicolon = rawText.contains(';');
          final hasComma = rawText.contains(',');

          String formatLabel = 'Format Belum Terdeteksi';
          Color formatBadgeColor = mutedText;

          if (rawText.isNotEmpty) {
            if (hasSemicolon && !hasComma) {
              formatLabel = 'CDV (Titik Koma ;)';
              formatBadgeColor = gunadarmaPurple;
            } else if (hasComma && !hasSemicolon) {
              formatLabel = 'CSV (Koma ,)';
              formatBadgeColor = const Color(0xFF007AFF);
            } else {
              formatLabel = 'Teks Terdeteksi';
              formatBadgeColor = accentPurple;
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D1D6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Input & Tempel Dataset',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: formatBadgeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            formatLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: formatBadgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          color: iosBg,
                          borderRadius: BorderRadius.circular(8),
                          onPressed: () async {
                            final data = await Clipboard.getData(Clipboard.kTextPlain);
                            if (data != null && data.text != null && data.text!.isNotEmpty) {
                              setModalState(() {
                                _csvImportCtrl.text = data.text!;
                              });
                            } else {
                              _showIOSNotification('Papan klip kosong.', isError: true);
                            }
                          },
                          child: const Text(
                            'Tempel dari Clipboard',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: gunadarmaPurple),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (rawText.isNotEmpty)
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            color: iosBg,
                            borderRadius: BorderRadius.circular(8),
                            onPressed: () {
                              setModalState(() {
                                _csvImportCtrl.clear();
                              });
                            },
                            child: const Text(
                              'Hapus',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFF3B30)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: iosBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: TextField(
                        controller: _csvImportCtrl,
                        maxLines: 7,
                        onChanged: (_) => setModalState(() {}),
                        style: const TextStyle(fontSize: 12, height: 1.4, color: darkText),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Tempel teks transaksi di sini...\nContoh:\nKopi, Gula, Susu\nRoti, Mentega, Cokelat\nKopi, Susu',
                          hintStyle: TextStyle(fontSize: 12, color: Color(0xFFAFAFB4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CupertinoSwitch(
                          value: overwriteExisting,
                          activeTrackColor: gunadarmaPurple,
                          onChanged: (v) {
                            setModalState(() {
                              overwriteExisting = v;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            overwriteExisting
                                ? 'Gantikan seluruh dataset yang ada'
                                : 'Tambahkan ke dataset saat ini',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: darkText),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: gunadarmaPurple,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: rawText.trim().isEmpty
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _processCsvImport(rawText, overwrite: overwriteExisting);
                              },
                        child: Text(
                          'Proses Data (${lines.length} Baris)',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _processCsvImport(String rawText, {bool overwrite = true}) {
    if (rawText.trim().isEmpty) {
      _showIOSNotification('Teks input kosong. Silakan pilih atau tempel berkas transaksi.', isError: true);
      return;
    }

    final rawLines = rawText.split(RegExp(r'\r?\n'));
    final List<List<String>> parsedTransactions = [];
    bool skippedHeader = false;

    for (int i = 0; i < rawLines.length; i++) {
      String line = rawLines[i].trim();
      if (line.isEmpty) continue;

      if (i == 0) {
        final lower = line.toLowerCase();
        if (lower.contains('transaksi') ||
            lower.contains('transaction') ||
            lower.contains('item') ||
            lower.contains('struk') ||
            lower.contains('tid') ||
            lower.contains('barang') ||
            lower.contains('produk') ||
            lower.contains('receipt') ||
            lower.contains('order') ||
            lower.contains('daftar')) {
          skippedHeader = true;
          continue;
        }
      }

      if (line.contains(':') && !line.startsWith('{')) {
        final colonIdx = line.indexOf(':');
        if (colonIdx > 0 && colonIdx < line.length - 1) {
          final prefix = line.substring(0, colonIdx).trim().toLowerCase();
          if (prefix.contains('trx') ||
              prefix.contains('t') ||
              prefix.contains('struk') ||
              RegExp(r'^\d+$').hasMatch(prefix)) {
            line = line.substring(colonIdx + 1).trim();
          }
        }
      }

      final countSemicolon = ';'.allMatches(line).length;
      final countComma = ','.allMatches(line).length;
      final countTab = '\t'.allMatches(line).length;
      final countPipe = '|'.allMatches(line).length;

      Pattern delimiter = ',';
      if (countSemicolon >= countComma && countSemicolon >= countTab && countSemicolon >= countPipe && countSemicolon > 0) {
        delimiter = ';';
      } else if (countTab > countComma && countTab > countSemicolon && countTab > countPipe) {
        delimiter = '\t';
      } else if (countPipe > countComma && countPipe > countSemicolon && countPipe > countTab) {
        delimiter = '|';
      } else if (countComma > 0) {
        delimiter = ',';
      }

      final rawTokens = line.split(delimiter);
      final List<String> cleanItems = [];

      for (int tIdx = 0; tIdx < rawTokens.length; tIdx++) {
        String token = rawTokens[tIdx].trim();
        token = token.replaceAll(RegExp(r'''^["'(\[\{]+|["')\]\}]+$'''), '').trim();

        if (token.isEmpty) continue;

        if (tIdx == 0 && rawTokens.length > 1) {
          if (RegExp(r'^(T\d+|TRX\d*|NO\.?\s*\d+|\d+|#\d+)$', caseSensitive: false).hasMatch(token)) {
            continue;
          }
        }

        if (token.isNotEmpty && !cleanItems.contains(token)) {
          cleanItems.add(token);
        }
      }

      if (cleanItems.isNotEmpty) {
        parsedTransactions.add(cleanItems);
      }
    }

    if (parsedTransactions.isEmpty) {
      _showIOSNotification('Format berkas tidak valid. Pastikan data memuat daftar barang.', isError: true);
      return;
    }

    setState(() {
      if (overwrite) {
        _transactions.clear();
      }
      _transactions.addAll(parsedTransactions);
      _currentBasket.clear();
    });
    _syncState();

    final msg = overwrite
        ? '${parsedTransactions.length} transaksi berhasil dimuat ke dataset.'
        : '${parsedTransactions.length} transaksi baru ditambahkan ke dataset.';
    _showIOSNotification(msg + (skippedHeader ? ' (Header dilewati)' : ''));
  }

  void _showIOSNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? const Color(0xFFFF3B30) : const Color(0xFF1C1C1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  _AprioriResult _calculateApriori() {
    final int totalTrans = _transactions.length;
    if (totalTrans == 0) {
      return const _AprioriResult(
        totalTransactions: 0,
        uniqueItemCount: 0,
        frequentItemCount: 0,
        itemFrequencies: [],
        rules: [],
      );
    }

    final Map<String, int> itemCounts = {};
    for (final trans in _transactions) {
      for (final item in trans.toSet()) {
        itemCounts[item] = (itemCounts[item] ?? 0) + 1;
      }
    }

    final List<_ItemFreq> itemFrequencies = itemCounts.entries.map((e) {
      final double pct = (e.value / totalTrans) * 100.0;
      return _ItemFreq(name: e.key, count: e.value, percent: pct);
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final int frequentItemCount = itemFrequencies.where((i) => i.percent >= _minSupport).length;

    final Map<String, int> pairCounts = {};
    for (final trans in _transactions) {
      final list = trans.toSet().toList();
      for (int i = 0; i < list.length; i++) {
        for (int j = i + 1; j < list.length; j++) {
          final a = list[i];
          final b = list[j];
          final key = a.compareTo(b) < 0 ? '$a|||$b' : '$b|||$a';
          pairCounts[key] = (pairCounts[key] ?? 0) + 1;
        }
      }
    }

    final List<_LiveRule> rules = [];
    pairCounts.forEach((key, countBoth) {
      final parts = key.split('|||');
      final itemA = parts[0];
      final itemB = parts[1];

      final countA = itemCounts[itemA] ?? 1;
      final countB = itemCounts[itemB] ?? 1;

      final double supportBoth = (countBoth / totalTrans) * 100.0;

      final double confAtoB = (countBoth / countA) * 100.0;
      final double suppB = (countB / totalTrans) * 100.0;
      final double liftAtoB = suppB > 0 ? (confAtoB / suppB) : 0.0;

      if (supportBoth >= _minSupport && confAtoB >= _minConfidence) {
        rules.add(_LiveRule(
          antecedent: itemA,
          consequent: itemB,
          confidence: confAtoB,
          support: supportBoth,
          lift: liftAtoB,
        ));
      }

      final double confBtoA = (countBoth / countB) * 100.0;
      final double suppA = (countA / totalTrans) * 100.0;
      final double liftBtoA = suppA > 0 ? (confBtoA / suppA) : 0.0;

      if (supportBoth >= _minSupport && confBtoA >= _minConfidence) {
        rules.add(_LiveRule(
          antecedent: itemB,
          consequent: itemA,
          confidence: confBtoA,
          support: supportBoth,
          lift: liftBtoA,
        ));
      }
    });

    rules.sort((a, b) {
      final cmp = b.confidence.compareTo(a.confidence);
      if (cmp != 0) return cmp;
      return b.lift.compareTo(a.lift);
    });

    return _AprioriResult(
      totalTransactions: totalTrans,
      uniqueItemCount: itemCounts.keys.length,
      frequentItemCount: frequentItemCount,
      itemFrequencies: itemFrequencies,
      rules: rules,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final aprioriResult = _calculateApriori();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AprioriStateManager.instance.updateParameters(_minSupport, _minConfidence);
      AprioriStateManager.instance.setRulesCount(aprioriResult.rules.length);
      AprioriStateManager.instance.setTransactions(_transactions);
    });

    return Scaffold(
      backgroundColor: iosBg,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dataset & Algoritma Apriori',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pusat Manajemen Transaksi & Aturan Asosiasi',
                          style: TextStyle(
                            fontSize: 12,
                            color: mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (_transactions.isNotEmpty)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _resetAllData,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Kosongkan',
                            style: TextStyle(
                              color: Color(0xFFFF3B30),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedSegment,
                  backgroundColor: const Color(0xFFE5E5EA),
                  thumbColor: Colors.white,
                  padding: const EdgeInsets.all(4),
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Kelola Dataset (${_transactions.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedSegment == 0 ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedSegment == 0 ? gunadarmaPurple : mutedText,
                        ),
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Hasil & Aturan Apriori (${aprioriResult.rules.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedSegment == 1 ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedSegment == 1 ? gunadarmaPurple : mutedText,
                        ),
                      ),
                    ),
                  },
                  onValueChanged: (v) {
                    if (v != null) {
                      setState(() => _selectedSegment = v);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedSegment == 0) ...[
                _buildImportActionCard(),
                const SizedBox(height: 14),
                _buildManualBasketCard(),
                const SizedBox(height: 14),
                _buildDatasetStatsRow(aprioriResult),
                const SizedBox(height: 14),
                _buildTransactionListSection(),
              ] else ...[
                _buildParameterCard(),
                const SizedBox(height: 14),
                _buildExecutiveMetrics(aprioriResult),
                const SizedBox(height: 14),
                _buildItemFrequencyDistribution(aprioriResult),
                const SizedBox(height: 14),
                _buildAssociationRulesSection(aprioriResult),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildImportActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Unggah File Dataset Transaksi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'CSV / CDV / TXT',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: mutedText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Impor berkas transaksi dari penyimpanan HP Anda untuk diproses oleh algoritma Apriori secara realtime.',
            style: TextStyle(
              fontSize: 11.5,
              color: mutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: gunadarmaPurple,
              borderRadius: BorderRadius.circular(14),
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: _pickFileFromDevice,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.folder_badge_plus, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Pilih Berkas dari HP',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: iosBg,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(vertical: 11),
              onPressed: _openCsvImportSheet,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.doc_on_clipboard, size: 15, color: gunadarmaPurple),
                  SizedBox(width: 6),
                  Text(
                    'Tempel Teks / Manual',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: gunadarmaPurple,
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

  Widget _buildDatasetStatsRow(_AprioriResult res) {
    final double avgItems = _transactions.isEmpty
        ? 0.0
        : _transactions.map((t) => t.length).reduce((a, b) => a + b) / _transactions.length;

    return Row(
      children: [
        Expanded(
          child: _buildSimpleStatCard(
            label: 'TOTAL STRUK',
            value: '${_transactions.length}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSimpleStatCard(
            label: 'ITEM UNIK',
            value: '${res.uniqueItemCount}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSimpleStatCard(
            label: 'RATA-RATA/STRUK',
            value: avgItems.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleStatCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: mutedText,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: darkText,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionListSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Struk Transaksi (${_transactions.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              if (_transactions.isNotEmpty)
                GestureDetector(
                  onTap: _resetAllData,
                  child: const Text(
                    'Hapus Semua',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_transactions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: iosBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Text(
                    'Belum Ada Berkas Transaksi',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pilih berkas dari memori HP atau tempel teks transaksi di atas.',
                    style: TextStyle(fontSize: 11, color: mutedText),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length > 25 ? 25 : _transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final trans = _transactions[idx];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: iosBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${idx + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: gunadarmaPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: trans.map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: darkText),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _deleteTransaction(idx),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(CupertinoIcons.trash, size: 14, color: mutedText),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (_transactions.length > 25) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Menampilkan 25 dari ${_transactions.length} transaksi total',
                style: const TextStyle(fontSize: 10.5, color: mutedText, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManualBasketCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Input Struk Tunggal (Manual)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: iosBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: _customItemCtrl,
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) _addItemToBasket(v);
                    },
                    style: const TextStyle(fontSize: 12, color: darkText),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Ketik nama item...',
                      hintStyle: TextStyle(fontSize: 11.5, color: mutedText),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                color: gunadarmaPurple,
                borderRadius: BorderRadius.circular(10),
                onPressed: () => _addItemToBasket(_customItemCtrl.text),
                child: const Text('Tambah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          if (_currentBasket.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _currentBasket.map((it) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(it, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: gunadarmaPurple)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeItemFromBasket(it),
                        child: const Icon(CupertinoIcons.clear, size: 10, color: gunadarmaPurple),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: accentPurple,
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.symmetric(vertical: 10),
                onPressed: _saveTransaction,
                child: const Text('Simpan Struk ke Dataset', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParameterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ambang Batas Minimum Support',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: darkText),
              ),
              Text(
                '${_minSupport.toInt()}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: gunadarmaPurple),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlider(
              value: _minSupport.clamp(1.0, 100.0),
              min: 1.0,
              max: 100.0,
              divisions: 99,
              activeColor: gunadarmaPurple,
              onChanged: (val) {
                setState(() => _minSupport = val);
                _syncState();
              },
            ),
          ),
          const Divider(height: 16, color: cardBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ambang Batas Minimum Confidence',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: darkText),
              ),
              Text(
                '${_minConfidence.toInt()}%',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: gunadarmaPurple),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlider(
              value: _minConfidence.clamp(1.0, 100.0),
              min: 1.0,
              max: 100.0,
              divisions: 99,
              activeColor: gunadarmaPurple,
              onChanged: (val) {
                setState(() => _minConfidence = val);
                _syncState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveMetrics(_AprioriResult res) {
    return Row(
      children: [
        Expanded(
          child: _buildSimpleStatCard(
            label: 'FREQUENT ITEMSETS',
            value: '${res.frequentItemCount}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSimpleStatCard(
            label: 'ATURAN VALID',
            value: '${res.rules.length}',
          ),
        ),
      ],
    );
  }

  Widget _buildItemFrequencyDistribution(_AprioriResult res) {
    final topItems = res.itemFrequencies.take(6).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribusi Frekuensi Item Teratas (L1)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: darkText),
          ),
          const SizedBox(height: 12),
          if (topItems.isEmpty)
            const Text('Belum ada data item.', style: TextStyle(fontSize: 11, color: mutedText))
          else
            ...topItems.map((item) {
              final isAbove = item.percent >= _minSupport;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        item.name,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: darkText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (item.percent / 100.0).clamp(0.0, 1.0),
                          backgroundColor: iosBg,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isAbove ? gunadarmaPurple : mutedText.withValues(alpha: 0.4),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${item.percent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isAbove ? gunadarmaPurple : mutedText,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAssociationRulesSection(_AprioriResult res) {
    final rules = res.rules;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Aturan Asosiasi (Apriori Rules)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: darkText),
              ),
              Text(
                '${rules.length} Aturan',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: gunadarmaPurple),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rules.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Center(
                child: Text(
                  'Belum ada aturan yang memenuhi ambang batas minimum.',
                  style: TextStyle(fontSize: 11.5, color: mutedText),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rules.length > 20 ? 20 : rules.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 0.5,
                color: cardBorder,
              ),
              itemBuilder: (ctx, idx) {
                final r = rules[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    r.antecedent,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: darkText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    CupertinoIcons.arrow_right,
                                    size: 11,
                                    color: mutedText,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    r.consequent,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: gunadarmaPurple,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Support: ${r.support.toStringAsFixed(1)}%   •   Confidence: ${r.confidence.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lift ${r.lift.toStringAsFixed(2)}x',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AprioriResult {
  final int totalTransactions;
  final int uniqueItemCount;
  final int frequentItemCount;
  final List<_ItemFreq> itemFrequencies;
  final List<_LiveRule> rules;

  const _AprioriResult({
    required this.totalTransactions,
    required this.uniqueItemCount,
    required this.frequentItemCount,
    required this.itemFrequencies,
    required this.rules,
  });
}

class _ItemFreq {
  final String name;
  final int count;
  final double percent;

  const _ItemFreq({
    required this.name,
    required this.count,
    required this.percent,
  });
}

class _LiveRule {
  final String antecedent;
  final String consequent;
  final double confidence;
  final double support;
  final double lift;

  const _LiveRule({
    required this.antecedent,
    required this.consequent,
    required this.confidence,
    required this.support,
    required this.lift,
  });
}
