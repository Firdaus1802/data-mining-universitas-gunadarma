import 'package:flutter/material.dart';
import '../../../constants.dart';

class ProductShippingScreen extends StatelessWidget {
  const ProductShippingScreen({super.key});

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
                    "Informasi Pengiriman",
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
                  _buildOption(
                    context,
                    icon: Icons.flash_on_outlined,
                    title: "Instant Delivery (1-2 Jam)",
                    desc: "Pengiriman langsung ke area kampus Gunadarma Depok, Kelapa Dua, dan sekitarnya.",
                    cost: "Rp 15.000",
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  _buildOption(
                    context,
                    icon: Icons.local_shipping_outlined,
                    title: "Same Day (6-8 Jam)",
                    desc: "Pengiriman pada hari yang sama untuk pemesanan sebelum pukul 14:00 WIB.",
                    cost: "Rp 10.000",
                  ),
                  const SizedBox(height: defaultPadding / 2),
                  _buildOption(
                    context,
                    icon: Icons.storefront_outlined,
                    title: "Ambil di Kampus (Pick Up)",
                    desc: "Pengambilan pesanan langsung di Laboratorium Sistem Informasi Kampus D Gunadarma.",
                    cost: "Gratis",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
    required String cost,
  }) {
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(width: defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              cost,
              style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

