import 'package:flutter/material.dart';
import '../../../../constants.dart';

class EnableNotificationScreen extends StatelessWidget {
  const EnableNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding * 1.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  size: 54,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: defaultPadding * 1.5),
              Text(
                "Aktifkan Notifikasi",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: defaultPadding / 2),
              Text(
                "Dapatkan informasi terbaru mengenai pembaruan aturan asosiasi Apriori, pola belanja populer, dan analisis data mining secara realtime.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Aktifkan Notifikasi"),
              ),
              const SizedBox(height: defaultPadding / 2),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Nanti Saja"),
              ),
              const SizedBox(height: defaultPadding),
            ],
          ),
        ),
      ),
    );
  }
}
