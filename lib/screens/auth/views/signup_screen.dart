import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shop/screens/auth/views/components/sign_up_form.dart';
import 'package:shop/route/route_constants.dart';

import '../../../constants.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _agreeTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height * 0.32,
                      width: double.infinity,
                      color: Colors.white,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        "assets/logo/gunadarma.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(defaultPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Let’s get started!",
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: defaultPadding / 2),
                            const Text(
                              "Please enter your valid data in order to create an account.",
                            ),
                            const SizedBox(height: defaultPadding),
                            SignUpForm(
                              formKey: _formKey,
                              nameController: _nameController,
                              emailController: _emailController,
                            ),
                            const SizedBox(height: defaultPadding / 2),
                            Row(
                              children: [
                                Checkbox(
                                  onChanged: (value) {
                                    setState(() {
                                      _agreeTerms = value ?? false;
                                    });
                                  },
                                  value: _agreeTerms,
                                  activeColor: primaryColor,
                                ),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: "I agree with the",
                                      children: [
                                        TextSpan(
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.pushNamed(
                                                  context, termsOfServicesScreenRoute);
                                            },
                                          text: " Terms of service ",
                                          style: const TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: "& privacy policy.",
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () {
                                String enteredName = _nameController.text.trim();
                                final enteredEmail = _emailController.text.trim().isNotEmpty
                                    ? _emailController.text.trim()
                                    : "firdaus@gmail.com";
                                if (enteredName.isEmpty) {
                                  final parts = enteredEmail.split('@');
                                  if (parts.isNotEmpty && parts[0].isNotEmpty) {
                                    final raw = parts[0].replaceAll('.', ' ').replaceAll('_', ' ');
                                    enteredName = raw
                                        .split(' ')
                                        .where((w) => w.isNotEmpty)
                                        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
                                        .join(' ')
                                        .trim();
                                  }
                                }
                                if (enteredName.isEmpty) {
                                  enteredName = "Dosen / Pengguna";
                                }
                                final otp = (100000 + Random().nextInt(900000)).toString();
                                Navigator.pushNamed(
                                  context,
                                  otpScreenRoute,
                                  arguments: {
                                    'email': enteredEmail,
                                    'expectedOtp': otp,
                                    'userName': enteredName,
                                  },
                                );
                              },
                              child: const Text("Verifikasi Email & Lanjutkan"),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Do you have an account?"),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, logInScreenRoute);
                                  },
                                  child: const Text("Log in"),
                                )
                              ],
                            ),
                            const SizedBox(height: defaultPadding / 2),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
