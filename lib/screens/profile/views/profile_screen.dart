import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shop/models/apriori_state_manager.dart';
import 'package:shop/route/screen_export.dart';
import 'package:shop/screens/apriori/views/academic_reference_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color darkText = Color(0xFF1C1C1E);
  static const Color textMuted = Color(0xFF8E8E93);
  static const Color borderLine = Color(0xFFE5E5EA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color pageBg = Color(0xFFF2F2F7);
  static const Color gunadarmaPurple = Color(0xFF4A148C);
  static const Color destructiveRed = Color(0xFFFF3B30);

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAppleIdHeaderCard(context, state, displayName, email),
                  const SizedBox(height: 22),
                  _buildSectionHeader("TIM PENELITI & AKADEMIK"),
                  _buildGroupCard([
                    _buildSettingsTile(
                      icon: CupertinoIcons.person_2_fill,
                      iconColor: const Color(0xFF1C1C1E),
                      title: "Anggota Tim",
                      trailing: "${state.teamMembers.length} Profil",
                      onTap: () => _showTeamMembersModal(context, state),
                    ),
                    const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
                    _buildSettingsTile(
                      icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                      iconColor: const Color(0xFF1C1C1E),
                      title: "Dosen Pengampu",
                      trailing: "Dr. Dina Anggraini, S.Kom., M.M.S.I.",
                      showChevron: false,
                    ),
                    const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
                    _buildSettingsTile(
                      icon: CupertinoIcons.book_fill,
                      iconColor: const Color(0xFF1C1C1E),
                      title: "Mata Kuliah",
                      trailing: "Konsep Data Mining",
                      showChevron: false,
                    ),
                    const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
                    _buildSettingsTile(
                      icon: CupertinoIcons.number,
                      iconColor: const Color(0xFF1C1C1E),
                      title: "Kelas",
                      trailing: "3KA31",
                      showChevron: false,
                    ),
                    const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
                    _buildSettingsTile(
                      icon: CupertinoIcons.square_grid_2x2_fill,
                      iconColor: const Color(0xFF1C1C1E),
                      title: "Jurusan / Prodi",
                      trailing: "S1 Sistem Informasi",
                      showChevron: false,
                    ),
                    const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
                    _buildSettingsTile(
                      icon: CupertinoIcons.building_2_fill,
                      iconColor: const Color(0xFF1C1C1E),
                      title: "Institusi",
                      trailing: "Universitas Gunadarma",
                      showChevron: false,
                    ),
                  ]),
                  const SizedBox(height: 22),
                  _buildSectionHeader("DATABASE & DATASET TRANSAKSI"),
                  _buildGroupCard([
                    _buildSettingsTile(
                      icon: CupertinoIcons.archivebox_fill,
                      iconColor: const Color(0xFF1C1C1E),
                      title: "Status Penyimpanan",
                      trailing: state.transactions.isNotEmpty
                          ? "${state.totalTransactions} Transaksi"
                          : "Kosong (0 Struk)",
                      showChevron: false,
                    ),
                    const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
                    _buildSettingsTile(
                      icon: CupertinoIcons.book_circle_fill,
                      iconColor: const Color(0xFF5856D6),
                      title: "Referensi Jurnal & Dataset",
                      trailing: "SINTA 3 • Kaggle",
                      onTap: () => _showAcademicReferenceModal(context),
                    ),
                    const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
                    _buildSettingsTile(
                      icon: CupertinoIcons.doc_text_fill,
                      iconColor: const Color(0xFF1C1C1E),
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
                  const SizedBox(height: 22),
                  _buildSectionHeader("KONFIGURASI ALGORITMA APRIORI"),
                  _buildGroupCard([
                    _buildSettingsTile(
                      icon: CupertinoIcons.slider_horizontal_3,
                      iconColor: const Color(0xFF1C1C1E),
                      title: "Minimum Support",
                      trailing: "${state.minSupport.toStringAsFixed(1)}%",
                      showChevron: false,
                    ),
                    const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
                    _buildSettingsTile(
                      icon: CupertinoIcons.percent,
                      iconColor: const Color(0xFF1C1C1E),
                      title: "Minimum Confidence",
                      trailing: "${state.minConfidence.toStringAsFixed(1)}%",
                      showChevron: false,
                    ),
                    const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
                    _buildSettingsTile(
                      icon: CupertinoIcons.chart_bar_fill,
                      iconColor: const Color(0xFF1C1C1E),
                      title: "Metrik Evaluasi",
                      trailing: "Support, Conf, Lift",
                      showChevron: false,
                    ),
                    const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
                    _buildSettingsTile(
                      icon: CupertinoIcons.scissors,
                      iconColor: const Color(0xFF1C1C1E),
                      title: "Pruning Engine",
                      trailing: "Anti-monotonicity",
                      showChevron: false,
                    ),
                  ]),
                  const SizedBox(height: 22),
                  _buildSectionHeader("SISTEM & SESI"),
                  _buildGroupCard([
                    _buildSettingsTile(
                      icon: CupertinoIcons.info_circle_fill,
                      iconColor: const Color(0xFF1C1C1E),
                      title: "Versi Aplikasi",
                      trailing: "1.0.0 (Release)",
                      showChevron: false,
                    ),
                    const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
                    _buildSettingsTile(
                      icon: _getDetectedDesignSystemIcon(),
                      iconColor: const Color(0xFF1C1C1E),
                      title: "Device Platform",
                      trailing: _getDetectedPlatformName(),
                      showChevron: false,
                    ),
                    const Divider(height: 0.5, thickness: 0.5, indent: 54, color: borderLine),
                    _buildSettingsTile(
                      icon: CupertinoIcons.sparkles,
                      iconColor: gunadarmaPurple,
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
                  const SizedBox(height: 28),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "UNIVERSITAS GUNADARMA",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "S1 Sistem Informasi • Kelas 3KA31 • Kelompok 4 © 2026",
                          style: TextStyle(
                            fontSize: 10,
                            color: textMuted.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppleIdHeaderCard(BuildContext context, AprioriStateManager state, String displayName, String email) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showTeamMembersModal(context, state),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderLine, width: 0.6),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.person_crop_circle_fill,
                  size: 34,
                  color: gunadarmaPurple,
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
                      fontWeight: FontWeight.w600,
                      color: darkText,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "10124497 • S1 Sistem Informasi",
                    style: TextStyle(
                      fontFamily: "Plus Jakarta",
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    "Ketua Kelompok 4 • Kelas 3KA31",
                    style: TextStyle(
                      fontFamily: "Plus Jakarta",
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: gunadarmaPurple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 15,
              color: Color(0xFFC7C7CC),
            ),
          ],
        ),
      ),
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

  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderLine, width: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
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
    required Color iconColor,
    required String title,
    required String trailing,
    String? subtitle,
    Color? titleColor,
    VoidCallback? onTap,
    bool showChevron = true,
  }) {
    final tileContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          if (subtitle != null && subtitle.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: "Plus Jakarta",
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? darkText,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: "Plus Jakarta",
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],
            )
          else
            Text(
              title,
              style: TextStyle(
                fontFamily: "Plus Jakarta",
                fontSize: 14,
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
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? textMuted,
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
                    size: 14,
                    color: textMuted,
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
        return "Multiplatform";
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
        return CupertinoIcons.device_phone_portrait;
    }
  }

  void _showTeamMembersModal(BuildContext context, AprioriStateManager state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        final members = state.teamMembers;
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: const BoxDecoration(
            color: pageBg,
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
                          "Anggota Kelompok 4",
                          style: TextStyle(
                            fontFamily: "Plus Jakarta",
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "S1 Sistem Informasi • Kelas 3KA31",
                          style: TextStyle(
                            fontFamily: "Plus Jakarta",
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(bottomSheetContext),
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
              const Divider(height: 0.5, thickness: 0.5, color: borderLine),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 12, bottom: 8),
                        child: Text(
                          "DAFTAR PENELITI",
                          style: TextStyle(
                            fontFamily: "Plus Jakarta",
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderLine, width: 0.6),
                        ),
                        child: Column(
                          children: List.generate(members.length, (index) {
                            final member = members[index];
                            final isLead = index == 0;
                            final isLast = index == members.length - 1;

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: isLead ? gunadarmaPurple.withValues(alpha: 0.1) : const Color(0xFFF2F2F7),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "${index + 1}",
                                            style: TextStyle(
                                              fontFamily: "Plus Jakarta",
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isLead ? gunadarmaPurple : const Color(0xFF8E8E93),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              member.name,
                                              style: const TextStyle(
                                                fontFamily: "Plus Jakarta",
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w600,
                                                color: darkText,
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "${member.npm} • ${member.role}",
                                              style: const TextStyle(
                                                fontFamily: "Plus Jakarta",
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isLead)
                                        const Text(
                                          "Ketua",
                                          style: TextStyle(
                                            fontFamily: "Plus Jakarta",
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: gunadarmaPurple,
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
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          "Universitas Gunadarma • Konsep Data Mining",
                          style: TextStyle(
                            fontFamily: "Plus Jakarta",
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: textMuted,
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
      },
    );
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: pageBg,
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
                          "Referensi Riset & Dataset",
                          style: TextStyle(
                            fontFamily: "Plus Jakarta",
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: darkText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Dasar Teori Ilmiah & Sumber Data Transaksi",
                          style: TextStyle(
                            fontFamily: "Plus Jakarta",
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: textMuted,
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
              const Divider(height: 0.5, thickness: 0.5, color: borderLine),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("RUJUKAN JURNAL ILMIAH (SINTA 3)"),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderLine, width: 0.8),
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
                                    "Terakreditasi SINTA 3",
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: gunadarmaPurple,
                                    ),
                                  ),
                                ),
                                const Text(
                                  "ISSN 2614-5278",
                                  style: TextStyle(fontSize: 10.5, color: textMuted, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Market Basket Analysis Menggunakan Algoritma Apriori dan FP Growth untuk Menentukan Pola Pembelian Konsumen",
                              style: TextStyle(
                                fontFamily: "Plus Jakarta",
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: darkText,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Jurnal Media Informatika Budidarma (JMIB) • Vol. 7, No. 3 (Juli 2023)\nPenulis: Reski Noviana, Arief Hermawan, Donny Avianto (UTY)",
                              style: TextStyle(fontSize: 11.5, color: textMuted, height: 1.35),
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
                                          "Buka DOI",
                                          style: TextStyle(
                                            fontSize: 12.5,
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
                                          "Naskah & PDF",
                                          style: TextStyle(
                                            fontSize: 12.5,
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionHeader("SUMBER DATASET KONSUMEN"),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderLine, width: 0.8),
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
                                    "1.000 Transaksi Terpilih",
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF007AFF),
                                    ),
                                  ),
                                ),
                                const Text(
                                  "Kaggle Dataset",
                                  style: TextStyle(fontSize: 10.5, color: textMuted, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Groceries Market Basket Dataset",
                              style: TextStyle(
                                fontFamily: "Plus Jakarta",
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: darkText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Dataset riil transaksi pasar swalayan yang merekam kombinasi belanja konsumen untuk pengujian association rules mining.",
                              style: TextStyle(fontSize: 11.5, color: textMuted, height: 1.35),
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
                                          "Unduh CSV",
                                          style: TextStyle(
                                            fontSize: 12,
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
                                          "Pratinjau",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF007AFF),
                                          ),
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
