import 'package:flutter/material.dart';
import '../../../constants.dart';

class KidsScreen extends StatelessWidget {
  const KidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {"name": "Dairy Products", "items": "whole milk, yogurt, butter, curd", "icon": Icons.water_drop_outlined},
      {"name": "Vegetables & Fruits", "items": "root vegetables, citrus fruit, pip fruit", "icon": Icons.eco_outlined},
      {"name": "Bakery & Breads", "items": "rolls/buns, pastry, brown bread", "icon": Icons.bakery_dining_outlined},
      {"name": "Beverages", "items": "soda, bottled water, fruit juice, coffee", "icon": Icons.local_cafe_outlined},
      {"name": "Meat & Sausage", "items": "sausage, pork, beef, chicken", "icon": Icons.set_meal_outlined},
      {"name": "Canned & Groceries", "items": "canned beer, canned vegetables, sugar", "icon": Icons.kitchen_outlined},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kategori Produk"),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(defaultPadding),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(height: defaultPadding / 2),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(defaultBorderRadious),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: defaultPadding,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  cat["icon"] as IconData,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              title: Text(
                cat["name"] as String,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                cat["items"] as String,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
