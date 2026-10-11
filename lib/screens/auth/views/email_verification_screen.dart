import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shop/models/apriori_state_manager.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/services/email_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String expectedOtp;
  final String? userName;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.expectedOtp,
    this.userName,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const Color darkText = Color(0xFF1C1C1E);
  static const Color textMuted = Color(0xFF8E8E93);
  static const Color borderLine = Color(0xFFE5E5EA);
  static const Color gunadarmaPurple = Color(0xFF4A148C);
  static const Color destructiveRed = Color(0xFFFF3B30);
  static const Color pageBg = Color(0xFFF2F2F7);

  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late String _currentOtp;
  bool _showBanner = true;
  bool _isVerifying = false;
  String? _errorMessage;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentOtp = widget.expectedOtp.isNotEmpty ? widget.expectedOtp : _generateRandomOtp();
    _sendActualEmailIfConfigured();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _sendActualEmailIfConfigured() {
    final name = widget.userName ?? "Pengguna";
    EmailService.sendOtpEmail(
      toEmail: widget.email,
      toName: name,
      otpCode: _currentOtp,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _generateRandomOtp() {
    final random = Random();
    final code = 100000 + random.nextInt(900000);
    return code.toString();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _resendCode() {
    setState(() {
      _currentOtp = _generateRandomOtp();
      _showBanner = true;
      _errorMessage = null;
      for (final c in _controllers) {
        c.clear();
      }
    });
    _sendActualEmailIfConfigured();
    _startTimer();
    _focusNodes[0].requestFocus();
  }

  void _autoFillOtp() {
    for (int i = 0; i < 6 && i < _currentOtp.length; i++) {
      _controllers[i].text = _currentOtp[i];
    }
    _verifyCode();
  }

  String get _enteredCode {
    return _controllers.map((c) => c.text).join();
  }

  void _onDigitChanged(int index, String value) {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_enteredCode.length == 6) {
          _verifyCode();
        }
      }
    }
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _openGmailApp() async {
    final gmailWebUri = Uri.parse("https://mail.google.com");
    final mailtoUri = Uri.parse("mailto:${widget.email}");
    try {
      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
      } else if (await canLaunchUrl(gmailWebUri)) {
        await launchUrl(gmailWebUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _verifyCode() async {
    final code = _enteredCode;
    if (code.length < 6) {
      setState(() {
        _errorMessage = "Harap masukkan seluruh 6 digit kode.";
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 400));

    if (code == _currentOtp) {
      final detected = widget.userName != null && widget.userName!.isNotEmpty
          ? widget.userName!
          : AprioriStateManager.instance.detectUserName(widget.email);

      AprioriStateManager.instance.registerUser(widget.email, detected);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text("Verifikasi Berhasil! Selamat datang, $detected."),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1C1C1E),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        entryPointScreenRoute,
        (route) => false,
      );
    } else {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = "Kode otorisasi tidak cocok. Periksa kembali email pribadi Anda.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.chevron_left, color: darkText, size: 22),
        ),
        title: const Text(
          "Verifikasi Kode",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: darkText,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Image.asset(
              "assets/logo/gunadarma.png",
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_showBanner) _buildSimulatedGmailPushBanner(),
              const SizedBox(height: 18),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: gunadarmaPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: gunadarmaPurple.withValues(alpha: 0.2), width: 1.5),
                ),
                child: const Icon(
                  CupertinoIcons.mail_solid,
                  size: 28,
                  color: gunadarmaPurple,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Verifikasi Kode Masuk",
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Masukkan 6 digit kode yang telah dikirimkan ke email Anda:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderLine, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.mail, size: 14, color: gunadarmaPurple),
                    const SizedBox(width: 6),
                    Text(
                      widget.email,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(CupertinoIcons.checkmark_seal_fill, size: 14, color: Color(0xFF34C759)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) => _buildOtpBox(index)),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFCCC7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 15, color: destructiveRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: destructiveRed, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: CupertinoButton(
                  color: darkText,
                  borderRadius: BorderRadius.circular(12),
                  padding: EdgeInsets.zero,
                  onPressed: _isVerifying ? null : _verifyCode,
                  child: _isVerifying
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.checkmark_alt, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Verifikasi & Masuk",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: CupertinoButton(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  padding: EdgeInsets.zero,
                  onPressed: _openGmailApp,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEA4335),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.mail_solid, size: 11, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Buka Aplikasi Gmail",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_secondsLeft > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.clock, size: 14, color: textMuted),
                    const SizedBox(width: 6),
                    Text(
                      "Kirim ulang kode dalam 00:${_secondsLeft.toString().padLeft(2, '0')}",
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              else
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _resendCode,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.arrow_clockwise, size: 14, color: gunadarmaPurple),
                      SizedBox(width: 6),
                      Text(
                        "Kirim Ulang Kode Otorisasi",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: gunadarmaPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderLine, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.info_circle_fill, size: 16, color: Color(0xFF475569)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Keamanan Otentikasi: Kode hanya berlaku untuk sesi login ini. Pastikan email '${widget.email}' adalah milik Anda.",
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF475569),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimulatedGmailPushBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEA4335).withValues(alpha: 0.3), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEA4335),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.mail_solid, size: 11, color: Colors.white),
              ),
              const SizedBox(width: 7),
              const Text(
                "GMAIL",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEA4335),
                  letterSpacing: 0.6,
                ),
              ),
              const Text(
                " • Baru Saja",
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const Spacer(),
              CupertinoButton(
                padding: const EdgeInsets.all(4),
                onPressed: () {
                  setState(() {
                    _showBanner = false;
                  });
                },
                child: const Icon(CupertinoIcons.xmark, size: 13, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Kode Masuk Gunadarma: $_currentOtp",
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Gunakan kode $_currentOtp untuk otorisasi login ke akun ${widget.email}.",
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: gunadarmaPurple,
                borderRadius: BorderRadius.circular(8),
                onPressed: _autoFillOtp,
                child: const Text(
                  "Isi Otomatis",
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) => _onKeyDown(index, event),
      child: Container(
        width: 44,
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _focusNodes[index].hasFocus ? gunadarmaPurple : borderLine,
            width: _focusNodes[index].hasFocus ? 1.6 : 0.9,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x04000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: CupertinoTextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
          maxLength: 1,
          decoration: null,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (val) => _onDigitChanged(index, val),
        ),
      ),
    );
  }
}

