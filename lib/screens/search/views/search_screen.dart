import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shop/models/apriori_state_manager.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  static const Color gunadarmaPurple = Color(0xFF2E1065);
  static const Color darkText = Color(0xFF0F172A);
  static const Color bodyText = Color(0xFF334155);
  static const Color mutedText = Color(0xFF64748B);
  static const Color subtleText = Color(0xFF94A3B8);
  static const Color borderLine = Color(0xFFE2E8F0);
  static const Color pageBg = Color(0xFFF8FAFC);
  static const Color cardBg = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final text = _searchCtrl.text.trim();
      if (text != _query) {
        setState(() {
          _query = text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applySearchQuery(String term) {
    _searchCtrl.text = term;
    _searchCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: term.length),
    );
    setState(() {
      _query = term;
    });
  }

  List<String> _getTopPopularItems(List<List<String>> transactions) {
    final Map<String, int> counts = {};
    for (final t in transactions) {
      for (final item in t.toSet()) {
        final clean = item.trim();
        if (clean.isNotEmpty) {
          counts[clean] = (counts[clean] ?? 0) + 1;
        }
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(8).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AprioriStateManager.instance,
      builder: (context, _) {
        final state = AprioriStateManager.instance;
        final transactions = state.transactions;
        final rules = state.rules;
        final popularItems = _getTopPopularItems(transactions);

        final cleanQuery = _query.toLowerCase();
        final hasQuery = cleanQuery.isNotEmpty;

        final matchingRules = hasQuery
            ? rules.where((r) {
                final ant = r.antecedent.toLowerCase();
                final cons = r.consequent.toLowerCase();
                return ant.contains(cleanQuery) || cons.contains(cleanQuery);
              }).toList()
            : <AprioriRuleSummary>[];

        final matchingTransactions = hasQuery
            ? transactions.where((t) {
                return t.any((item) => item.toLowerCase().contains(cleanQuery));
              }).toList()
            : <List<String>>[];

        int itemOccurrence = 0;
        if (hasQuery) {
          for (final t in transactions) {
            if (t.any((item) => item.toLowerCase().contains(cleanQuery))) {
              itemOccurrence++;
            }
          }
        }
        final double itemSupportPercent = transactions.isNotEmpty && itemOccurrence > 0
            ? (itemOccurrence / transactions.length) * 100.0
            : 0.0;

        return Scaffold(
          backgroundColor: pageBg,
          appBar: AppBar(
            backgroundColor: cardBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.chevron_back, color: darkText, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pencarian Pola Asosiasi',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Market Basket Rule & Bundling Explorer',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: mutedText,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(color: borderLine, height: 1.0),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  color: cardBg,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: CupertinoSearchTextField(
                    controller: _searchCtrl,
                    placeholder: 'Cari produk (misal: Roti, Kopi, Susu)...',
                    placeholderStyle: const TextStyle(
                      fontSize: 13.5,
                      color: subtleText,
                      fontWeight: FontWeight.w400,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                    borderRadius: BorderRadius.circular(12),
                    backgroundColor: const Color(0xFFF1F5F9),
                    onSuffixTap: () {
                      _searchCtrl.clear();
                      setState(() {
                        _query = '';
                      });
                    },
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!hasQuery)
                          _buildIdleView(transactions, popularItems)
                        else
                          _buildSearchResultsView(
                            query: _query,
                            itemOccurrence: itemOccurrence,
                            itemSupportPercent: itemSupportPercent,
                            totalTransactions: transactions.length,
                            matchingRules: matchingRules,
                            matchingTransactions: matchingTransactions,
                            minSupport: state.minSupport,
                            minConfidence: state.minConfidence,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdleView(List<List<String>> transactions, List<String> popularItems) {
    if (transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderLine, width: 1.0),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: borderLine),
              ),
              child: const Icon(
                CupertinoIcons.tray_fill,
                color: mutedText,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Dataset Transaksi Kosong',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Silakan unggah dataset transaksi di tab Dataset untuk mengaktifkan mesin pencarian pola asosiasi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: mutedText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context, 'open_dataset'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Buka Tab Dataset',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: gunadarmaPurple,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(CupertinoIcons.chevron_right, size: 10, color: gunadarmaPurple),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (popularItems.isNotEmpty) ...[
          const Text(
            'Item Populer dalam Dataset',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: darkText,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularItems.map((item) {
              return GestureDetector(
                onTap: () => _applySearchQuery(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderLine, width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.tag_fill,
                        size: 11,
                        color: gunadarmaPurple,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Panduan Pencarian Pola Asosiasi',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: darkText,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 10),
        _buildGuideTile(
          icon: CupertinoIcons.arrow_2_squarepath,
          title: 'Pola Pembelian Komplementer',
          description: 'Ketik nama barang untuk melihat produk apa yang paling sering dibeli secara bersamaan.',
        ),
        const SizedBox(height: 10),
        _buildGuideTile(
          icon: CupertinoIcons.chart_pie_fill,
          title: 'Metrik Akurasi Apriori',
          description: 'Sistem menganalisis nilai Support, Confidence, dan Lift ratio untuk mengukur kekuatan korelasi bundling.',
        ),
        const SizedBox(height: 10),
        _buildGuideTile(
          icon: CupertinoIcons.doc_text_search,
          title: 'Riwayat Struk Terverifikasi',
          description: 'Temukan nomor struk transaksi asli yang memuat barang tersebut secara transparan.',
        ),
      ],
    );
  }

  Widget _buildGuideTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderLine, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: gunadarmaPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsView({
    required String query,
    required int itemOccurrence,
    required double itemSupportPercent,
    required int totalTransactions,
    required List<AprioriRuleSummary> matchingRules,
    required List<List<String>> matchingTransactions,
    required double minSupport,
    required double minConfidence,
  }) {
    final hasItemMatch = itemOccurrence > 0;

    if (!hasItemMatch) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderLine, width: 1.0),
        ),
        child: Column(
          children: [
            const Icon(
              CupertinoIcons.search,
              size: 32,
              color: subtleText,
            ),
            const SizedBox(height: 12),
            Text(
              'Item "$query" Tidak Ditemukan',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tidak ada struk transaksi yang memuat nama item tersebut. Silakan periksa kembali ejaan atau gunakan kata kunci lain.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: mutedText,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderLine, width: 1.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      query,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ditemukan di $itemOccurrence dari $totalTransactions struk',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${itemSupportPercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: gunadarmaPurple,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Support',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: mutedText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ATURAN ASOSIASI (${matchingRules.length})',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: mutedText,
              letterSpacing: 0.6,
            ),
          ),
        ),

        if (matchingRules.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderLine, width: 1.0),
            ),
            child: Text(
              'Item "$query" belum membentuk aturan yang melampaui ambang batas Min. Support (${minSupport.toStringAsFixed(1)}%) dan Min. Confidence (${minConfidence.toStringAsFixed(1)}%).',
              style: const TextStyle(
                fontSize: 12,
                color: mutedText,
                height: 1.4,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderLine, width: 1.0),
            ),
            child: Column(
              children: matchingRules.asMap().entries.map((entry) {
                final index = entry.key;
                final rule = entry.value;
                final isLast = index == matchingRules.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                                        rule.antecedent,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: darkText,
                                        ),
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
                                        rule.consequent,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: gunadarmaPurple,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Conf: ${rule.confidence.toStringAsFixed(1)}%   •   Sup: ${rule.support.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: mutedText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Lift ${rule.lift.toStringAsFixed(2)}x',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                        height: 1,
                        thickness: 0.5,
                        color: Color(0xFFF1F5F9),
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 22),

        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'RIWAYAT STRUK (${matchingTransactions.length})',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: mutedText,
              letterSpacing: 0.6,
            ),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderLine, width: 1.0),
          ),
          child: Column(
            children: matchingTransactions.take(10).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final basket = entry.value;
              final isLast = index == matchingTransactions.take(10).length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Struk #${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: darkText,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '•  ${basket.length} Item',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: mutedText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: basket.asMap().entries.map((itemEntry) {
                                    final iIdx = itemEntry.key;
                                    final item = itemEntry.value;
                                    final isMatched = item.toLowerCase().contains(query.toLowerCase());
                                    final isLastItem = iIdx == basket.length - 1;

                                    return TextSpan(
                                      text: isLastItem ? item : '$item, ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isMatched ? FontWeight.w700 : FontWeight.w400,
                                        color: isMatched ? gunadarmaPurple : bodyText,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Color(0xFFF1F5F9),
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
