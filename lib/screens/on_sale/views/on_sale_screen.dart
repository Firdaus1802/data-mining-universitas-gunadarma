import 'package:flutter/material.dart';
import '../../../constants.dart';

class OnSaleScreen extends StatelessWidget {
  const OnSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bundles = [
      {
        "title": "Paket Sarapan Sehat",
        "items": "whole milk + yogurt + pastry",
        "discount": "Diskon 15%",
        "price": "Rp 42.500",
        "originalPrice": "Rp 50.000",
        "lift": "Lift: 2.18x",
      },
      {
        "title": "Paket Masak Sayur Segar",
        "items": "root vegetables + other vegetables + onions",
        "discount": "Diskon 20%",
        "price": "Rp 36.000",
        "originalPrice": "Rp 45.000",
        "lift": "Lift: 2.45x",
      },
      {
        "title": "Paket Camilan & Minuman",
        "items": "rolls/buns + soda + fruit juice",
        "discount": "Diskon 10%",
        "price": "Rp 27.000",
        "originalPrice": "Rp 30.000",
        "lift": "Lift: 1.85x",
      },
      {
        "title": "Paket Daging & Bumbu",
        "items": "sausage + rolls/buns + mustard",
        "discount": "Diskon 25%",
        "price": "Rp 48.750",
        "originalPrice": "Rp 65.000",
        "lift": "Lift: 2.62x",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Promo & Bundling Apriori"),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(defaultPadding),
        itemCount: bundles.length,
        separatorBuilder: (context, index) => const SizedBox(height: defaultPadding),
        itemBuilder: (context, index) {
          final b = bundles[index];
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
                      Expanded(
                        child: Text(
                          b["title"]!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          b["lift"]!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    b["items"]!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            b["price"]!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            b["originalPrice"]!,
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text("Beli Paket"),
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
