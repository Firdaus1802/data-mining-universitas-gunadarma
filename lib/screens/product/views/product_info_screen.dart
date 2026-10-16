import 'package:flutter/material.dart';
import '../../../constants.dart';

class ProductInfoScreen extends StatelessWidget {
  const ProductInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: defaultPadding),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding / 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    width: 40,
                    child: BackButton(),
                  ),
                  Text(
                    "Detail Produk",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(defaultPadding),
                children: [
                  Text(
                    "Spesifikasi & Informasi Produk",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: defaultPadding),
                  _buildRow("Kategori", "Groceries & Supermarket"),
                  _buildRow("Kondisi", "Segar / Baru"),
                  _buildRow("Kemasan", "Food Grade Sealed Pack"),
                  _buildRow("Penyimpanan", "Suhu Dingin 2-6 °C"),
                  _buildRow("Sertifikasi", "Halal MUI & BPOM RI"),
                  _buildRow("Sumber Data", "Groceries Transaction Dataset"),
                  const SizedBox(height: defaultPadding),
                  Text(
                    "Deskripsi",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Produk kebutuhan sehari-hari berkualitas tinggi yang dipilih dari dataset transaksi ritel groceries. Item ini sering dibeli bersamaan dengan produk pendamping berdasarkan hasil analisis algoritma asosiasi Apriori.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          height: 1.5,
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

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

