import 'package:flutter/material.dart';
import '../../../../constants.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        "title": "Dataset Groceries Berhasil Dimuat",
        "desc": "1.000 transaksi berhasil disinkronisasi ke memori lokal secara otomatis.",
        "time": "Baru saja",
        "icon": Icons.dataset_outlined,
      },
      {
        "title": "Aturan Asosiasi Selesai Dihitung",
        "desc": "Algoritma Apriori menghasilkan 48 aturan dengan minimum support 1.5% dan confidence 10%.",
        "time": "1 jam lalu",
        "icon": Icons.auto_graph_outlined,
      },
      {
        "title": "Data Kelompok 4 Terverifikasi",
        "desc": "Daftar anggota kelompok kelas 3KA31 Universitas Gunadarma telah diperbarui.",
        "time": "Kemarin",
        "icon": Icons.group_outlined,
      },
      {
        "title": "Sistem Rekomendasi Siap",
        "desc": "Fitur kasir pintar di menu Discover telah tersinkron dengan hasil aturan Apriori.",
        "time": "2 hari lalu",
        "icon": Icons.shopping_basket_outlined,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifikasi"),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(defaultPadding),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: defaultPadding / 2),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(defaultBorderRadious),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(defaultPadding / 1.5),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Icon(
                  item["icon"] as IconData,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              title: Text(
                item["title"] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  item["desc"] as String,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              trailing: Text(
                item["time"] as String,
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ),
          );
        },
      ),
    );
  }
}
