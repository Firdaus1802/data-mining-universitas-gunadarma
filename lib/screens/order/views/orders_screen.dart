import 'package:flutter/material.dart';
import '../../../constants.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      {
        "id": "TRX-1048",
        "date": "16 Okt 2026, 11:20",
        "items": ["whole milk", "citrus fruit", "tropical fruit"],
        "total": "Rp 54.000",
        "status": "Selesai",
      },
      {
        "id": "TRX-1047",
        "date": "15 Okt 2026, 16:45",
        "items": ["other vegetables", "pip fruit", "pastry"],
        "total": "Rp 38.500",
        "status": "Selesai",
      },
      {
        "id": "TRX-1046",
        "date": "14 Okt 2026, 09:15",
        "items": ["sausage", "rolls/buns", "soda"],
        "total": "Rp 42.000",
        "status": "Selesai",
      },
      {
        "id": "TRX-1045",
        "date": "13 Okt 2026, 14:02",
        "items": ["yogurt", "bottled water", "chocolate"],
        "total": "Rp 29.000",
        "status": "Selesai",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Transaksi"),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(defaultPadding),
        itemCount: orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: defaultPadding),
        itemBuilder: (context, index) {
          final o = orders[index];
          final items = o["items"] as List<String>;
          return Card(
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
                        o["id"] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          o["status"] as String,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    o["date"] as String,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const Divider(height: 20),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: items
                        .map(
                          (item) => Chip(
                            label: Text(
                              item,
                              style: const TextStyle(fontSize: 11),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Pembayaran",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Text(
                        o["total"] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: primaryColor,
                        ),
                      ),
                    ],
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
