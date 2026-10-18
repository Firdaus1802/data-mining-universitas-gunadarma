import 'package:flutter/material.dart';
import '../../../constants.dart';

class UserInfoScreen extends StatelessWidget {
  const UserInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Informasi Akun"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(defaultPadding),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Text(
                    "UG",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.verified_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: defaultPadding),
          Center(
            child: Text(
              "Mahasiswa Gunadarma",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              "Kelompok 4 - Kelas 3KA31",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          const SizedBox(height: defaultPadding * 1.5),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(defaultBorderRadious),
            ),
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Column(
                children: [
                  _buildItem(context, "Universitas", "Universitas Gunadarma"),
                  const Divider(),
                  _buildItem(context, "Fakultas", "Ilmu Komputer & Teknologi Informasi"),
                  const Divider(),
                  _buildItem(context, "Jurusan", "Sistem Informasi"),
                  const Divider(),
                  _buildItem(context, "Mata Kuliah", "Data Mining"),
                  const Divider(),
                  _buildItem(context, "Dosen Pengampu", "Dr. Dina Anggraini, S.Kom., M.M.S.I."),
                  const Divider(),
                  _buildItem(context, "Tahun Akademik", "2026/2027"),
                ],
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text("Kembali ke Profil"),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
