import 'package:flutter/material.dart';
import '../../../../constants.dart';

class NotificationOptionsScreen extends StatefulWidget {
  const NotificationOptionsScreen({super.key});

  @override
  State<NotificationOptionsScreen> createState() => _NotificationOptionsScreenState();
}

class _NotificationOptionsScreenState extends State<NotificationOptionsScreen> {
  bool _aprioriRuleAlerts = true;
  bool _datasetUpdates = true;
  bool _recommendationPopups = true;
  bool _systemStatus = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengaturan Notifikasi"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(defaultPadding),
        children: [
          SwitchListTile.adaptive(
            value: _aprioriRuleAlerts,
            title: const Text("Pemberitahuan Aturan Apriori"),
            subtitle: const Text("Notifikasi ketika kalkulasi support & confidence selesai"),
            onChanged: (val) {
              setState(() => _aprioriRuleAlerts = val);
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            value: _datasetUpdates,
            title: const Text("Pembaruan Dataset"),
            subtitle: const Text("Pemberitahuan ketika dataset transaksi baru diunggah"),
            onChanged: (val) {
              setState(() => _datasetUpdates = val);
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            value: _recommendationPopups,
            title: const Text("Rekomendasi Keranjang Belanja"),
            subtitle: const Text("Tampilkan rekomendasi produk pasangan otomatis"),
            onChanged: (val) {
              setState(() => _recommendationPopups = val);
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            value: _systemStatus,
            title: const Text("Status Sistem & Log"),
            subtitle: const Text("Catatan teknis eksekusi algoritma data mining"),
            onChanged: (val) {
              setState(() => _systemStatus = val);
            },
          ),
        ],
      ),
    );
  }
}
