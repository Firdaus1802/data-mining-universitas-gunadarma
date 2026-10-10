import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shop/constants.dart';
import 'package:shop/models/apriori_state_manager.dart';
import 'package:shop/route/route_constants.dart';

import 'components/login_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _agreeTerms = false;

  @override
  void dispose() {
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
                        "assets/logo/gunadarma.jpg",
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
                              "Welcome back!",
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: defaultPadding / 2),
                            const Text(
                              "Log in with your data that you entered during your registration.",
                            ),
                            const SizedBox(height: defaultPadding),
                            LogInForm(
                              formKey: _formKey,
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
                                      text: "I agree with the ",
                                      style: const TextStyle(fontSize: 13),
                                      children: [
                                        TextSpan(
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              Navigator.pushNamed(
                                                  context, termsOfServicesScreenRoute);
                                            },
                                          text: "Terms of service ",
                                          style: const TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: "& privacy policy.",
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, passwordRecoveryScreenRoute);
                                },
                                child: const Text(
                                  "Forgot password?",
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Mode Demo Aktif: Tekan Sign in untuk langsung masuk ke dashboard.",
                                      style: TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () {
                                final enteredEmail = _emailController.text.trim();
                                final detectedName = enteredEmail.isNotEmpty
                                    ? AprioriStateManager.instance.detectUserName(enteredEmail)
                                    : "Member";
                                AprioriStateManager.instance.setUserName(detectedName);
                                Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    entryPointScreenRoute,
                                    (route) => false);
                              },
                              child: const Text("Sign In / Masuk"),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account?"),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context, signUpScreenRoute);
                                  },
                                  child: const Text("Sign up"),
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
