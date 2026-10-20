import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop/models/apriori_state_manager.dart';
import 'package:shop/screens/apriori/views/academic_reference_helper.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _showOnlyL1 = false;
  int _scenarioIndex = 0;
  bool _viewingTestSet = false;
  int _rulesCurrentPage = 0;
  static const int _rulesPerPage = 10;
  int _transCurrentPage = 0;
  static const int _transPerPage = 10;

  final List<List<String>> _masterTransactions = [];
  final List<List<String>> _transactions = [];
  final List<List<String>> _testTransactions = [];
  final List<String> _currentBasket = [];
  final TextEditingController _customItemCtrl = TextEditingController();
  final TextEditingController _csvImportCtrl = TextEditingController();

  int _lastCachedTransHash = 0;
  List<_ItemFreq> _cachedItemFrequencies = [];
  Map<String, int> _cachedItemCounts = {};
  List<_LiveRule> _cachedAllCandidateRules = [];
  int _cachedTotalTrans = 0;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  static const Color gunadarmaPurple = Color(0xFF581C87);
  static const Color accentPurple = Color(0xFF7E22CE);
  static const Color cardBorder = Color(0xFFEDE9FE);
  static const Color iosBg = Color(0xFFFBFBFE);
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color mutedText = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    final mgr = AprioriStateManager.instance;
    _scenarioIndex = mgr.scenarioIndex;
    _masterTransactions.clear();
    _masterTransactions.addAll(mgr.masterTransactions.isNotEmpty ? mgr.masterTransactions : mgr.transactions);
    if (_masterTransactions.length < 10) {
      AprioriStateManager.instance.resetToDefaultDataset().then((_) {
        if (mounted) {
          setState(() {
            _masterTransactions.clear();
            _masterTransactions.addAll(AprioriStateManager.instance.masterTransactions);
            _applyScenarioSplitLocal();
            _syncState();
          });
        }
      });
    }
    _transactions.clear();
    _transactions.addAll(mgr.transactions);
    _testTransactions.clear();
    _testTransactions.addAll(mgr.testTransactions);
    _minSupport = mgr.minSupport;
    _minConfidence = mgr.minConfidence;

    AprioriStateManager.instance.addListener(_onStateManagerUpdated);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  void _onStateManagerUpdated() {
    if (!mounted) return;
    final mgr = AprioriStateManager.instance;
    if (mgr.transactions.length != _transactions.length ||
        mgr.masterTransactions.length != _masterTransactions.length ||
        mgr.scenarioIndex != _scenarioIndex ||
        mgr.minSupport != _minSupport ||
        mgr.minConfidence != _minConfidence) {
      setState(() {
        _scenarioIndex = mgr.scenarioIndex;
        _masterTransactions.clear();
        _masterTransactions.addAll(mgr.masterTransactions.isNotEmpty ? mgr.masterTransactions : mgr.transactions);
        _transactions.clear();
        _transactions.addAll(mgr.transactions);
        _testTransactions.clear();
        _testTransactions.addAll(mgr.testTransactions);
        _minSupport = mgr.minSupport;
        _minConfidence = mgr.minConfidence;
      });
    }
  }

  void _onScenarioChanged(int? newIndex) {
    if (newIndex == null || newIndex == _scenarioIndex) return;
    if (_masterTransactions.length <= 1 && AprioriStateManager.instance.masterTransactions.length > 1) {
      _masterTransactions.clear();
      _masterTransactions.addAll(AprioriStateManager.instance.masterTransactions);
    }
    setState(() {
      _scenarioIndex = newIndex;
      _viewingTestSet = false;
      _applyScenarioSplitLocal();
    });
    _syncState();
    final String scenarioName = newIndex == 1
        ? 'Rasio 80:20 aktif (800 latih, 200 uji)'
        : newIndex == 2
            ? 'Rasio 70:30 aktif (700 latih, 300 uji)'
            : 'Data penuh (1.000 transaksi)';
    _showIOSNotification(scenarioName);
  }

  void _applyScenarioSplitLocal() {
    _transactions.clear();
    _testTransactions.clear();
    final total = _masterTransactions.length;
    if (total == 0) return;

    if (_scenarioIndex == 1) {
      final trainCount = (total * 0.8).round();
      _transactions.addAll(_masterTransactions.sublist(0, trainCount));
      _testTransactions.addAll(_masterTransactions.sublist(trainCount));
    } else if (_scenarioIndex == 2) {
      final trainCount = (total * 0.7).round();
      _transactions.addAll(_masterTransactions.sublist(0, trainCount));
      _testTransactions.addAll(_masterTransactions.sublist(trainCount));
    } else {
      _transactions.addAll(_masterTransactions);
    }
  }

  @override
  void dispose() {
    AprioriStateManager.instance.removeListener(_onStateManagerUpdated);
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
      masterTransactions: _masterTransactions,
      scenarioIndex: _scenarioIndex,
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
      _masterTransactions.insert(0, List<String>.from(_currentBasket));
      _currentBasket.clear();
      _customItemCtrl.clear();
      _applyScenarioSplitLocal();
    });
    _syncState();
    _showIOSNotification('Struk berhasil disimpan ke dataset master.');
  }

  void _deleteTransaction(int index) {
    setState(() {
      if (_viewingTestSet) {
        if (index >= 0 && index < _testTransactions.length) {
          final target = _testTransactions[index];
          _masterTransactions.remove(target);
        }
      } else {
        if (index >= 0 && index < _transactions.length) {
          final target = _transactions[index];
          _masterTransactions.remove(target);
        }
      }
      _applyScenarioSplitLocal();
    });
    _syncState();
    _showIOSNotification('Struk berhasil dihapus.');
  }

  void _resetAllData() {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Kelola Dataset'),
        content: const Text('Pilih aksi untuk mereset dataset transaksi Anda:'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(ctx);
              await AprioriStateManager.instance.resetToDefaultDataset();
              _showIOSNotification('Dataset 1.000 data bawaan berhasil dimuat.');
            },
            child: const Text('Muat Ulang 1.000 Data'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _masterTransactions.clear();
                _transactions.clear();
                _testTransactions.clear();
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

  Widget _buildCsvImportSheetContent(
    BuildContext ctx,
    StateSetter setModalState,
    bool overwriteExisting,
    ValueChanged<bool> onOverwriteChanged,
  ) {
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onChanged: onOverwriteChanged,
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
    );
  }

  void _openCsvImportSheet() {
    _csvImportCtrl.clear();
    bool overwriteExisting = true;
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 30,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: _buildCsvImportSheetContent(
                      dialogCtx,
                      setModalState,
                      overwriteExisting,
                      (v) => setModalState(() => overwriteExisting = v),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
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
                    _buildCsvImportSheetContent(
                      ctx,
                      setModalState,
                      overwriteExisting,
                      (v) => setModalState(() => overwriteExisting = v),
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
        _masterTransactions.clear();
      }
      _masterTransactions.addAll(parsedTransactions);
      _currentBasket.clear();
      _applyScenarioSplitLocal();
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

  void _ensureDatasetMined() {
    final int currentHash = Object.hashAll([
      _transactions.length,
      if (_transactions.isNotEmpty) _transactions.first.length,
      if (_transactions.isNotEmpty) _transactions.last.length,
    ]);
    if (_lastCachedTransHash == currentHash && _cachedItemFrequencies.isNotEmpty) {
      return;
    }
    _lastCachedTransHash = currentHash;
    _cachedTotalTrans = _transactions.length;
    if (_cachedTotalTrans == 0) return;

    final Map<String, int> itemCounts = {};
    for (final trans in _transactions) {
      for (final item in trans.toSet()) {
        itemCounts[item] = (itemCounts[item] ?? 0) + 1;
      }
    }

    _cachedItemCounts = itemCounts;
    _cachedItemFrequencies = itemCounts.entries.map((e) {
      final double pct = (e.value / _cachedTotalTrans) * 100.0;
      return _ItemFreq(name: e.key, count: e.value, percent: pct);
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

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

    final List<_LiveRule> candidates = [];
    pairCounts.forEach((key, countBoth) {
      final parts = key.split('|||');
      final itemA = parts[0];
      final itemB = parts[1];

      final countA = itemCounts[itemA] ?? 1;
      final countB = itemCounts[itemB] ?? 1;

      final double supportBoth = (countBoth / _cachedTotalTrans) * 100.0;
      final double confAtoB = (countBoth / countA) * 100.0;
      final double suppB = (countB / _cachedTotalTrans) * 100.0;
      final double liftAtoB = suppB > 0 ? (confAtoB / suppB) : 0.0;

      candidates.add(_LiveRule(
        antecedent: itemA,
        consequent: itemB,
        confidence: confAtoB,
        support: supportBoth,
        lift: liftAtoB,
      ));

      final double confBtoA = (countBoth / countB) * 100.0;
      final double suppA = (countA / _cachedTotalTrans) * 100.0;
      final double liftBtoA = suppA > 0 ? (confBtoA / suppA) : 0.0;

      candidates.add(_LiveRule(
        antecedent: itemB,
        consequent: itemA,
        confidence: confBtoA,
        support: supportBoth,
        lift: liftBtoA,
      ));
    });

    candidates.sort((a, b) {
      final cmp = b.confidence.compareTo(a.confidence);
      if (cmp != 0) return cmp;
      return b.lift.compareTo(a.lift);
    });

    _cachedAllCandidateRules = candidates;
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

    _ensureDatasetMined();

    final int frequentItemCount =
        _cachedItemFrequencies.where((i) => i.percent >= _minSupport).length;

    final List<_LiveRule> activeRules = _cachedAllCandidateRules
        .where((r) => r.support >= _minSupport && r.confidence >= _minConfidence)
        .toList();

    return _AprioriResult(
      totalTransactions: _cachedTotalTrans,
      uniqueItemCount: _cachedItemCounts.keys.length,
      frequentItemCount: frequentItemCount,
      itemFrequencies: _cachedItemFrequencies,
      rules: activeRules,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final aprioriResult = _calculateApriori();
    final bool isDesktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: iosBg,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dataset & Algoritma Apriori',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: darkText,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pengolahan Data Transaksi & Kaidah Asosiasi',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: mutedText,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showAcademicReferenceModal(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: gunadarmaPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.book_fill, size: 12, color: gunadarmaPurple),
                                SizedBox(width: 5),
                                Text(
                                  'Rujukan & Dataset',
                                  style: TextStyle(
                                    color: gunadarmaPurple,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_transactions.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _resetAllData,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Reset',
                                style: TextStyle(
                                  color: Color(0xFFFF3B30),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              Align(
                alignment: isDesktop ? Alignment.centerLeft : Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 480 : double.infinity),
                  child: SizedBox(
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
                ),
              ),
              const SizedBox(height: 14),
              if (isDesktop) ...[
                if (_selectedSegment == 0)
                  _buildDesktopDatasetView(aprioriResult)
                else
                  _buildDesktopAprioriView(aprioriResult),
              ] else ...[
                _buildScenarioSplitCard(),
                const SizedBox(height: 14),
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
            ],
          ),
        ),
      ),
    ),
  ),
),
);
  }

  Widget _buildDesktopDatasetView(_AprioriResult aprioriResult) {
    final double avgItems = _transactions.isEmpty
        ? 0.0
        : _transactions.map((t) => t.length).reduce((a, b) => a + b) / _transactions.length;

    String badgeLabel;
    if (_scenarioIndex == 1) {
      badgeLabel = 'Rasio 80 : 20';
    } else if (_scenarioIndex == 2) {
      badgeLabel = 'Rasio 70 : 30';
    } else {
      badgeLabel = '${_masterTransactions.length} Data Penuh';
    }

    final activeList = _viewingTestSet ? _testTransactions : _transactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDesktopKPICard(
                title: 'TOTAL TRANSAKSI',
                value: '${_masterTransactions.length} Struk',
                subtitle: 'Dataset master',
                icon: CupertinoIcons.doc_text_fill,
                iconColor: gunadarmaPurple,
                iconBg: const Color(0xFFFAF5FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDesktopKPICard(
                title: 'ITEM UNIK',
                value: '${aprioriResult.uniqueItemCount} Produk',
                subtitle: 'Katalog terdata',
                icon: CupertinoIcons.cube_box_fill,
                iconColor: gunadarmaPurple,
                iconBg: const Color(0xFFFAF5FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDesktopKPICard(
                title: 'RATA-RATA / STRUK',
                value: '${avgItems.toStringAsFixed(1)} Item',
                subtitle: 'Kepadatan transaksi',
                icon: CupertinoIcons.cart_fill,
                iconColor: gunadarmaPurple,
                iconBg: const Color(0xFFFAF5FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDesktopKPICard(
                title: 'PARTISI AKTIF',
                value: badgeLabel,
                subtitle: '${_transactions.length} Latih / ${_testTransactions.length} Uji',
                icon: CupertinoIcons.slider_horizontal_3,
                iconColor: gunadarmaPurple,
                iconBg: const Color(0xFFFAF5FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: _buildDesktopDatasetControlPanel(aprioriResult),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 8,
              child: _buildDesktopTransactionsCard(activeList),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopAprioriView(_AprioriResult aprioriResult) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDesktopKPICard(
                title: 'FREQUENT ITEMSETS',
                value: '${aprioriResult.frequentItemCount} Item',
                subtitle: 'Lolos ambang batas L1',
                icon: CupertinoIcons.check_mark_circled_solid,
                iconColor: gunadarmaPurple,
                iconBg: const Color(0xFFFAF5FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDesktopKPICard(
                title: 'ATURAN ASOSIASI',
                value: '${aprioriResult.rules.length} Aturan',
                subtitle: 'Kaidah valid teruji',
                icon: CupertinoIcons.arrow_branch,
                iconColor: gunadarmaPurple,
                iconBg: const Color(0xFFFAF5FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDesktopKPICard(
                title: 'MINIMUM SUPPORT',
                value: '${_minSupport.toInt()}%',
                subtitle: 'Ambang frekuensi',
                icon: CupertinoIcons.percent,
                iconColor: gunadarmaPurple,
                iconBg: const Color(0xFFFAF5FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDesktopKPICard(
                title: 'MINIMUM CONFIDENCE',
                value: '${_minConfidence.toInt()}%',
                subtitle: 'Ambang kepastian',
                icon: CupertinoIcons.shield_fill,
                iconColor: gunadarmaPurple,
                iconBg: const Color(0xFFFAF5FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: _buildDesktopAprioriControlPanel(aprioriResult),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 8,
              child: _buildDesktopRulesCard(aprioriResult.rules),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopKPICard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: mutedText,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: mutedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDatasetControlPanel(_AprioriResult res) {
    final totalMaster = _masterTransactions.length;
    final trainCount = _transactions.length;
    final testCount = _testTransactions.length;
    final int trainPct = totalMaster > 0 ? ((trainCount / totalMaster) * 100).round() : 0;
    final int testPct = totalMaster > 0 ? ((testCount / totalMaster) * 100).round() : 0;

    String badgeLabel;
    if (_scenarioIndex == 1) {
      badgeLabel = 'Rasio 80 : 20';
    } else if (_scenarioIndex == 2) {
      badgeLabel = 'Rasio 70 : 30';
    } else {
      badgeLabel = '$totalMaster Data Penuh';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
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
              const Row(
                children: [
                  Icon(CupertinoIcons.slider_horizontal_3, size: 16, color: darkText),
                  SizedBox(width: 8),
                  Text(
                    'Panel Kontrol Dataset',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: darkText,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: gunadarmaPurple,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.8, color: cardBorder),
          const Text(
            '1. Skenario Partisi Data',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _scenarioIndex,
              backgroundColor: const Color(0xFFE5E5EA),
              thumbColor: Colors.white,
              padding: const EdgeInsets.all(3.5),
              children: {
                0: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.5),
                  child: Text(
                    'Semua ($totalMaster)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _scenarioIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                      color: _scenarioIndex == 0 ? gunadarmaPurple : mutedText,
                    ),
                  ),
                ),
                1: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.5),
                  child: Text(
                    '80 : 20',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _scenarioIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                      color: _scenarioIndex == 1 ? gunadarmaPurple : mutedText,
                    ),
                  ),
                ),
                2: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.5),
                  child: Text(
                    '70 : 30',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _scenarioIndex == 2 ? FontWeight.w700 : FontWeight.w500,
                      color: _scenarioIndex == 2 ? gunadarmaPurple : mutedText,
                    ),
                  ),
                ),
              },
              onValueChanged: _onScenarioChanged,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4.5,
              width: double.infinity,
              child: _scenarioIndex == 0
                  ? Container(color: gunadarmaPurple)
                  : Row(
                      children: [
                        Expanded(
                          flex: trainPct > 0 ? trainPct : 1,
                          child: Container(color: gunadarmaPurple),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: testPct > 0 ? testPct : 1,
                          child: Container(color: const Color(0xFF007AFF)),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: gunadarmaPurple,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Latih: $trainCount ($trainPct%)',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                ],
              ),
              if (testCount > 0)
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF007AFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Uji: $testCount ($testPct%)',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  '100% untuk pemodelan',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const Divider(height: 24, thickness: 0.8, color: cardBorder),
          const Text(
            '2. Impor Berkas Dataset',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Unggah berkas transaksi (.csv / .txt) atau tempel baris data.',
            style: TextStyle(fontSize: 11, color: mutedText, height: 1.35),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: gunadarmaPurple,
                  borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: _pickFileFromDevice,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.folder_badge_plus, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Pilih Berkas',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoButton(
                  color: iosBg,
                  borderRadius: BorderRadius.circular(10),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: _openCsvImportSheet,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.doc_on_clipboard, size: 14, color: gunadarmaPurple),
                      SizedBox(width: 6),
                      Text(
                        'Tempel Teks',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: gunadarmaPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.8, color: cardBorder),
          const Text(
            '3. Input Struk Tunggal (Manual)',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
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
                child: const Text('Tambah', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: accentPurple,
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.symmetric(vertical: 9),
                onPressed: _saveTransaction,
                child: const Text('Simpan Struk ke Dataset', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopTransactionsCard(List<List<String>> activeList) {
    final totalTrans = activeList.length;
    final totalPages = totalTrans == 0 ? 1 : ((totalTrans - 1) ~/ _transPerPage) + 1;
    final currentPage = _transCurrentPage.clamp(0, totalPages - 1);
    final startIndex = currentPage * _transPerPage;
    final endIndex = (startIndex + _transPerPage < totalTrans) ? startIndex + _transPerPage : totalTrans;
    final displayList = totalTrans == 0 ? <List<String>>[] : activeList.sublist(startIndex, endIndex);

    final String titleText = _scenarioIndex == 0
        ? 'Daftar Struk Transaksi ($totalTrans)'
        : _viewingTestSet
            ? 'Daftar Struk Uji ($totalTrans)'
            : 'Daftar Struk Latih ($totalTrans)';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.doc_text_fill, size: 16, color: gunadarmaPurple),
                    const SizedBox(width: 8),
                    Text(
                      titleText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_scenarioIndex > 0 && _testTransactions.isNotEmpty) ...[
                      CupertinoSlidingSegmentedControl<bool>(
                        groupValue: _viewingTestSet,
                        backgroundColor: const Color(0xFFE5E5EA),
                        thumbColor: Colors.white,
                        padding: const EdgeInsets.all(2.5),
                        children: {
                          false: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Text(
                              'Latih (${_transactions.length})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: !_viewingTestSet ? FontWeight.w700 : FontWeight.w500,
                                color: !_viewingTestSet ? gunadarmaPurple : mutedText,
                              ),
                            ),
                          ),
                          true: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Text(
                              'Uji (${_testTransactions.length})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: _viewingTestSet ? FontWeight.w700 : FontWeight.w500,
                                color: _viewingTestSet ? const Color(0xFF007AFF) : mutedText,
                              ),
                            ),
                          ),
                        },
                        onValueChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _viewingTestSet = val;
                              _transCurrentPage = 0;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (_masterTransactions.isNotEmpty)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: _resetAllData,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Hapus Semua',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF3B30),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: cardBorder, width: 0.8),
                bottom: BorderSide(color: cardBorder, width: 0.8),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 75,
                  child: Text(
                    'ID STRUK',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ITEM BELANJA TRANSAKSI',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: Text(
                    'JUMLAH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 50,
                  child: Text(
                    'AKSI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (activeList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              alignment: Alignment.center,
              child: const Text(
                'Belum ada transaksi dalam dataset ini.',
                style: TextStyle(fontSize: 12, color: mutedText),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayList.length,
              separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, idx) {
                final trans = displayList[idx];
                final actualIdx = startIndex + idx;
                final displayIdx = _viewingTestSet ? _transactions.length + actualIdx + 1 : actualIdx + 1;
                final isEven = idx % 2 == 0;
                const badgeColor = Color(0xFF475569);
                const badgeBg = Color(0xFFF1F5F9);

                return Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  color: isEven ? Colors.white : const Color(0xFFFAFAFC),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 75,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                            ),
                            child: Text(
                              '#$displayIdx',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Tooltip(
                          message: trans.join(', '),
                          child: Text(
                            trans.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: cardBorder, width: 0.6),
                            ),
                            child: Text(
                              '${trans.length} Item',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: darkText,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: Center(
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(28, 28),
                            onPressed: () => _deleteTransaction(actualIdx),
                            child: const Icon(CupertinoIcons.trash, size: 15, color: Color(0xFFFF3B30)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: cardBorder, width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Halaman ${currentPage + 1} dari $totalPages (Total $totalTrans Transaksi)',
                  style: const TextStyle(fontSize: 11.5, color: mutedText, fontWeight: FontWeight.w500),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      onPressed: currentPage > 0
                          ? () => setState(() => _transCurrentPage = currentPage - 1)
                          : null,
                      child: Text(
                        'Sebelumnya',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: currentPage > 0 ? gunadarmaPurple : mutedText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      onPressed: currentPage < totalPages - 1
                          ? () => setState(() => _transCurrentPage = currentPage + 1)
                          : null,
                      child: Text(
                        'Selanjutnya',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: currentPage < totalPages - 1 ? gunadarmaPurple : mutedText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopAprioriControlPanel(_AprioriResult res) {
    final totalMaster = _masterTransactions.length;
    final trainCount = _transactions.length;
    final testCount = _testTransactions.length;
    final int trainPct = totalMaster > 0 ? ((trainCount / totalMaster) * 100).round() : 0;
    final int testPct = totalMaster > 0 ? ((testCount / totalMaster) * 100).round() : 0;

    final frequentItems = res.itemFrequencies.where((i) => i.percent >= _minSupport).toList();
    final allTopItems = res.itemFrequencies.take(5).toList();
    final itemsToDisplay = _showOnlyL1 ? frequentItems.take(5).toList() : allTopItems;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.gear_alt_fill, size: 16, color: darkText),
                  SizedBox(width: 8),
                  Text(
                    'Panel Parameter & L1',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: darkText,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Text(
                'Algoritma Apriori',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: gunadarmaPurple,
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.8, color: cardBorder),
          const Text(
            '1. Skenario Partisi Data',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _scenarioIndex,
              backgroundColor: const Color(0xFFE5E5EA),
              thumbColor: Colors.white,
              padding: const EdgeInsets.all(3.5),
              children: {
                0: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.5),
                  child: Text(
                    'Semua ($totalMaster)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _scenarioIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                      color: _scenarioIndex == 0 ? gunadarmaPurple : mutedText,
                    ),
                  ),
                ),
                1: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.5),
                  child: Text(
                    '80 : 20',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _scenarioIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                      color: _scenarioIndex == 1 ? gunadarmaPurple : mutedText,
                    ),
                  ),
                ),
                2: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.5),
                  child: Text(
                    '70 : 30',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _scenarioIndex == 2 ? FontWeight.w700 : FontWeight.w500,
                      color: _scenarioIndex == 2 ? gunadarmaPurple : mutedText,
                    ),
                  ),
                ),
              },
              onValueChanged: _onScenarioChanged,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4.5,
              width: double.infinity,
              child: _scenarioIndex == 0
                  ? Container(color: gunadarmaPurple)
                  : Row(
                      children: [
                        Expanded(
                          flex: trainPct > 0 ? trainPct : 1,
                          child: Container(color: gunadarmaPurple),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: testPct > 0 ? testPct : 1,
                          child: Container(color: const Color(0xFF007AFF)),
                        ),
                      ],
                    ),
            ),
          ),
          const Divider(height: 24, thickness: 0.8, color: cardBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Preset Parameter Cepat',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: mutedText,
                  letterSpacing: 0.3,
                ),
              ),
              Row(
                children: [
                  _buildPresetButton('Standar', sup: 1.0, conf: 16.0),
                  const SizedBox(width: 4),
                  _buildPresetButton('Selektif', sup: 2.5, conf: 30.0),
                  const SizedBox(width: 4),
                  _buildPresetButton('Ketat', sup: 5.0, conf: 50.0),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '2. Ambang Batas Min. Support',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: darkText),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_minSupport.toInt()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: gunadarmaPurple),
                ),
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
              },
              onChangeEnd: (val) {
                _syncState();
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '3. Ambang Batas Min. Confidence',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: darkText),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_minConfidence.toInt()}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: gunadarmaPurple),
                ),
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
              },
              onChangeEnd: (val) {
                _syncState();
              },
            ),
          ),
          const Divider(height: 24, thickness: 0.8, color: cardBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '4. Distribusi Item (L1)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: darkText),
              ),
              CupertinoSlidingSegmentedControl<bool>(
                groupValue: _showOnlyL1,
                padding: const EdgeInsets.all(2),
                children: const {
                  false: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text('Semua', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                  true: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text('Lolos L1', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                },
                onValueChanged: (val) {
                  if (val != null) {
                    setState(() => _showOnlyL1 = val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cardBorder, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Batas Eliminasi Min. Support',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: mutedText,
                      ),
                    ),
                    Text(
                      '${_minSupport.toInt()}%',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: gunadarmaPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    height: 6,
                    width: double.infinity,
                    color: const Color(0xFFE2E8F0),
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.centerLeft,
                      widthFactor: (_minSupport / 100.0).clamp(0.01, 1.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [gunadarmaPurple, accentPurple],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (itemsToDisplay.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: const Text(
                'Tidak ada item yang lolos ambang batas',
                style: TextStyle(fontSize: 11, color: mutedText),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...itemsToDisplay.map((it) {
              final isLolos = it.percent >= _minSupport;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isLolos ? const Color(0xFFFAF5FF) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isLolos ? const Color(0xFFE9D5FF) : cardBorder,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  it.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isLolos ? FontWeight.w700 : FontWeight.w600,
                                    color: isLolos ? darkText : mutedText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isLolos ? const Color(0xFFF3E8FF) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isLolos ? 'Lolos L1' : 'Gugur',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isLolos ? gunadarmaPurple : mutedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${it.count}x (${it.percent.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isLolos ? gunadarmaPurple : mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 6,
                        width: double.infinity,
                        color: const Color(0xFFE2E8F0),
                        child: Stack(
                          children: [
                            AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.centerLeft,
                              widthFactor: (it.percent / 100.0).clamp(0.01, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isLolos ? const Color(0xFFDDD6FE) : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                            AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.centerLeft,
                              widthFactor: (isLolos ? (_minSupport / 100.0) : (it.percent / 100.0)).clamp(0.01, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: isLolos
                                      ? const LinearGradient(
                                          colors: [gunadarmaPurple, accentPurple],
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
                                        ),
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
            }),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              onPressed: () {
                AprioriStateManager.instance.resetToDefaultDataset().then((_) {
                  if (mounted) {
                    setState(() {
                      _masterTransactions.clear();
                      _masterTransactions.addAll(AprioriStateManager.instance.masterTransactions);
                      _applyScenarioSplitLocal();
                      _syncState();
                    });
                  }
                });
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.arrow_clockwise, size: 13, color: gunadarmaPurple),
                  SizedBox(width: 6),
                  Text(
                    'Muat Ulang Dataset 1.000 Transaksi',
                    style: TextStyle(
                      fontSize: 11,
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

  Widget _buildDesktopRulesCard(List<_LiveRule> rules) {
    final totalRules = rules.length;
    final totalPages = totalRules == 0 ? 1 : ((totalRules - 1) ~/ _rulesPerPage) + 1;
    final currentPage = _rulesCurrentPage.clamp(0, totalPages - 1);
    final startIndex = currentPage * _rulesPerPage;
    final endIndex = (startIndex + _rulesPerPage < totalRules) ? startIndex + _rulesPerPage : totalRules;
    final displayRules = totalRules == 0 ? <_LiveRule>[] : rules.sublist(startIndex, endIndex);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(CupertinoIcons.arrow_branch, size: 16, color: gunadarmaPurple),
                    const SizedBox(width: 8),
                    Text(
                      'Kaidah Asosiasi Apriori ($totalRules Aturan)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showFormulaExplanationModal(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: iosBg,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: cardBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(CupertinoIcons.question_circle, size: 12, color: darkText),
                            SizedBox(width: 4),
                            Text(
                              'Rumus',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: darkText),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (rules.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _copyRulesToClipboard(rules),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: const Color(0xFFE9D5FF)),
                          ),
                          child: const Row(
                            children: [
                              Icon(CupertinoIcons.doc_on_doc, size: 12, color: gunadarmaPurple),
                              SizedBox(width: 4),
                              Text(
                                'Salin',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: gunadarmaPurple),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _exportRulesToCsv(rules),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: cardBorder),
                          ),
                          child: const Row(
                            children: [
                              Icon(CupertinoIcons.arrow_down_doc, size: 12, color: gunadarmaPurple),
                              SizedBox(width: 4),
                              Text(
                                'Ekspor CSV',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: gunadarmaPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(color: cardBorder, width: 0.8),
                bottom: BorderSide(color: cardBorder, width: 0.8),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 45,
                  child: Text(
                    'NO',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: mutedText, letterSpacing: 0.5),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'JIKA DIBELI (ANTECEDENT)',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: mutedText, letterSpacing: 0.5),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    'MAKA DIBELI (CONSEQUENT)',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: mutedText, letterSpacing: 0.5),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'SUPPORT',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: mutedText, letterSpacing: 0.5),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'CONFIDENCE',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: mutedText, letterSpacing: 0.5),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'LIFT RATIO',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: mutedText, letterSpacing: 0.5),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'KORELASI',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: mutedText, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
          if (rules.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
              alignment: Alignment.center,
              child: const Text(
                'Belum ada aturan yang memenuhi ambang batas minimum.',
                style: TextStyle(fontSize: 12, color: mutedText),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayRules.length,
              separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFF1F5F9)),
              itemBuilder: (ctx, idx) {
                final r = displayRules[idx];
                final isEven = idx % 2 == 0;
                final isStrong = r.lift >= 1.0;
                final globalIdx = startIndex + idx + 1;

                return Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  color: isEven ? Colors.white : const Color(0xFFFAFAFC),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 45,
                        child: Text(
                          '#$globalIdx',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mutedText),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: cardBorder, width: 0.6),
                            ),
                            child: Text(
                              r.antecedent,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkText),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE9D5FF), width: 0.6),
                            ),
                            child: Text(
                              r.consequent,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: gunadarmaPurple),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${r.support.toStringAsFixed(1)}%',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkText),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${r.confidence.toStringAsFixed(1)}%',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: darkText),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${r.lift.toStringAsFixed(2)}x',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isStrong ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isStrong ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isStrong ? const Color(0xFFA7F3D0) : cardBorder,
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              isStrong ? 'Sangat Kuat' : 'Kurang Kuat',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isStrong ? const Color(0xFF059669) : mutedText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: cardBorder, width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Halaman ${currentPage + 1} dari $totalPages (Total $totalRules Aturan)',
                  style: const TextStyle(fontSize: 11.5, color: mutedText, fontWeight: FontWeight.w500),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      onPressed: currentPage > 0
                          ? () => setState(() => _rulesCurrentPage = currentPage - 1)
                          : null,
                      child: Text(
                        'Sebelumnya',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: currentPage > 0 ? gunadarmaPurple : mutedText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      onPressed: currentPage < totalPages - 1
                          ? () => setState(() => _rulesCurrentPage = currentPage + 1)
                          : null,
                      child: Text(
                        'Selanjutnya',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: currentPage < totalPages - 1 ? gunadarmaPurple : mutedText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioSplitCard() {
    final totalMaster = _masterTransactions.length;
    final trainCount = _transactions.length;
    final testCount = _testTransactions.length;
    final int trainPct = totalMaster > 0 ? ((trainCount / totalMaster) * 100).round() : 0;
    final int testPct = totalMaster > 0 ? ((testCount / totalMaster) * 100).round() : 0;

    String badgeLabel;
    if (_scenarioIndex == 1) {
      badgeLabel = 'Rasio 80 : 20';
    } else if (_scenarioIndex == 2) {
      badgeLabel = 'Rasio 70 : 30';
    } else {
      badgeLabel = '$totalMaster Data Penuh';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Partisi Dataset',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: gunadarmaPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _scenarioIndex,
              backgroundColor: const Color(0xFFE5E5EA),
              thumbColor: Colors.white,
              padding: const EdgeInsets.all(3.5),
              children: {
                0: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.5),
                  child: Text(
                    'Semua ($totalMaster)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _scenarioIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                      color: _scenarioIndex == 0 ? gunadarmaPurple : mutedText,
                    ),
                  ),
                ),
                1: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.5),
                  child: Text(
                    '80 : 20',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _scenarioIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                      color: _scenarioIndex == 1 ? gunadarmaPurple : mutedText,
                    ),
                  ),
                ),
                2: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.5),
                  child: Text(
                    '70 : 30',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _scenarioIndex == 2 ? FontWeight.w700 : FontWeight.w500,
                      color: _scenarioIndex == 2 ? gunadarmaPurple : mutedText,
                    ),
                  ),
                ),
              },
              onValueChanged: _onScenarioChanged,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4.5,
              width: double.infinity,
              child: _scenarioIndex == 0
                  ? Container(color: gunadarmaPurple)
                  : Row(
                      children: [
                        Expanded(
                          flex: trainPct > 0 ? trainPct : 1,
                          child: Container(color: gunadarmaPurple),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: testPct > 0 ? testPct : 1,
                          child: Container(color: const Color(0xFF007AFF)),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: gunadarmaPurple,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Data Latih: $trainCount ($trainPct%)',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
                ],
              ),
              if (testCount > 0)
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF007AFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Data Uji: $testCount ($testPct%)',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  '100% data untuk pemodelan',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
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
            label: _scenarioIndex == 0 ? 'TOTAL STRUK' : 'DATA LATIH',
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
            label: _scenarioIndex == 0 ? 'RATA-RATA/STRUK' : 'DATA UJI',
            value: _scenarioIndex == 0 ? avgItems.toStringAsFixed(1) : '${_testTransactions.length}',
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
    final activeList = _viewingTestSet ? _testTransactions : _transactions;

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
                _scenarioIndex == 0
                    ? 'Daftar Struk Transaksi (${activeList.length})'
                    : _viewingTestSet
                        ? 'Daftar Struk Uji (${activeList.length})'
                        : 'Daftar Struk Latih (${activeList.length})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              if (_masterTransactions.isNotEmpty)
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
          if (_scenarioIndex > 0 && _testTransactions.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<bool>(
                groupValue: _viewingTestSet,
                backgroundColor: const Color(0xFFE5E5EA),
                thumbColor: Colors.white,
                padding: const EdgeInsets.all(3),
                children: {
                  false: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Data Latih (${_transactions.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: !_viewingTestSet ? FontWeight.w700 : FontWeight.w500,
                        color: !_viewingTestSet ? gunadarmaPurple : mutedText,
                      ),
                    ),
                  ),
                  true: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Data Uji (${_testTransactions.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: _viewingTestSet ? FontWeight.w700 : FontWeight.w500,
                        color: _viewingTestSet ? const Color(0xFF007AFF) : mutedText,
                      ),
                    ),
                  ),
                },
                onValueChanged: (val) {
                  if (val != null) {
                    setState(() => _viewingTestSet = val);
                  }
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (activeList.isEmpty)
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
          else if (MediaQuery.of(context).size.width >= 960)
            _buildDesktopTransactionsDataTable(activeList)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeList.length > 25 ? 25 : activeList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final trans = activeList[idx];
                final displayIdx = _viewingTestSet ? _transactions.length + idx + 1 : idx + 1;
                const badgeColor = Color(0xFF475569);
                const badgeBg = Color(0xFFF1F5F9);

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
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                        ),
                        child: Text(
                          '#$displayIdx',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
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
          if (activeList.length > 25 && MediaQuery.of(context).size.width < 960) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Menampilkan 25 dari ${activeList.length} transaksi',
                style: const TextStyle(fontSize: 10.5, color: mutedText, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopTransactionsDataTable(List<List<String>> activeList) {
    final totalTrans = activeList.length;
    final totalPages = totalTrans == 0 ? 1 : ((totalTrans - 1) ~/ _transPerPage) + 1;
    final currentPage = _transCurrentPage.clamp(0, totalPages - 1);
    final startIndex = currentPage * _transPerPage;
    final endIndex = (startIndex + _transPerPage < totalTrans) ? startIndex + _transPerPage : totalTrans;
    final displayList = totalTrans == 0 ? <List<String>>[] : activeList.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 0.8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: cardBorder, width: 0.8)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    'STRUK ID',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'ITEM BELANJA (TRANSAKSI)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    'TOTAL ITEM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    'HAPUS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayList.length,
            separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFF1F5F9)),
            itemBuilder: (ctx, idx) {
              final trans = displayList[idx];
              final actualIdx = startIndex + idx;
              final displayIdx = _viewingTestSet ? _transactions.length + actualIdx + 1 : actualIdx + 1;
              final isEven = idx % 2 == 0;
              const badgeColor = Color(0xFF475569);
              const badgeBg = Color(0xFFF1F5F9);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: isEven ? Colors.white : const Color(0xFFFAFAFC),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                        ),
                        child: Text(
                          '#$displayIdx',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: trans.map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Text(
                              item,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: darkText),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        '${trans.length} Item',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: mutedText,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Center(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(28, 28),
                          onPressed: () => _deleteTransaction(actualIdx),
                          child: const Icon(CupertinoIcons.trash, size: 15, color: Color(0xFFFF3B30)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: cardBorder, width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Halaman ${currentPage + 1} dari $totalPages (Total $totalTrans Transaksi)',
                  style: const TextStyle(fontSize: 11, color: mutedText, fontWeight: FontWeight.w500),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      onPressed: currentPage > 0
                          ? () => setState(() => _transCurrentPage = currentPage - 1)
                          : null,
                      child: Text(
                        'Sebelumnya',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: currentPage > 0 ? gunadarmaPurple : mutedText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      onPressed: currentPage < totalPages - 1
                          ? () => setState(() => _transCurrentPage = currentPage + 1)
                          : null,
                      child: Text(
                        'Selanjutnya',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: currentPage < totalPages - 1 ? gunadarmaPurple : mutedText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
              },
              onChangeEnd: (val) {
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
              },
              onChangeEnd: (val) {
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
    final allTopItems = res.itemFrequencies.take(6).toList();
    final frequentItems = res.itemFrequencies.where((i) => i.percent >= _minSupport).toList();
    final itemsToDisplay = _showOnlyL1 ? frequentItems.take(6).toList() : allTopItems;

    const double displayMax = 100.0;
    final double thresholdFraction = (_minSupport / displayMax).clamp(0.0, 1.0);

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribusi Frekuensi Item Teratas (L1)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: darkText),
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: const TextStyle(fontSize: 10.5, color: mutedText, fontWeight: FontWeight.w500),
                      child: Text(
                        '${frequentItems.length} item lolos ambang batas (≥ ${_minSupport.toInt()}%)',
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSlidingSegmentedControl<bool>(
                groupValue: _showOnlyL1,
                children: const {
                  false: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Text('Semua', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                  ),
                  true: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Text('Lolos L1', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                  ),
                },
                onValueChanged: (val) {
                  if (val != null) {
                    setState(() => _showOnlyL1 = val);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (itemsToDisplay.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(CupertinoIcons.slider_horizontal_below_rectangle, color: mutedText, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada item yang memenuhi ambang batas ≥ ${_minSupport.toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Geser slider Minimum Support ke kiri untuk menurunkan batas seleksi L1.',
                    style: TextStyle(fontSize: 11, color: mutedText),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Expanded(
                    flex: 4,
                    child: SizedBox(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 6,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final trackWidth = constraints.maxWidth;
                        final double badgeLeft = (thresholdFraction * trackWidth - 30.0)
                            .clamp(0.0, math.max(0.0, trackWidth - 62.0))
                            .toDouble();

                        return SizedBox(
                          height: 22,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('0%', style: TextStyle(fontSize: 8.5, color: mutedText, fontWeight: FontWeight.w600)),
                                    Text('50%', style: TextStyle(fontSize: 8.5, color: mutedText, fontWeight: FontWeight.w600)),
                                    Text('100%', style: TextStyle(fontSize: 8.5, color: mutedText, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: badgeLeft,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: gunadarmaPurple,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: gunadarmaPurple.withValues(alpha: 0.25),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Ambang ${_minSupport.toInt()}%',
                                    style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(width: 52),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeOutCubic,
              builder: (context, animValue, _) {
                return LayoutBuilder(
                  builder: (context, chartConstraints) {
                    return Stack(
                      children: [
                        Column(
                          children: itemsToDisplay.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final isAbove = item.percent >= _minSupport;
                            final barWidthFactor = ((item.percent / displayMax) * animValue).clamp(0.0, 1.0);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Row(
                                      children: [
                                        Text(
                                          '#${index + 1} ',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: mutedText),
                                        ),
                                        Expanded(
                                          child: Text(
                                            _formatItemName(item.name),
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: isAbove ? FontWeight.w700 : FontWeight.w500,
                                              color: isAbove ? darkText : mutedText,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 6,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final barAreaWidth = constraints.maxWidth;
                                        return SizedBox(
                                          height: 18,
                                          child: Stack(
                                            alignment: Alignment.centerLeft,
                                            children: [
                                              Container(
                                                height: 8,
                                                width: barAreaWidth,
                                                decoration: BoxDecoration(
                                                  color: iosBg,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                              AnimatedContainer(
                                                duration: const Duration(milliseconds: 180),
                                                curve: Curves.easeOutCubic,
                                                height: 8,
                                                width: barAreaWidth * barWidthFactor,
                                                decoration: BoxDecoration(
                                                  gradient: isAbove
                                                      ? const LinearGradient(
                                                          colors: [gunadarmaPurple, accentPurple],
                                                        )
                                                      : null,
                                                  color: isAbove ? null : const Color(0xFFD1D1D6),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 52,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${item.percent.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: isAbove ? gunadarmaPurple : mutedText,
                                          ),
                                        ),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: isAbove
                                                ? gunadarmaPurple.withValues(alpha: 0.1)
                                                : const Color(0xFFE5E5EA),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            isAbove ? 'L1' : 'Gugur',
                                            style: TextStyle(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w700,
                                              color: isAbove ? gunadarmaPurple : mutedText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Row(
                              children: [
                                const Expanded(
                                  flex: 4,
                                  child: SizedBox(),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 6,
                                  child: LayoutBuilder(
                                    builder: (context, trackConstraints) {
                                      final double needlePosition = (thresholdFraction * trackConstraints.maxWidth)
                                          .clamp(0.0, trackConstraints.maxWidth)
                                          .toDouble();

                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Positioned(
                                            left: math.max(0.0, needlePosition - 1.0),
                                            top: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 2.0,
                                              decoration: BoxDecoration(
                                                color: gunadarmaPurple,
                                                borderRadius: BorderRadius.circular(1),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: gunadarmaPurple.withValues(alpha: 0.35),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 0),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const SizedBox(width: 52),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _formatItemName(String text) {
    if (text.isEmpty) return text;
    return text.split(',').map((item) {
      final trimmed = item.trim();
      if (trimmed.isEmpty) return '';
      return trimmed.split('/').map((sub) {
        final subTrimmed = sub.trim();
        if (subTrimmed.isEmpty) return '';
        return subTrimmed.split(' ').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
      }).join(' / ');
    }).join(', ');
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Text(
                    'Aturan Asosiasi',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: darkText),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${rules.length}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: gunadarmaPurple),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showFormulaExplanationModal(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: iosBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cardBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(CupertinoIcons.question_circle, size: 12, color: darkText),
                          SizedBox(width: 4),
                          Text(
                            'Rumus',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: darkText),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (rules.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _copyRulesToClipboard(rules),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE9D5FF)),
                        ),
                        child: const Row(
                          children: [
                            Icon(CupertinoIcons.doc_on_doc, size: 12, color: gunadarmaPurple),
                            SizedBox(width: 4),
                            Text(
                              'Salin',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: gunadarmaPurple),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
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
          else if (MediaQuery.of(context).size.width >= 960)
            _buildDesktopRulesDataTable(rules)
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

  Widget _buildDesktopRulesDataTable(List<_LiveRule> rules) {
    final totalRules = rules.length;
    final totalPages = totalRules == 0 ? 1 : ((totalRules - 1) ~/ _rulesPerPage) + 1;
    final currentPage = _rulesCurrentPage.clamp(0, totalPages - 1);
    final startIndex = currentPage * _rulesPerPage;
    final endIndex = (startIndex + _rulesPerPage < totalRules) ? startIndex + _rulesPerPage : totalRules;
    final displayRules = totalRules == 0 ? <_LiveRule>[] : rules.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 0.8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: cardBorder, width: 0.8)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    'NO',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'JIKA DIBELI (ANTECEDENT)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    'MAKA DIBELI (CONSEQUENT)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'SUPPORT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'CONFIDENCE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'LIFT RATIO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'KORELASI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: mutedText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayRules.length,
            separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFF1F5F9)),
            itemBuilder: (ctx, idx) {
              final r = displayRules[idx];
              final isEven = idx % 2 == 0;
              final isStrong = r.lift >= 1.0;
              final globalIdx = startIndex + idx + 1;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: isEven ? Colors.white : const Color(0xFFFAFAFC),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        '#$globalIdx',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: mutedText,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: cardBorder, width: 0.6),
                          ),
                          child: Text(
                            r.antecedent,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE9D5FF), width: 0.6),
                          ),
                          child: Text(
                            r.consequent,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: gunadarmaPurple,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${r.support.toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${r.confidence.toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: darkText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${r.lift.toStringAsFixed(2)}x',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isStrong ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isStrong ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isStrong ? const Color(0xFFA7F3D0) : cardBorder,
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            isStrong ? 'Sangat Kuat' : 'Kurang Kuat',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isStrong ? const Color(0xFF059669) : mutedText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: cardBorder, width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Halaman ${currentPage + 1} dari $totalPages (Total $totalRules Aturan)',
                  style: const TextStyle(fontSize: 11, color: mutedText, fontWeight: FontWeight.w500),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      onPressed: currentPage > 0
                          ? () => setState(() => _rulesCurrentPage = currentPage - 1)
                          : null,
                      child: Text(
                        'Sebelumnya',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: currentPage > 0 ? gunadarmaPurple : mutedText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      onPressed: currentPage < totalPages - 1
                          ? () => setState(() => _rulesCurrentPage = currentPage + 1)
                          : null,
                      child: Text(
                        'Selanjutnya',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: currentPage < totalPages - 1 ? gunadarmaPurple : mutedText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyRulesToClipboard(List<_LiveRule> rules) {
    if (rules.isEmpty) {
      _showIOSNotification('Tidak ada aturan untuk disalin.');
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('No\tAntecedent (Jika)\tConsequent (Maka)\tSupport (%)\tConfidence (%)\tLift Ratio\tInterpretasi');
    for (int i = 0; i < rules.length; i++) {
      final r = rules[i];
      final interp = r.lift > 1.0 ? 'Pola Sangat Kuat' : 'Pola Kurang Kuat';
      buffer.writeln('${i + 1}\t${r.antecedent}\t${r.consequent}\t${r.support.toStringAsFixed(1)}%\t${r.confidence.toStringAsFixed(1)}%\t${r.lift.toStringAsFixed(2)}\t$interp');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    _showIOSNotification('${rules.length} aturan disalin ke clipboard');
  }

  Widget _buildPresetButton(String label, {required double sup, required double conf}) {
    final isSelected = (_minSupport - sup).abs() < 0.1 && (_minConfidence - conf).abs() < 0.1;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      minimumSize: Size.zero,
      color: isSelected ? gunadarmaPurple : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(6),
      onPressed: () {
        setState(() {
          _minSupport = sup;
          _minConfidence = conf;
        });
        _syncState();
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
    );
  }

  void _exportRulesToCsv(List<_LiveRule> rules) {
    if (rules.isEmpty) {
      _showIOSNotification('Tidak ada aturan untuk diekspor.', isError: true);
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('No,Antecedent (Jika Dibeli),Consequent (Maka Dibeli),Support (%),Confidence (%),Lift Ratio,Korelasi');
    for (int i = 0; i < rules.length; i++) {
      final r = rules[i];
      final interp = r.lift > 1.0 ? 'Sangat Kuat' : 'Kurang Kuat';
      buffer.writeln('${i + 1},"${r.antecedent}","${r.consequent}",${r.support.toStringAsFixed(1)},${r.confidence.toStringAsFixed(1)},${r.lift.toStringAsFixed(2)},$interp');
    }
    final csvContent = buffer.toString();
    Clipboard.setData(ClipboardData(text: csvContent));
    launchUrl(Uri.dataFromString(csvContent, mimeType: 'text/csv', encoding: utf8));
    _showIOSNotification('${rules.length} kaidah asosiasi diekspor ke file CSV.');
  }

  Widget _buildFormulaExplanationModalContent(BuildContext context, VoidCallback onClose) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rumus & Metrik Evaluasi Apriori',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Dasar Perhitungan Algoritma Market Basket Analysis',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: mutedText,
                    ),
                  ),
                ],
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onClose,
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
        ),
        const Divider(height: 0.5, thickness: 0.5, color: cardBorder),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              children: [
                _buildFormulaCard(
                  title: '1. Support (Tingkat Dukungan)',
                  badge: 'Frekuensi Kemunculan',
                  badgeColor: gunadarmaPurple,
                  formula: 'Support(A ∪ B) = n(A ∩ B) / N × 100%',
                  description: 'Mengukur seberapa sering kombinasi produk A dan B dibeli bersamaan dari total seluruh transaksi belanja.',
                  example: 'Contoh: 177 dari 1.000 transaksi membeli whole milk → Support = 17.7%.',
                ),
                const SizedBox(height: 12),
                _buildFormulaCard(
                  title: '2. Confidence (Tingkat Kepastian)',
                  badge: 'Kekuatan Hubungan',
                  badgeColor: const Color(0xFF007AFF),
                  formula: 'Confidence(A → B) = Support(A ∪ B) / Support(A) × 100%',
                  description: 'Mengukur seberapa besar kepastian pelanggan membeli produk B apabila pelanggan tersebut telah membeli produk A.',
                  example: 'Contoh: Jika membeli roti, berapa % kemungkinan membeli mentega.',
                ),
                const SizedBox(height: 12),
                _buildFormulaCard(
                  title: '3. Lift Ratio (Validitas Asosiasi)',
                  badge: 'Keabsahan Pola',
                  badgeColor: const Color(0xFF34C759),
                  formula: 'Lift(A → B) = Confidence(A → B) / Support(B)',
                  description: 'Menguji apakah hubungan antar item merupakan pola riil atau sekadar kebetulan statistik.',
                  example: 'Lift > 1.0 : Pola asosiasi sangat kuat (rekomendasi bernilai tinggi).\nLift = 1.0 : Kedua produk independen (tidak saling mempengaruhi).\nLift < 1.0 : Korelasi negatif (jarang dibeli bersamaan).',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFormulaExplanationModal(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (dialogCtx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
            child: Container(
              decoration: BoxDecoration(
                color: iosBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.only(top: 18),
              child: _buildFormulaExplanationModalContent(
                context,
                () => Navigator.pop(dialogCtx),
              ),
            ),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.76,
          decoration: const BoxDecoration(
            color: iosBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  width: 36,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Expanded(
                child: _buildFormulaExplanationModalContent(
                  context,
                  () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormulaCard({
    required String title,
    required String badge,
    required Color badgeColor,
    required String formula,
    required String description,
    required String example,
  }) {
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
                title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: darkText),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: iosBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cardBorder),
            ),
            child: Text(
              formula,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: gunadarmaPurple,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 11.5, color: darkText, height: 1.35),
          ),
          const SizedBox(height: 6),
          Text(
            example,
            style: const TextStyle(fontSize: 11, color: mutedText, height: 1.35),
          ),
        ],
      ),
    );
  }

  void _showAcademicReferenceModal(BuildContext context) {
    AcademicReferenceHelper.showJournalModal(context);
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
