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
            final recommendations = _computeRecommendations(state);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 95),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClassicHeroBanner(),
                  const SizedBox(height: 18),
                  _buildCatalogSectionHeader(availableProducts.length, isFromDataset),
                  _buildCatalogCard(availableProducts, isFromDataset),
                  const SizedBox(height: 18),
                  _buildRecommendationsSectionHeader(recommendations.length),
                  _buildRecommendationsCard(recommendations),
                  const SizedBox(height: 10),
                  _buildFootnote(isFromDataset),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildClassicHeroBanner() {
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
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              right: -25,
              top: -25,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UNIVERSITAS GUNADARMA',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.72),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Simulasi Rekomendasi',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih kombinasi produk belanja untuk mengeksplorasi rekomendasi bundling berdasarkan aturan asosiasi Apriori secara realtime.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.86),
                      height: 1.35,
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

  Widget _buildCatalogSectionHeader(int totalItems, bool isFromDataset) {
    final String title = _cartItems.isEmpty
        ? (isFromDataset ? 'PRODUK DATASET ($totalItems)' : 'PILIH PRODUK ($totalItems)')
        : 'PILIH PRODUK (${_cartItems.length} DIPILIH)';

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: slateMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.7),
                ),
                child: Text(
                  isFromDataset ? 'Dataset Excel' : 'Data Sampel',
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          if (_cartItems.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _clearCart,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  'Atur Ulang',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryPurple,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCatalogCard(List<String> products, bool isFromDataset) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: products.map((item) {
              final bool isSelected = _cartItems.contains(item);
              return CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => _toggleProduct(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryPurple : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? primaryPurple : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const Icon(
                          CupertinoIcons.checkmark,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : darkText,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (!isFromDataset) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.7),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.info_circle,
                    size: 14,
                    color: primaryPurple,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Produk di atas adalah sampel. Unggah file Excel/CSV di tab Dataset untuk mengganti daftar ini dengan produk Anda.',
                      style: TextStyle(
                        fontSize: 11,
                        color: slateMuted,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (widget.onNavigateToDataset != null) ...[
                    const SizedBox(width: 6),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: widget.onNavigateToDataset,
                      child: const Text(
                        'Upload →',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsSectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        count == 0 ? 'HASIL REKOMENDASI' : 'HASIL REKOMENDASI ($count)',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: slateMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(List<_RecommendationItem> recommendations) {
    if (_cartItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderSubtle, width: 0.8),
        ),
        child: const Column(
          children: [
            Icon(
              CupertinoIcons.cart,
              size: 28,
              color: slateSubtle,
            ),
            SizedBox(height: 8),
            Text(
              'Keranjang Belum Terisi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Ketuk produk di atas untuk melihat rekomendasi bundling otomatis.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: slateMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (recommendations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
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
                    'Semua produk rekomendasi asosiasi telah dimasukkan ke dalam keranjang.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: slateMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderSubtle, width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recommendations.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            thickness: 0.5,
            indent: 56,
            endIndent: 16,
            color: Color(0xFFF1F5F9),
          ),
          itemBuilder: (context, index) {
            final rec = recommendations[index];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFF3E8FF),
                        width: 0.8,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.sparkles,
                      size: 16,
                      color: primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.targetProduct,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Pasangan dari ${rec.triggerProduct} • Conf: ${rec.rule.confidence.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: slateMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                        ),
                        child: Text(
                          'Lift ${rec.rule.lift.toStringAsFixed(2)}x',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () => _addProduct(rec.targetProduct),
                        child: const Text(
                          '+ Tambah',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: primaryPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFootnote(bool isFromDataset) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        isFromDataset
            ? '• Rekomendasi dihitung seketika menggunakan parameter algoritma Apriori dari dataset yang Anda unggah.'
            : '• Rekomendasi dihitung seketika menggunakan parameter algoritma Apriori Universitas Gunadarma.',
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
