import 'dart:convert';
import 'dart:io';

class EmailService {
  static String serviceId = "";
  static String templateId = "";
  static String publicKey = "";

  static bool get isConfigured =>
      serviceId.isNotEmpty && templateId.isNotEmpty && publicKey.isNotEmpty;

  static Future<bool> sendOtpEmail({
    required String toEmail,
    required String toName,
    required String otpCode,
  }) async {
    if (!isConfigured) {
      return false;
    }

    try {
      final client = HttpClient();
      final request = await client.postUrl(
        Uri.parse("https://api.emailjs.com/api/v1.0/email/send"),
      );

      request.headers.set('Content-Type', 'application/json');

      final payload = jsonEncode({
        "service_id": serviceId,
        "template_id": templateId,
        "user_id": publicKey,
        "template_params": {
          "to_email": toEmail,
          "to_name": toName,
          "otp_code": otpCode,
        },
      });

      request.write(payload);
      final response = await request.close();
      client.close();

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}

