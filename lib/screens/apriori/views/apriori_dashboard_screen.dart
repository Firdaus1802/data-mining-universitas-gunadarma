import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop/models/apriori_state_manager.dart';
import 'package:shop/screens/apriori/views/academic_reference_helper.dart';

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

  static const Color gunadarmaPurple = Color(0xFF2E1065);
  static const Color accentPurple = Color(0xFF5856D6);
  static const Color cardBorder = Color(0xFFE5E5EA);
  static const Color iosBg = Color(0xFFF2F2F7);
  static const Color darkText = Color(0xFF1C1C1E);
  static const Color mutedText = Color(0xFF8E8E93);

  @override
  void initState() {
    super.initState();
    final mgr = AprioriStateManager.instance;
    _scenarioIndex = mgr.scenarioIndex;
    _masterTransactions.clear();
    _masterTransactions.addAll(mgr.masterTransactions.isNotEmpty ? mgr.masterTransactions : mgr.transactions);
    if (_masterTransactions.length <= 1) {
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

    return Scaffold(
      backgroundColor: iosBg,
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                            'Pusat Manajemen Transaksi & Aturan Asosiasi',
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: gunadarmaPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.book_fill, size: 12, color: gunadarmaPurple),
                                SizedBox(width: 4),
                                Text(
                                  'Jurnal',
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
              const SizedBox(height: 14),
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
          ),
        ),
      ),
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
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeList.length > 25 ? 25 : activeList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final trans = activeList[idx];
                final displayIdx = _viewingTestSet ? _transactions.length + idx + 1 : idx + 1;
                final badgeColor = _viewingTestSet ? const Color(0xFF007AFF) : gunadarmaPurple;
                final badgeBg = _viewingTestSet ? const Color(0xFFE0F2FE) : const Color(0xFFEDE9FE);

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
                        ),
                        child: Text(
                          '#$displayIdx',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
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
          if (activeList.length > 25) ...[
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

  void _showFormulaExplanationModal(BuildContext context) {
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
                      onPressed: () => Navigator.pop(ctx),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Referensi Riset & Dataset',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Dasar Teori Ilmiah & Sumber Data Transaksi',
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
                      onPressed: () => Navigator.pop(ctx),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Terakreditasi SINTA 3',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: gunadarmaPurple),
                                  ),
                                ),
                                const Text(
                                  'ISSN 2614-5278',
                                  style: TextStyle(fontSize: 10.5, color: mutedText, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Market Basket Analysis Menggunakan Algoritma Apriori dan FP Growth untuk Menentukan Pola Pembelian Konsumen',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: darkText, height: 1.3),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Jurnal Media Informatika Budidarma (JMIB) • Vol. 7, No. 3 (Juli 2023)\nPenulis: Reski Noviana, Arief Hermawan, Donny Avianto (UTY)',
                              style: TextStyle(fontSize: 11.5, color: mutedText, height: 1.35),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    color: gunadarmaPurple,
                                    borderRadius: BorderRadius.circular(10),
                                    onPressed: () {
                                      AcademicReferenceHelper.safeLaunchUrl(
                                        context,
                                        AcademicReferenceHelper.journalDoiUrl,
                                      );
                                    },
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(CupertinoIcons.arrow_up_right_square, size: 15, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text(
                                          'Buka DOI',
                                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
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
                                    onPressed: () {
                                      AcademicReferenceHelper.showJournalModal(context);
                                    },
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(CupertinoIcons.doc_text_fill, size: 15, color: gunadarmaPurple),
                                        SizedBox(width: 6),
                                        Text(
                                          'Naskah & PDF',
                                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: gunadarmaPurple),
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
                      const SizedBox(height: 14),
                      Container(
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '1.000 Transaksi Terpilih',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF007AFF)),
                                  ),
                                ),
                                const Text(
                                  'Kaggle Dataset',
                                  style: TextStyle(fontSize: 10.5, color: mutedText, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Groceries Market Basket Dataset',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: darkText),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Dataset riil transaksi pasar swalayan yang merekam kombinasi belanja konsumen untuk pengujian association rules mining.',
                              style: TextStyle(fontSize: 11.5, color: mutedText, height: 1.35),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    color: const Color(0xFF007AFF),
                                    borderRadius: BorderRadius.circular(10),
                                    onPressed: () {
                                      AcademicReferenceHelper.downloadDatasetCsv(context);
                                    },
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(CupertinoIcons.arrow_down_doc_fill, size: 15, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text(
                                          'Unduh CSV',
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
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(10),
                                    onPressed: () {
                                      AcademicReferenceHelper.showDatasetModal(context);
                                    },
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(CupertinoIcons.eye_fill, size: 15, color: Color(0xFF007AFF)),
                                        SizedBox(width: 6),
                                        Text(
                                          'Pratinjau',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF007AFF)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                  onPressed: () {
                                    AcademicReferenceHelper.safeLaunchUrl(
                                      context,
                                      AcademicReferenceHelper.kaggleDatasetUrl,
                                    );
                                  },
                                  child: const Icon(CupertinoIcons.arrow_up_right_square, size: 16, color: Color(0xFF4B5563)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
