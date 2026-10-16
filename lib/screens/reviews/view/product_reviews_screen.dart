import 'package:flutter/material.dart';
import '../../../constants.dart';

class ProductReviewsScreen extends StatelessWidget {
  const ProductReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reviews = [
      {
        "name": "Ahmad Fauzi",
        "rating": 5.0,
        "date": "15 Okt 2026",
        "comment": "Susu dan rotinya masih sangat segar, packing rapi dan aman. Rekomendasi bundle sarapan sangat membantu!",
      },
      {
        "name": "Siti Nurhaliza",
        "rating": 5.0,
        "date": "14 Okt 2026",
        "comment": "Sayurannya segar-segar, pas banget buat kebutuhan masak harian. Belanja jadi lebih praktis dengan rekomendasi otomatis.",
      },
      {
        "name": "Budi Santoso",
        "rating": 4.0,
        "date": "12 Okt 2026",
        "comment": "Pengiriman cepat dan tepat waktu ke area kampus. Kualitas barang sesuai deskripsi pada aplikasi.",
      },
      {
        "name": "Rina Anggraini",
        "rating": 5.0,
        "date": "10 Okt 2026",
        "comment": "Fitur belanja rekomendasi pasangan produknya sangat akurat sesuai pola belanja mingguan saya.",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ulasan Pembeli"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(defaultPadding),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(defaultBorderRadious),
            ),
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "4.8",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                          (i) => const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Color(0xFFFFB800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Dari 126 ulasan pembeli",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    height: 60,
                    width: 1,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "98% Kepuasan",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Produk Berkualitas",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          Text(
            "Ulasan Terbaru",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: defaultPadding / 2),
          ...reviews.map(
            (r) => Card(
              margin: const EdgeInsets.only(bottom: defaultPadding / 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(defaultBorderRadious),
              ),
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r["name"] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          r["date"] as String,
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        (r["rating"] as double).toInt(),
                        (i) => const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFFFB800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r["comment"] as String,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
