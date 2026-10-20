import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shop/models/apriori_state_manager.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToDataset;
  final VoidCallback? onNavigateToDiscover;
  final String? userName;

  const HomeScreen({
    super.key,
    this.onNavigateToDataset,
    this.onNavigateToDiscover,
    this.userName,
  });

  static const Color gunadarmaPurple = Color(0xFF581C87);
  static const Color accentPurple = Color(0xFF7E22CE);
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color textBody = Color(0xFF334155);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textSubtle = Color(0xFF9CA3AF);
  static const Color borderLine = Color(0xFFEDE9FE);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color pageBg = Color(0xFFFBFBFE);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AprioriStateManager.instance,
      builder: (context, _) {
        final state = AprioriStateManager.instance;
        final totalTransactions = state.totalTransactions;
        final totalRules = state.totalRules;
        final minSupport = state.minSupport.toStringAsFixed(1);
        final minConf = state.minConfidence.toStringAsFixed(1);
        final isDataLoaded = state.isDataLoaded;
        final resolvedName = state.userName.isNotEmpty
            ? state.userName
            : (userName != null && userName!.isNotEmpty ? userName! : '');
        final bool isDesktop = MediaQuery.of(context).size.width >= 960;

        return Scaffold(
          backgroundColor: pageBg,
          body: SafeArea(
            top: false,
            bottom: false,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGrandHeroBanner(context, resolvedName),
                      const SizedBox(height: 18),
                      if (isDesktop) ...[
                        _buildSectionHeader('RINGKASAN METRIK OPERASIONAL'),
                        _buildDesktopHomeKPIStrip(
                          totalTransactions: totalTransactions,
                          totalRules: totalRules,
                          minSupport: minSupport,
                          minConf: minConf,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader('PARAMETER ALGORITMA'),
                                  _buildParameterConfigPanel(
                                    minSupport: minSupport,
                                    minConf: minConf,
                                    isDataLoaded: isDataLoaded,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 8,
                              child: _buildRealtimeRulesStreamSection(context, state),
                            ),
                          ],
                        ),
                      ] else ...[
                        _buildSectionHeader('RINGKASAN DATASET'),
                        _buildRealtimeMetrics(
                          totalTransactions: totalTransactions,
                          totalRules: totalRules,
                        ),
                        const SizedBox(height: 18),
                        _buildSectionHeader('PARAMETER ALGORITMA'),
                        _buildParameterConfigPanel(
                          minSupport: minSupport,
                          minConf: minConf,
                          isDataLoaded: isDataLoaded,
                        ),
                        const SizedBox(height: 18),
                        _buildRealtimeRulesStreamSection(context, state),
                      ],
                      const SizedBox(height: 28),
                      _buildAcademicCreditsFooter(),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: textMuted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildGrandHeroBanner(BuildContext context, [String? currentName]) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E0A38),
            Color(0xFF2E1065),
            Color(0xFF3B0764),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E0A38).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    'UNIVERSITAS GUNADARMA',
                    style: TextStyle(
                      fontFamily: "Plus Jakarta",
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => _showSystemInfoModal(context),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                        width: 0.8,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.info,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Hai, Selamat Datang!',
              style: TextStyle(
                fontFamily: "Plus Jakarta",
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Apa yang ingin Anda lakukan hari ini?',
              style: TextStyle(
                fontFamily: "Plus Jakarta",
                color: Color(0xFFE9D5FF),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih menu di bawah untuk mengelola dataset transaksi belanja atau mencoba simulasi rekomendasi kasir berbasis Algoritma Apriori.',
              style: TextStyle(
                fontFamily: "Plus Jakarta",
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (onNavigateToDataset != null)
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                      onPressed: onNavigateToDataset,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.doc_text_fill, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Dataset Transaksi',
                            style: TextStyle(
                              fontFamily: "Plus Jakarta",
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (onNavigateToDataset != null && onNavigateToDiscover != null)
                  const SizedBox(width: 8),
                if (onNavigateToDiscover != null)
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      onPressed: onNavigateToDiscover,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.cart_fill, size: 14, color: Color(0xFF2E1065)),
                          SizedBox(width: 6),
                          Text(
                            'Simulasi Kasir',
                            style: TextStyle(
                              fontFamily: "Plus Jakarta",
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E1065),
                              letterSpacing: -0.1,
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
    );
  }

  Widget _buildRealtimeMetrics({
    required int totalTransactions,
    required int totalRules,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'TRANSAKSI',
            value: '$totalTransactions',
            unit: 'Struk Belanja',
            icon: CupertinoIcons.doc_text,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            label: 'ATURAN ASOSIASI',
            value: '$totalRules',
            unit: 'Aturan Valid',
            icon: CupertinoIcons.arrow_branch,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHomeKPIStrip({
    required int totalTransactions,
    required int totalRules,
    required String minSupport,
    required String minConf,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'TOTAL TRANSAKSI',
            value: '$totalTransactions',
            unit: 'Struk Belanja',
            icon: CupertinoIcons.doc_text,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            label: 'ATURAN ASOSIASI',
            value: '$totalRules',
            unit: 'Kaidah Valid',
            icon: CupertinoIcons.arrow_branch,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            label: 'MINIMUM SUPPORT',
            value: '$minSupport%',
            unit: 'Ambang Frekuensi',
            icon: CupertinoIcons.percent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            label: 'MINIMUM CONFIDENCE',
            value: '$minConf%',
            unit: 'Ambang Kepastian',
            icon: CupertinoIcons.shield_fill,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLine, width: 0.8),
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
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(7.5),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: darkText,
              letterSpacing: -0.6,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterConfigPanel({
    required String minSupport,
    required String minConf,
    required bool isDataLoaded,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLine, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildParamRow(
            icon: CupertinoIcons.slider_horizontal_3,
            label: 'Minimum Support',
            value: '$minSupport%',
          ),
          const Divider(height: 1, thickness: 0.5, indent: 58, endIndent: 16, color: borderLine),
          _buildParamRow(
            icon: CupertinoIcons.gauge,
            label: 'Minimum Confidence',
            value: '$minConf%',
          ),
          const Divider(height: 1, thickness: 0.5, indent: 58, endIndent: 16, color: borderLine),
          _buildParamRow(
            icon: CupertinoIcons.function,
            label: 'Mesin Algoritma',
            value: 'Apriori Mining',
          ),
          const Divider(height: 1, thickness: 0.5, indent: 58, endIndent: 16, color: borderLine),
          _buildParamStatusRow(isDataLoaded: isDataLoaded),
        ],
      ),
    );
  }

  Widget _buildParamRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(7.5),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Icon(
              icon,
              size: 15,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: darkText,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: darkText,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamStatusRow({required bool isDataLoaded}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(7.5),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Icon(
              isDataLoaded ? CupertinoIcons.checkmark_alt : CupertinoIcons.circle_grid_hex,
              size: 15,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Status Pemrosesan',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: darkText,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDataLoaded ? const Color(0xFF0F766E) : textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isDataLoaded ? 'Terproses' : 'Standby',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeRulesStreamSection(BuildContext context, AprioriStateManager state) {
    final rules = state.rules;
    final hasRules = rules.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader('KAIDAH ASOSIASI AKTIF'),
            if (hasRules)
              GestureDetector(
                onTap: onNavigateToDataset,
                child: const Padding(
                  padding: EdgeInsets.only(right: 4, bottom: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Kelola',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: gunadarmaPurple,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(CupertinoIcons.chevron_right, size: 10, color: gunadarmaPurple),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (!hasRules)
          _buildEmptyRulesCard(context)
        else if (MediaQuery.of(context).size.width >= 960)
          _buildDesktopHomeRulesDataTable(rules)
        else
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderLine, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _buildTopRulesList(rules),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopHomeRulesDataTable(List<AprioriRuleSummary> rules) {
    final displayRules = rules.take(10).toList();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLine, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: borderLine, width: 0.8)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    'NO',
                    style: TextStyle(
                      fontFamily: "Plus Jakarta",
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Tooltip(
                    message: 'Antecedent (X): Produk yang dibeli dalam transaksi',
                    child: Text(
                      'ANTECEDENT (X)',
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Tooltip(
                    message: 'Consequent (Y): Produk yang direkomendasikan sistem jika X dibeli',
                    child: Text(
                      'CONSEQUENT (Y)',
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Tooltip(
                    message: 'Support = P(X ∩ Y): Rasio transaksi bersama terhadap total transaksi',
                    child: Text(
                      'SUPPORT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Tooltip(
                    message: 'Confidence = P(Y|X) = Support(X ∪ Y) / Support(X): Kepastian aturan asosiasi',
                    child: Text(
                      'CONFIDENCE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Tooltip(
                    message: 'Lift Ratio = Confidence / Support(Y): Nilai > 1.0 membuktikan asosiasi positif kuat',
                    child: Text(
                      'LIFT RATIO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Tooltip(
                    message: 'Korelasi: Sangat Kuat (Lift ≥ 1.0) menunjukkan peningkatan penjualan yang nyata',
                    child: Text(
                      'KORELASI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 0.5,
                      ),
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
              final rule = displayRules[idx];
              final isEven = idx % 2 == 0;
              final isPositiveLift = rule.lift >= 1.0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isEven ? Colors.white : const Color(0xFFFAFAFC),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        '#${idx + 1}',
                        style: const TextStyle(
                          fontFamily: "Plus Jakarta",
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _formatItemName(rule.antecedent),
                        style: const TextStyle(
                          fontFamily: "Plus Jakarta",
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.arrow_right,
                            size: 11,
                            color: gunadarmaPurple,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _formatItemName(rule.consequent),
                              style: const TextStyle(
                                fontFamily: "Plus Jakarta",
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: gunadarmaPurple,
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
                      flex: 2,
                      child: Text(
                        '${rule.support.toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: "Plus Jakarta",
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
                        '${rule.confidence.toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: "Plus Jakarta",
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
                        '${rule.lift.toStringAsFixed(2)}x',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Plus Jakarta",
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isPositiveLift ? const Color(0xFF059669) : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPositiveLift ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isPositiveLift ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            isPositiveLift ? 'Sangat Kuat' : 'Kurang Kuat',
                            style: TextStyle(
                              fontFamily: "Plus Jakarta",
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isPositiveLift ? const Color(0xFF059669) : const Color(0xFF64748B),
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
          if (rules.length > 10)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Menampilkan 10 dari ${rules.length} aturan asosiasi aktif',
                style: const TextStyle(fontFamily: "Plus Jakarta", fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyRulesCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLine, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(color: borderLine, width: 0.8),
            ),
            child: const Icon(
              CupertinoIcons.tray,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Aturan Terbentuk',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: darkText,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Unggah atau input transaksi di tab Dataset untuk mengekstrak pola aturan asosiasi secara live.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            color: gunadarmaPurple,
            borderRadius: BorderRadius.circular(10),
            onPressed: onNavigateToDataset,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Buka Tab Dataset',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 4),
                Icon(CupertinoIcons.arrow_right, size: 11, color: Colors.white),
              ],
            ),
          ),
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

  List<Widget> _buildTopRulesList(List<AprioriRuleSummary> rules) {
    final topRules = rules.take(3).toList();
    final List<Widget> items = [];

    for (int i = 0; i < topRules.length; i++) {
      final rule = topRules[i];
      final isPositiveLift = rule.lift >= 1.0;

      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: gunadarmaPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: gunadarmaPurple.withValues(alpha: 0.16),
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '#${i + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: gunadarmaPurple,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _formatItemName(rule.antecedent),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: darkText,
                              letterSpacing: -0.2,
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
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _formatItemName(rule.consequent),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: gunadarmaPurple,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'Support ${rule.support.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            '•',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                        Text(
                          'Confidence ${rule.confidence.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isPositiveLift ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isPositiveLift ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'Lift ${rule.lift.toStringAsFixed(2)}x',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isPositiveLift ? const Color(0xFF047857) : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (i < topRules.length - 1) {
        items.add(
          const Divider(
            height: 1,
            thickness: 0.5,
            indent: 56,
            endIndent: 16,
            color: borderLine,
          ),
        );
      }
    }

    return items;
  }

  Widget _buildAcademicCreditsFooter() {
    return Center(
      child: Column(
        children: [
          const Text(
            'UNIVERSITAS GUNADARMA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'S1 Sistem Informasi • Kelas 3KA31 • Kelompok 4 © 2026',
            style: TextStyle(
              fontSize: 10,
              color: textMuted.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoModalContent(BuildContext context, VoidCallback onClose) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: borderLine, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset("assets/logo/gunadarma.png"),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "UNIVERSITAS GUNADARMA",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: darkText,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "S1 Sistem Informasi • Kelas 3KA31 • Kelompok 4",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: accentPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Text(
                              "v1.0.0",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: borderLine),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ringkasan Eksekutif Sistem",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: darkText,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Sistem ini dirancang untuk mengimplementasikan analisis pola belanja konsumen (Market Basket Analysis) secara komprehensif pada transaksi e-commerce. Melalui penerapan algoritma Apriori, sistem mengekstraksi aturan asosiasi yang valid guna mendukung pengambilan keputusan berbasis data dan strategi bundling produk komplementer.",
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: textBody,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "Pilar Analisis & Metodologi:",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: darkText,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSystemInfoCard(
                        number: "01",
                        title: "Market Basket Analysis (MBA)",
                        desc: "Menganalisis keterkaitan antar produk dalam keranjang belanja pelanggan guna mendeteksi itemset frekuen yang sering dibeli secara bersamaan.",
                      ),
                      const SizedBox(height: 10),
                      _buildSystemInfoCard(
                        number: "02",
                        title: "Algoritma Apriori & Metrik Evaluasi",
                        desc: "Menghitung parameter Support (frekuensi kemunculan), Confidence (kepastian aturan), dan Lift Ratio (kekuatan korelasi) untuk menghasilkan aturan asosiasi yang valid.",
                      ),
                      const SizedBox(height: 10),
                      _buildSystemInfoCard(
                        number: "03",
                        title: "Rekomendasi Bundling & Cross-Selling",
                        desc: "Menyediakan rekomendasi penataan produk komplementer untuk meningkatkan performa penjualan dan mengoptimalkan nilai rata-rata transaksi e-commerce.",
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Metodologi: CRISP-DM",
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: textMuted,
                              ),
                            ),
                            Text(
                              "Basis Data: Transaksi Realtime",
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: gunadarmaPurple,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onPressed: onClose,
                  child: const Text(
                    "Tutup Informasi Sistem",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
  }

  void _showSystemInfoModal(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (dialogCtx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 740),
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: _buildSystemInfoModalContent(
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
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: _buildSystemInfoModalContent(
                  context,
                  () => Navigator.pop(sheetContext),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildSystemInfoCard({
    required String number,
    required String title,
    required String desc,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDDD6FE), width: 1.0),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: gunadarmaPurple,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    fontSize: 11,
                    color: textBody,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
