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
  static const Color iosBg = Color(0xFFF2F2F7);
  static const Color iosCardBg = Colors.white;
  static const Color iosBorder = Color(0xFFE5E5EA);
  static const Color iosPillBg = Color(0xFFE9E9EB);
  static const Color iosTextPrimary = Color(0xFF000000);
  static const Color iosTextSecondary = Color(0xFF6C6C70);
  static const Color iosTextTertiary = Color(0xFF8E8E93);

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
      backgroundColor: iosBg,
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1140),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIosHeaderBanner(isFromDataset, availableProducts.length, activeRules.length),
                          const SizedBox(height: 14),
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildIosCartCard(),
                                      const SizedBox(height: 14),
                                      _buildIosCatalogCard(
                                        availableProducts: availableProducts,
                                        filteredProducts: filteredProducts,
                                        popularProducts: popularProducts,
                                        ruleTriggers: ruleTriggers,
                                        isFromDataset: isFromDataset,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildIosRecommendationsCard(recommendations, ruleTriggers),
                                      const SizedBox(height: 10),
                                      _buildIosFootnote(isFromDataset),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildIosCartCard(),
                                const SizedBox(height: 14),
                                _buildIosCatalogCard(
                                  availableProducts: availableProducts,
                                  filteredProducts: filteredProducts,
                                  popularProducts: popularProducts,
                                  ruleTriggers: ruleTriggers,
                                  isFromDataset: isFromDataset,
                                ),
                                const SizedBox(height: 16),
                                _buildIosRecommendationsCard(recommendations, ruleTriggers),
                                const SizedBox(height: 10),
                                _buildIosFootnote(isFromDataset),
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

  Widget _buildIosHeaderBanner(bool isFromDataset, int totalProducts, int totalRules) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: deepPurple,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UNIVERSITAS GUNADARMA • 3KA31',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.72),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Simulasi Rekomendasi Kasir',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Eksplorasi rekomendasi bundling belanja otomatis berdasarkan aturan asosiasi Apriori secara realtime.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$totalRules Aturan Valid',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$totalProducts Produk',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIosCartCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: iosCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iosBorder, width: 0.8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.cart,
                    size: 16,
                    color: primaryPurple,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Keranjang Belanja',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: iosTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: iosPillBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_cartItems.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: iosTextSecondary,
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
                  child: const Text(
                    'Atur Ulang',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_cartItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: iosBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Keranjang masih kosong. Pilih produk pada daftar di bawah untuk menguji rekomendasi.',
                style: TextStyle(
                  fontSize: 12,
                  color: iosTextSecondary,
                  height: 1.35,
                ),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _cartItems.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primaryPurple,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _removeProduct(item),
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 14,
                          color: Colors.white70,
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

  Widget _buildIosCatalogCard({
    required List<String> availableProducts,
    required List<String> filteredProducts,
    required List<String> popularProducts,
    required Set<String> ruleTriggers,
    required bool isFromDataset,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: iosCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iosBorder, width: 0.8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Katalog Produk',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: iosTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                isFromDataset ? '${availableProducts.length} Produk Dataset' : 'Data Sampel',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: iosTextTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CupertinoSearchTextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            placeholder: 'Cari produk...',
            style: const TextStyle(fontSize: 13, color: iosTextPrimary),
            placeholderStyle: const TextStyle(fontSize: 13, color: iosTextTertiary),
            backgroundColor: iosBg,
            borderRadius: BorderRadius.circular(10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          const SizedBox(height: 12),
          if (_searchQuery.isEmpty && popularProducts.isNotEmpty) ...[
            const Text(
              'Pilihan Populer',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: iosTextSecondary,
                letterSpacing: -0.1,
              ),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryPurple
                          : (isTrigger ? const Color(0xFFF3E8FF) : iosPillBg),
                      borderRadius: BorderRadius.circular(8),
                      border: isTrigger && !isSelected
                          ? Border.all(color: const Color(0xFFD8B4FE), width: 0.8)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(CupertinoIcons.checkmark, size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          item,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isTrigger ? primaryPurple : iosTextPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: iosBorder),
            const SizedBox(height: 10),
          ],
          Text(
            _searchQuery.isEmpty
                ? 'Semua Produk (${availableProducts.length})'
                : 'Hasil Pencarian (${filteredProducts.length})',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: iosTextSecondary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iosBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Text(
                      'Produk tidak ditemukan.',
                      style: TextStyle(fontSize: 12, color: iosTextTertiary),
                    ),
                  )
                : CupertinoScrollbar(
                    child: SingleChildScrollView(
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryPurple : iosCardBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryPurple
                                      : (isTrigger ? const Color(0xFFD8B4FE) : iosBorder),
                                  width: 0.6,
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
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected
                                          ? Colors.white
                                          : (isTrigger ? primaryPurple : iosTextPrimary),
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
          ),
        ],
      ),
    );
  }

  Widget _buildIosRecommendationsCard(
    List<_RecommendationItem> recommendations,
    Set<String> ruleTriggers,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: iosCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iosBorder, width: 0.8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rekomendasi Bundling',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: iosTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: recommendations.isNotEmpty
                      ? const Color(0xFFDCFCE7)
                      : iosPillBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${recommendations.length} Rekomendasi',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: recommendations.isNotEmpty
                        ? const Color(0xFF166534)
                        : iosTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_cartItems.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: iosBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Icon(
                    CupertinoIcons.cube_box,
                    size: 30,
                    color: iosTextTertiary,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Menunggu Input Keranjang',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: iosTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilih produk belanja di sebelah kiri untuk melihat rekomendasi cross-selling otomatis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: iosTextSecondary,
                      height: 1.35,
                    ),
                  ),
                  if (ruleTriggers.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Pilihan pemicu aturan yang tersedia:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: iosTextSecondary,
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
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: iosCardBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: iosBorder, width: 0.8),
                            ),
                            child: Text(
                              trigger,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: primaryPurple,
                              ),
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iosBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle,
                    size: 18,
                    color: primaryPurple,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tidak ada aturan rekomendasi baru untuk kombinasi keranjang saat ini.',
                      style: TextStyle(
                        fontSize: 12,
                        color: iosTextSecondary,
                      ),
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
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final rec = recommendations[index];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: iosBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: iosBorder, width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rec.targetProduct,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: iosTextPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Dipicu oleh: ${rec.triggerProduct}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: primaryPurple,
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
                            child: const Text(
                              '+ Tambah',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: iosCardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: iosBorder, width: 0.6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildIosMetricItem(
                              label: 'Confidence',
                              value: '${rec.rule.confidence.toStringAsFixed(1)}%',
                            ),
                            Container(width: 1, height: 18, color: iosBorder),
                            _buildIosMetricItem(
                              label: 'Support',
                              value: '${rec.rule.support.toStringAsFixed(1)}%',
                            ),
                            Container(width: 1, height: 18, color: iosBorder),
                            _buildIosMetricItem(
                              label: 'Lift',
                              value: '${rec.rule.lift.toStringAsFixed(2)}x',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pola transaksi: Pembeli ${rec.triggerProduct} berkemungkinan membeli ${rec.targetProduct}.',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: iosTextSecondary,
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

  Widget _buildIosMetricItem({
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: iosTextPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
            color: iosTextTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildIosFootnote(bool isFromDataset) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        isFromDataset
            ? 'Rekomendasi dihitung otomatis menggunakan algoritma Apriori berdasarkan dataset transaksi yang diunggah.'
            : 'Rekomendasi dihitung otomatis menggunakan parameter algoritma Apriori Universitas Gunadarma.',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w400,
          color: iosTextTertiary,
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
