import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sends an OTP email by writing to the 'mail' collection.
  /// This is compatible with the 'Trigger Email' Firebase Extension.
  Future<void> sendOTPEmail(String email, String otp) async {
    try {
      await _firestore.collection('mail').add({
        'to': email,
        'message': {
          'subject': 'Haritham: Your OTP for Signup',
          'html': '''
            <div style="font-family: Arial, sans-serif; color: #333;">
              <h2 style="color: #2E7D32;">Verify Your Account</h2>
              <p>Hello,</p>
              <p>Your 6-digit One-Time Password (OTP) for Haritham Citizen Signup is:</p>
              <h1 style="color: #2E7D32; font-size: 32px; letter-spacing: 5px;">$otp</h1>
              <p>This OTP is valid for 10 minutes. Please do not share it with anyone.</p>
              <p>Regards,<br>Team Haritham</p>
            </div>
          ''',
        },
      });
    } catch (e) {
      print("EmailService Error (OTP): $e");
      rethrow;
    }
  }

  /// Sends a password reset email by writing to the 'mail' collection.
  Future<void> sendResetPasswordEmail(String email, String resetLink) async {
    try {
      await _firestore.collection('mail').add({
        'to': email,
        'message': {
          'subject': 'Haritham: Password Reset Request',
          'html': '''
            <div style="font-family: Arial, sans-serif; color: #333;">
              <h2 style="color: #2E7D32;">Password Reset Request</h2>
              <p>Hello,</p>
              <p>We received a request to reset your password for your Haritham account.</p>
              <p>Since this is a demo, you can proceed to reset your password by clicking the link below or using the app directly:</p>
              <a href="$resetLink" style="background-color: #2E7D32; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">Reset Password</a>
              <p>If you did not request this, please ignore this email.</p>
              <p>Regards,<br>Team Haritham</p>
            </div>
          ''',
        },
      });
    } catch (e) {
      print("EmailService Error (Reset): $e");
      rethrow;
    }
  }
}
