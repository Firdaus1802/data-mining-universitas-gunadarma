import 'package:flutter/material.dart';
import '../../../constants.dart';

class SizeGuideScreen extends StatelessWidget {
  const SizeGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final units = [
      {
        "unit": "Kilogram (kg) & Gram (g)",
        "desc": "Digunakan untuk menimbang produk segar seperti sayuran (root vegetables, onions), buah-buahan (citrus, tropical fruit), daging (beef, pork), dan keju.",
        "icon": Icons.scale_outlined,
      },
      {
        "unit": "Liter (L) & Mililiter (ml)",
        "desc": "Digunakan untuk produk cair seperti susu segar (whole milk), yogurt minuman, jus buah, minyak goreng, dan minuman kemasan (bottled water, soda).",
        "icon": Icons.local_drink_outlined,
      },
      {
        "unit": "Pack / Bungkusan",
        "desc": "Kemasan standar untuk produk roti (rolls/buns, brown bread), pastry, biskuit, dan sosis siap santap.",
        "icon": Icons.inventory_2_outlined,
      },
      {
        "unit": "Pcs / Butir",
        "desc": "Satuan hitungan per butir atau buah tunggal untuk produk kemasan satuan khusus.",
        "icon": Icons.widgets_outlined,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Panduan Satuan & Takaran"),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(defaultPadding),
        itemCount: units.length,
        separatorBuilder: (context, index) => const SizedBox(height: defaultPadding),
        itemBuilder: (context, index) {
          final u = units[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(defaultBorderRadious),
            ),
            child: Padding(
              padding: const EdgeInsets.all(defaultPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      u["icon"] as IconData,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: defaultPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u["unit"] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          u["desc"] as String,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
