import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shop/models/apriori_state_manager.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/screens/apriori/views/academic_reference_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color gunadarmaPurple = Color(0xFF581C87);
  static const Color accentPurple = Color(0xFF7E22CE);
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color borderLine = Color(0xFFEDE9FE);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color pageBg = Color(0xFFFBFBFE);
  static const Color purpleTint = Color(0xFFF3E8FF);
  static const Color purpleLightPill = Color(0xFFFAF5FF);
  static const Color destructiveRed = Color(0xFFFF3B30);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListenableBuilder(
          listenable: AprioriStateManager.instance,
          builder: (context, _) {
            final state = AprioriStateManager.instance;
            final displayName = state.userName.isNotEmpty ? state.userName : "Firdaus Dhuha Prabowo";
            final email = "${displayName.toLowerCase().replaceAll(' ', '.')}@gunadarma.ac.id";

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1140 : 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPageHeader(context, isDesktop),
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
                                  _buildAppleIdHeaderCard(context, state, displayName, email),
                                  const SizedBox(height: 20),
                                  _buildTeamMembersCard(context, state),
                                  const SizedBox(height: 20),
                                  _buildAcademicInfoCard(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDatabaseSection(context, state),
                                  const SizedBox(height: 20),
                                  _buildAprioriConfigSection(state),
                                  const SizedBox(height: 20),
                                  _buildSystemSection(context, state),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAppleIdHeaderCard(context, state, displayName, email),
                            const SizedBox(height: 20),
                            _buildTeamMembersCard(context, state),
                            const SizedBox(height: 20),
                            _buildAcademicInfoCard(),
                            const SizedBox(height: 20),
                            _buildDatabaseSection(context, state),
                            const SizedBox(height: 20),
                            _buildAprioriConfigSection(state),
                            const SizedBox(height: 20),
                            _buildSystemSection(context, state),
                          ],
                        ),
                      const SizedBox(height: 32),
                      _buildFooter(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLine, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06581C87),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: purpleTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderLine),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              "assets/logo/gunadarma.png",
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                CupertinoIcons.gear_alt_fill,
                color: gunadarmaPurple,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Pengaturan & Profil Akademik",
                  style: TextStyle(
                    fontFamily: "Plus Jakarta",
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Universitas Gunadarma • S1 Sistem Informasi • 3KA31",
                  style: TextStyle(
                    fontFamily: "Plus Jakarta",
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: purpleLightPill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderLine),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    size: 13,
                    color: gunadarmaPurple,
                  ),
                  SizedBox(width: 5),
                  Text(
                    "Sistem Aktif",
                    style: TextStyle(
                      fontFamily: "Plus Jakarta",
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: gunadarmaPurple,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppleIdHeaderCard(
    BuildContext context,
    AprioriStateManager state,
    String displayName,
    String email,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLine, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06581C87),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [gunadarmaPurple, accentPurple],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gunadarmaPurple.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(displayName),
                style: const TextStyle(
                  fontFamily: "Plus Jakarta",
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontFamily: "Plus Jakarta",
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: purpleLightPill,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderLine),
                      ),
                      child: const Text(
                        "10124497",
                        style: TextStyle(
                          fontFamily: "Plus Jakarta",
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: gunadarmaPurple,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Ketua Kelompok 4",
                      style: TextStyle(
                        fontFamily: "Plus Jakarta",
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: gunadarmaPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  "S1 Sistem Informasi • Kelas 3KA31",
                  style: TextStyle(
                    fontFamily: "Plus Jakarta",
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: purpleLightPill,
            borderRadius: BorderRadius.circular(8),
            onPressed: () => _showEditUserNameDialog(context, state, displayName),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.pencil,
                  size: 13,
                  color: gunadarmaPurple,
                ),
                SizedBox(width: 4),
                Text(
                  "Ubah",
                  style: TextStyle(
                    fontFamily: "Plus Jakarta",
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: gunadarmaPurple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return "FD";
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return "${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}".toUpperCase();
  }

  void _showEditUserNameDialog(BuildContext context, AprioriStateManager state, String currentName) {
    final controller = TextEditingController(text: currentName);
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Ubah Nama Profil"),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: "Nama Lengkap",
            autofocus: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                state.setUserName(newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMembersCard(BuildContext context, AprioriStateManager state) {
    final members = state.teamMembers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("ANGGOTA KELOMPOK 4 (3KA31)"),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderLine, width: 0.8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06581C87),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(members.length, (index) {
              final member = members[index];
              final isLead = index == 0;
              final isLast = index == members.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isLead ? gunadarmaPurple.withValues(alpha: 0.35) : const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(
                                fontFamily: "Plus Jakarta",
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isLead ? gunadarmaPurple : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            member.name,
                            style: TextStyle(
                              fontFamily: "Plus Jakarta",
                              fontSize: 13.5,
                              fontWeight: isLead ? FontWeight.w700 : FontWeight.w600,
                              color: darkText,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            member.npm,
                            style: const TextStyle(
                              fontFamily: "Plus Jakarta",
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 0.5, thickness: 0.5, indent: 52, color: borderLine),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicInfoCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("INFORMASI AKADEMIK & KURIKULUM"),
        _buildGroupCard([
          _buildSettingsTile(
            icon: CupertinoIcons.person_crop_circle_badge_checkmark,
            title: "Dosen Pengampu",
            trailing: "Dr. Dina Anggraini, S.Kom., M.M.S.I.",
            showChevron: false,
          ),
          const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
          _buildSettingsTile(
            icon: CupertinoIcons.book_fill,
            title: "Mata Kuliah",
            trailing: "Konsep Data Mining",
            showChevron: false,
          ),
          const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
          _buildSettingsTile(
            icon: CupertinoIcons.number,
            title: "Kelas",
            trailing: "3KA31",
            showChevron: false,
          ),
          const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
          _buildSettingsTile(
            icon: CupertinoIcons.square_grid_2x2_fill,
            title: "Jurusan / Prodi",
            trailing: "S1 Sistem Informasi",
            showChevron: false,
          ),
          const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
          _buildSettingsTile(
            icon: CupertinoIcons.building_2_fill,
            title: "Fakultas & Institusi",
            trailing: "FIKTI • Univ. Gunadarma",
            showChevron: false,
          ),
        ]),
      ],
    );
  }

  Widget _buildDatabaseSection(BuildContext context, AprioriStateManager state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("DATABASE & DATASET TRANSAKSI"),
        _buildGroupCard([
          _buildSettingsTile(
            icon: CupertinoIcons.archivebox_fill,
            title: "Status Penyimpanan",
            trailing: state.transactions.isNotEmpty
                ? "${state.totalTransactions} Transaksi Aktif"
                : "Kosong (0 Transaksi)",
            showChevron: false,
          ),
          const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
          _buildSettingsTile(
            icon: CupertinoIcons.book_circle_fill,
            iconColor: gunadarmaPurple,
            title: "Rujukan Jurnal & Dataset",
            trailing: "JUKTISI • CSV",
            onTap: () => _showAcademicReferenceModal(context),
          ),
          const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
          _buildSettingsTile(
            icon: CupertinoIcons.doc_text_fill,
            title: "Format Berkas",
            trailing: "CSV, TSV, TXT, Excel",
            showChevron: false,
          ),
          const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
          _buildSettingsTile(
            icon: CupertinoIcons.arrow_clockwise_circle_fill,
            iconColor: gunadarmaPurple,
            title: "Muat Dataset Contoh",
            trailing: "Pulihkan",
            onTap: () => _showResetDatasetConfirm(context, state),
          ),
          const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
          _buildSettingsTile(
            icon: CupertinoIcons.trash_fill,
            iconColor: destructiveRed,
            title: "Kosongkan Dataset",
            trailing: "Reset",
            titleColor: destructiveRed,
            onTap: () => _showClearDatasetConfirm(context, state),
          ),
        ]),
      ],
    );
  }

  Widget _buildAprioriConfigSection(AprioriStateManager state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("KONFIGURASI ALGORITMA APRIORI"),
        _buildGroupCard([
          _buildSettingsTile(
            icon: CupertinoIcons.slider_horizontal_3,
            title: "Minimum Support",
            trailing: "${state.minSupport.toStringAsFixed(1)}%",
            showChevron: false,
          ),
          const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
          _buildSettingsTile(
            icon: CupertinoIcons.percent,
            title: "Minimum Confidence",
            trailing: "${state.minConfidence.toStringAsFixed(1)}%",
            showChevron: false,
          ),
          const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
          _buildSettingsTile(
            icon: CupertinoIcons.chart_bar_fill,
            title: "Metrik Evaluasi",
            trailing: "Support, Conf, Lift",
            showChevron: false,
          ),
          const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
          _buildSettingsTile(
            icon: CupertinoIcons.scissors,
            title: "Pruning Engine",
            trailing: "Anti-monotonicity",
            showChevron: false,
          ),
        ]),
      ],
    );
  }

  Widget _buildSystemSection(BuildContext context, AprioriStateManager state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("SISTEM & SESI"),
        _buildGroupCard([
          _buildSettingsTile(
            icon: CupertinoIcons.info_circle_fill,
            title: "Versi Aplikasi",
            trailing: "1.0.0 (Release)",
            showChevron: false,
          ),
          const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
          _buildSettingsTile(
            icon: _getDetectedDesignSystemIcon(),
            title: "Platform Runtime",
            trailing: _getDetectedPlatformName(),
            showChevron: false,
          ),
          const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
          _buildSettingsTile(
            icon: CupertinoIcons.sparkles,
            title: "Mode Akses",
            trailing: "Demo Akademik",
            showChevron: false,
          ),
          const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
          _buildSettingsTile(
            icon: CupertinoIcons.arrow_counterclockwise,
            iconColor: destructiveRed,
            title: "Mulai Ulang Sesi Demo",
            trailing: "Reset",
            titleColor: destructiveRed,
            showChevron: false,
            onTap: () => _showResetDemoSessionConfirm(context, state),
          ),
        ]),
      ],
    );
  }

  Widget _buildFooter() {
    return const Center(
      child: Column(
        children: [
          Text(
            "UNIVERSITAS GUNADARMA",
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: gunadarmaPurple,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 3),
          Text(
            "S1 Sistem Informasi • Kelas 3KA31 • Kelompok 4 © 2026",
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: "Plus Jakarta",
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLine, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06581C87),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    Color? iconColor,
    required String title,
    required String trailing,
    Color? titleColor,
    VoidCallback? onTap,
    bool showChevron = true,
  }) {
    final isDestructive = iconColor == destructiveRed;
    final effectiveIconColor = iconColor ?? const Color(0xFF475569);

    final tileContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isDestructive ? const Color(0xFFFFEBEB) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDestructive ? const Color(0xFFFFCDD2) : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: Icon(
              icon,
              size: 15,
              color: effectiveIconColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontFamily: "Plus Jakarta",
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: titleColor ?? darkText,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    trailing,
                    style: TextStyle(
                      fontFamily: "Plus Jakarta",
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? (onTap != null ? gunadarmaPurple : textMuted),
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showChevron && onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 13,
                    color: gunadarmaPurple,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return tileContent;
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: tileContent,
    );
  }

  String _getDetectedPlatformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "Android";
      case TargetPlatform.iOS:
        return "iOS";
      case TargetPlatform.macOS:
        return "macOS";
      case TargetPlatform.windows:
        return "Windows";
      case TargetPlatform.linux:
        return "Linux";
      default:
        return "Web Browser";
    }
  }

  IconData _getDetectedDesignSystemIcon() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return CupertinoIcons.device_phone_portrait;
      case TargetPlatform.iOS:
        return CupertinoIcons.device_phone_portrait;
      case TargetPlatform.macOS:
        return CupertinoIcons.device_laptop;
      case TargetPlatform.windows:
        return CupertinoIcons.desktopcomputer;
      default:
        return CupertinoIcons.globe;
    }
  }

  void _showClearDatasetConfirm(BuildContext context, AprioriStateManager state) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Kosongkan Dataset?"),
        content: const Text(
          "Seluruh struk transaksi dan aturan asosiasi yang tersimpan di memori akan dihapus bersih.",
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              state.clearAll();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Dataset transaksi berhasil dikosongkan."),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text("Kosongkan"),
          ),
        ],
      ),
    );
  }

  void _showResetDatasetConfirm(BuildContext context, AprioriStateManager state) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Muat Dataset Contoh?"),
        content: const Text(
          "Dataset akan diisi dengan 10 struk transaksi retail contoh untuk pengujian algoritma Apriori.",
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          CupertinoDialogAction(
            onPressed: () {
              final sample = [
                ["Roti", "Mentega", "Susu"],
                ["Roti", "Mentega"],
                ["Roti", "Susu"],
                ["Kopi", "Gula"],
                ["Kopi", "Gula", "Susu"],
                ["Roti", "Selai"],
                ["Mentega", "Selai"],
                ["Biskuit", "Susu"],
                ["Roti", "Mentega", "Keju"],
                ["Kopi", "Gula", "Biskuit"],
              ];
              state.setTransactions(sample);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("10 transaksi contoh berhasil dimuat."),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text("Muat Data"),
          ),
        ],
      ),
    );
  }

  void _showResetDemoSessionConfirm(BuildContext context, AprioriStateManager state) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Mulai Ulang Sesi Demo?"),
        content: const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            "Sesi akan disetel kembali ke profil default (Firdaus Dhuha Prabowo - Kelompok 4) dan kembali ke beranda aplikasi.",
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              state.setUserName("Firdaus Dhuha Prabowo");
              Navigator.pushNamedAndRemoveUntil(
                context,
                entryPointScreenRoute,
                (route) => false,
              );
            },
            child: const Text("Mulai Ulang"),
          ),
        ],
      ),
    );
  }

  void _showAcademicReferenceModal(BuildContext context) {
    AcademicReferenceHelper.showJournalModal(context);
  }
}
