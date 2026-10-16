import 'package:flutter/material.dart';
import '../../../constants.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pemulihan Kata Sandi"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: defaultPadding),
              const Center(
                child: Icon(
                  Icons.lock_reset_rounded,
                  size: 72,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: defaultPadding),
              Text(
                "Lupa Kata Sandi Akun?",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "Masukkan email akun Gunadarma Anda. Kami akan mengirimkan instruksi untuk mengatur ulang kata sandi.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: defaultPadding * 2),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email Akun",
                  hintText: "nama@student.gunadarma.ac.id",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: defaultPadding * 1.5),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Instruksi pemulihan telah dikirim ke email."),
                    ),
                  );
                },
                child: const Text("Kirim Tautan Pemulihan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
