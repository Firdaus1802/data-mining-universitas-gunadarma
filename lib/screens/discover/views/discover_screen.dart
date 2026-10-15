import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shop/models/apriori_state_manager.dart';

class DiscoverScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDataset;

  const DiscoverScreen({
    super.key,
    this.onNavigateToDataset,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final Set<String> _cartItems = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color primaryPurple = Color(0xFF4A148C);
  static const Color deepPurple = Color(0xFF2E1065);
  static const Color darkText = Color(0xFF0F172A);
  static const Color slateMuted = Color(0xFF64748B);
  static const Color slateSubtle = Color(0xFF94A3B8);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color borderSubtle = Color(0xFFE2E8F0);

  static const List<String> _fallbackItems = [
    'Roti',
    'Mentega',
    'Susu',
    'Kopi',
    'Gula',
    'Selai',
    'Keju',
    'Biskuit',
  ];

  static const List<AprioriRuleSummary> _fallbackRules = [
    AprioriRuleSummary(
      antecedent: 'Gula',
      consequent: 'Kopi',
      support: 20.0,
      confidence: 100.0,
      lift: 5.0,
    ),
    AprioriRuleSummary(
      antecedent: 'Kopi',
      consequent: 'Gula',
      support: 20.0,
      confidence: 66.7,
      lift: 5.0,
    ),
    AprioriRuleSummary(
      antecedent: 'Mentega',
      consequent: 'Roti',
      support: 60.0,
      confidence: 100.0,
      lift: 1.25,
    ),
    AprioriRuleSummary(
      antecedent: 'Roti',
      consequent: 'Mentega',
      support: 60.0,
      confidence: 75.0,
      lift: 1.25,
    ),
    AprioriRuleSummary(
      antecedent: 'Selai',
      consequent: 'Mentega',
      support: 20.0,
      confidence: 100.0,
      lift: 1.67,
    ),
    AprioriRuleSummary(
      antecedent: 'Selai',
      consequent: 'Roti',
      support: 20.0,
      confidence: 100.0,
      lift: 1.25,
    ),
    AprioriRuleSummary(
      antecedent: 'Susu',
      consequent: 'Roti',
      support: 20.0,
      confidence: 100.0,
      lift: 1.25,
    ),
    AprioriRuleSummary(
      antecedent: 'Keju',
      consequent: 'Mentega',
      support: 20.0,
      confidence: 100.0,
      lift: 1.43,
    ),
    AprioriRuleSummary(
      antecedent: 'Biskuit',
      consequent: 'Kopi',
      support: 10.0,
      confidence: 100.0,
      lift: 3.33,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getAvailableProducts(AprioriStateManager state) {
    if (state.transactions.isNotEmpty) {
      final items = state.transactions
          .expand((t) => t)
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      items.sort();
      if (items.isNotEmpty) return items;
    }
    return _fallbackItems;
  }

  List<AprioriRuleSummary> _getActiveRules(AprioriStateManager state) {
    if (state.rules.isNotEmpty) {
      return state.rules;
    }
    return _fallbackRules;
  }

  Set<String> _getRuleTriggerProducts(List<AprioriRuleSummary> rules) {
    final Set<String> triggers = {};
    for (final r in rules) {
      final parts = r.antecedent.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
      triggers.addAll(parts);
    }
    return triggers;
  }

  List<String> _getPopularProducts(AprioriStateManager state, List<AprioriRuleSummary> rules) {
    final triggers = _getRuleTriggerProducts(rules);
    if (state.transactions.isNotEmpty) {
      final Map<String, int> counts = {};
      for (final tx in state.transactions) {
        for (final item in tx) {
          final clean = item.trim();
          if (clean.isNotEmpty) {
            counts[clean] = (counts[clean] ?? 0) + 1;
          }
        }
      }
      final sorted = counts.keys.toList()
        ..sort((a, b) {
          final aIsTrig = triggers.contains(a);
          final bIsTrig = triggers.contains(b);
          if (aIsTrig && !bIsTrig) return -1;
          if (!aIsTrig && bIsTrig) return 1;
          return counts[b]!.compareTo(counts[a]!);
        });
      return sorted.take(8).toList();
    }
    return _fallbackItems.take(5).toList();
  }

  List<_RecommendationItem> _computeRecommendations(AprioriStateManager state) {
    if (_cartItems.isEmpty) return [];

    final activeRules = _getActiveRules(state);
    final normalizedCart = _cartItems.map((e) => e.toLowerCase().trim()).toSet();
    final Map<String, _RecommendationItem> candidateMap = {};

    for (final rule in activeRules) {
      final anteParts = rule.antecedent
          .split(',')
          .map((e) => e.toLowerCase().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final consqParts = rule.consequent
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (anteParts.isEmpty || consqParts.isEmpty) continue;

      final bool anteMatches = anteParts.every((item) => normalizedCart.contains(item));
      if (!anteMatches) continue;

      for (final consqItem in consqParts) {
        if (!normalizedCart.contains(consqItem.toLowerCase())) {
          final existing = candidateMap[consqItem.toLowerCase()];
          if (existing == null || rule.lift > existing.rule.lift) {
            candidateMap[consqItem.toLowerCase()] = _RecommendationItem(
              targetProduct: consqItem,
              triggerProduct: rule.antecedent,
              rule: rule,
            );
          }
        }
      }
    }

    final list = candidateMap.values.toList();
    list.sort((a, b) {
      final liftComp = b.rule.lift.compareTo(a.rule.lift);
      if (liftComp != 0) return liftComp;
      return b.rule.confidence.compareTo(a.rule.confidence);
    });
    return list;
  }

  void _toggleProduct(String product) {
    setState(() {
      if (_cartItems.contains(product)) {
        _cartItems.remove(product);
      } else {
        _cartItems.add(product);
      }
    });
  }

  void _addProduct(String product) {
    setState(() {
      _cartItems.add(product);
    });
  }

  void _removeProduct(String product) {
    setState(() {
      _cartItems.remove(product);
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: AprioriStateManager.instance,
          builder: (context, _) {
            final state = AprioriStateManager.instance;
            final bool isFromDataset = state.transactions.isNotEmpty;
            final availableProducts = _getAvailableProducts(state);
            final activeRules = _getActiveRules(state);
            final ruleTriggers = _getRuleTriggerProducts(activeRules);
            final popularProducts = _getPopularProducts(state, activeRules);
            final recommendations = _computeRecommendations(state);

            final filteredProducts = _searchQuery.isEmpty
                ? availableProducts
                : availableProducts
                    .where((p) => p.toLowerCase().contains(_searchQuery.toLowerCase().trim()))
                    .toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final bool isDesktop = constraints.maxWidth >= 900;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 95),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroBanner(isFromDataset, availableProducts.length, activeRules.length),
                          const SizedBox(height: 18),
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildCartSection(),
                                      const SizedBox(height: 16),
                                      _buildCatalogCard(
                                        availableProducts: availableProducts,
                                        filteredProducts: filteredProducts,
                                        popularProducts: popularProducts,
                                        ruleTriggers: ruleTriggers,
                                        isFromDataset: isFromDataset,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildRecommendationsSection(recommendations, ruleTriggers),
                                      const SizedBox(height: 12),
                                      _buildFootnote(isFromDataset),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCartSection(),
                                const SizedBox(height: 16),
                                _buildCatalogCard(
                                  availableProducts: availableProducts,
                                  filteredProducts: filteredProducts,
                                  popularProducts: popularProducts,
                                  ruleTriggers: ruleTriggers,
                                  isFromDataset: isFromDataset,
                                ),
                                const SizedBox(height: 20),
                                _buildRecommendationsSection(recommendations, ruleTriggers),
                                const SizedBox(height: 12),
                                _buildFootnote(isFromDataset),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroBanner(bool isFromDataset, int totalProducts, int totalRules) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            deepPurple,
            primaryPurple,
            Color(0xFF581C87),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -25,
              top: -25,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'SIMULASI KASIR POS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'UNIVERSITAS GUNADARMA',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.75),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Rekomendasi Bundling Otomatis',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Uji coba kombinasi produk belanja untuk melihat rekomendasi cross-selling berbasis aturan asosiasi Apriori secara realtime.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$totalRules Aturan Valid',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$totalProducts Produk Aktif',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle, width: 0.8),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryPurple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.cart_fill,
                      size: 15,
                      color: primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Keranjang Belanja Aktif',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _cartItems.isEmpty
                          ? const Color(0xFFF1F5F9)
                          : primaryPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_cartItems.length} Item',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _cartItems.isEmpty ? slateMuted : primaryPurple,
                      ),
                    ),
                  ),
                ],
              ),
              if (_cartItems.isNotEmpty)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: _clearCart,
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.trash, size: 13, color: Color(0xFFDC2626)),
                      SizedBox(width: 4),
                      Text(
                        'Kosongkan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_cartItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.6),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.info_circle, size: 16, color: slateMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Keranjang masih kosong. Pilih produk di katalog bawah untuk menguji rekomendasi bundling kasir.',
                      style: TextStyle(
                        fontSize: 12,
                        color: slateMuted,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _cartItems.map((item) {
                return Container(
                  padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
                  decoration: BoxDecoration(
                    color: primaryPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeProduct(item),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.clear,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCatalogCard({
    required List<String> availableProducts,
    required List<String> filteredProducts,
    required List<String> popularProducts,
    required Set<String> ruleTriggers,
    required bool isFromDataset,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle, width: 0.8),
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
              const Text(
                'Katalog Produk',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.7),
                ),
                child: Text(
                  isFromDataset ? '${availableProducts.length} Produk Dataset' : 'Data Sampel',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(CupertinoIcons.search, size: 16, color: slateMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(fontSize: 12.5, color: darkText),
                    decoration: const InputDecoration(
                      hintText: 'Cari produk (misal: milk, sausage, beer)...',
                      hintStyle: TextStyle(fontSize: 12, color: slateSubtle),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: const Icon(CupertinoIcons.clear_circled_solid, size: 15, color: slateSubtle),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_searchQuery.isEmpty && popularProducts.isNotEmpty) ...[
            const Row(
              children: [
                Icon(CupertinoIcons.bolt_fill, size: 13, color: Color(0xFFD97706)),
                SizedBox(width: 5),
                Text(
                  'Pilihan Cepat (Produk Populer & Pemicu Rekomendasi):',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: popularProducts.map((item) {
                final isSelected = _cartItems.contains(item);
                final isTrigger = ruleTriggers.contains(item);

                return CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => _toggleProduct(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryPurple
                          : (isTrigger ? const Color(0xFFFAF5FF) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? primaryPurple
                            : (isTrigger ? const Color(0xFFD8B4FE) : const Color(0xFFE2E8F0)),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(CupertinoIcons.checkmark, size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                        ] else if (isTrigger) ...[
                          const Icon(CupertinoIcons.sparkles, size: 11, color: primaryPurple),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          item,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w700 : (isTrigger ? FontWeight.w700 : FontWeight.w600),
                            color: isSelected ? Colors.white : (isTrigger ? primaryPurple : darkText),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _searchQuery.isEmpty
                    ? 'Semua Produk (${availableProducts.length})'
                    : 'Hasil Pencarian (${filteredProducts.length})',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: slateMuted,
                  letterSpacing: 0.3,
                ),
              ),
              if (_searchQuery.isNotEmpty)
                Text(
                  'Menampilkan "$_searchQuery"',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: slateSubtle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 220,
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.7),
            ),
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Text(
                      'Produk tidak ditemukan.',
                      style: TextStyle(fontSize: 12, color: slateMuted),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: filteredProducts.map((item) {
                        final isSelected = _cartItems.contains(item);
                        final isTrigger = ruleTriggers.contains(item);

                        return CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () => _toggleProduct(item),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryPurple : Colors.white,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: isSelected
                                    ? primaryPurple
                                    : (isTrigger ? const Color(0xFFD8B4FE) : const Color(0xFFE2E8F0)),
                                width: 0.7,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const Icon(CupertinoIcons.checkmark, size: 10, color: Colors.white),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  item,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : (isTrigger ? primaryPurple : darkText),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(
    List<_RecommendationItem> recommendations,
    Set<String> ruleTriggers,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle, width: 0.8),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryPurple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.sparkles,
                      size: 15,
                      color: primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Hasil Rekomendasi Bundling',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: recommendations.isNotEmpty
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: recommendations.isNotEmpty
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFE2E8F0),
                    width: 0.7,
                  ),
                ),
                child: Text(
                  '${recommendations.length} Rekomendasi',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: recommendations.isNotEmpty
                        ? const Color(0xFF166534)
                        : slateMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_cartItems.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryPurple.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.chart_pie,
                      size: 24,
                      color: primaryPurple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Menunggu Input Keranjang',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih produk belanja di sebelah kiri untuk melihat rekomendasi cross-selling otomatis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: slateMuted,
                      height: 1.35,
                    ),
                  ),
                  if (ruleTriggers.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Coba klik salah satu pemicu aturan ini:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: ruleTriggers.take(4).map((trigger) {
                        return CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () => _addProduct(trigger),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF5FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFD8B4FE), width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.add, size: 10, color: primaryPurple),
                                const SizedBox(width: 4),
                                Text(
                                  trigger,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: primaryPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (recommendations.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
              ),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    size: 20,
                    color: Color(0xFF334155),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keranjang Belanja Optimal',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Semua produk rekomendasi asosiasi telah dimasukkan atau tidak ada aturan baru untuk kombinasi ini.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: slateMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recommendations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rec = recommendations[index];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE9D5FF),
                      width: 0.9,
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
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFD8B4FE),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.sparkles,
                                    size: 16,
                                    color: primaryPurple,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rec.targetProduct,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: darkText,
                                        ),
                                      ),
                                      Text(
                                        'Dipicu oleh: ${rec.triggerProduct}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: primaryPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            minimumSize: Size.zero,
                            color: primaryPurple,
                            borderRadius: BorderRadius.circular(8),
                            onPressed: () => _addProduct(rec.targetProduct),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.add, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Tambah',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE9D5FF), width: 0.7),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricItem(
                              label: 'Confidence',
                              value: '${rec.rule.confidence.toStringAsFixed(1)}%',
                              color: const Color(0xFF7C3AED),
                            ),
                            Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
                            _buildMetricItem(
                              label: 'Support',
                              value: '${rec.rule.support.toStringAsFixed(1)}%',
                              color: const Color(0xFF0284C7),
                            ),
                            Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
                            _buildMetricItem(
                              label: 'Lift Ratio',
                              value: '${rec.rule.lift.toStringAsFixed(2)}x',
                              color: const Color(0xFF16A34A),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Peluang cross-selling: Pembeli ${rec.triggerProduct} berpeluang tinggi membeli ${rec.targetProduct} bersamaan.',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          color: slateMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: slateSubtle,
          ),
        ),
      ],
    );
  }

  Widget _buildFootnote(bool isFromDataset) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        isFromDataset
            ? '• Rekomendasi dihitung otomatis menggunakan algoritma Apriori berdasarkan dataset transaksi yang Anda unggah.'
            : '• Rekomendasi dihitung otomatis menggunakan parameter algoritma Apriori Universitas Gunadarma.',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: slateSubtle,
          height: 1.3,
        ),
      ),
    );
  }
}

class _RecommendationItem {
  final String targetProduct;
  final String triggerProduct;
  final AprioriRuleSummary rule;

  const _RecommendationItem({
    required this.targetProduct,
    required this.triggerProduct,
    required this.rule,
  });
}
