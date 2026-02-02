import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController(); // ✅ NEW

  int step = 1; // 1=email, 2=otp, 3=password
  bool loading = false;
  String generatedOtp = '';

  // ================= SEND OTP =================
  Future<void> _sendOtp() async {
    final email = emailController.text.trim();

    if (!email.contains('@')) {
      _show('Enter valid email');
      return;
    }

    setState(() => loading = true);

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        _show('Email not found');
        return;
      }

      generatedOtp = (100000 + Random().nextInt(900000)).toString();

      await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(email)
          .set({
        'otp': generatedOtp,
        'createdAt': Timestamp.now(),
      });

      // ⚠️ connect email service here
      print('OTP SENT TO EMAIL: $generatedOtp');

      setState(() => step = 2);
      _show('OTP sent to email');
    } catch (e) {
      _show('Failed to send OTP');
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= VERIFY OTP =================
  Future<void> _verifyOtp() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      _show('Invalid OTP');
      return;
    }

    setState(() => loading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(email)
          .get();

      if (!doc.exists || doc['otp'] != otp) {
        _show('Wrong OTP');
        return;
      }

      setState(() => step = 3);
    } catch (e) {
      _show('OTP verification failed');
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= RESET PASSWORD =================
  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (password.length < 6) {
      _show('Password too short');
      return;
    }

    if (password != confirm) {
      _show('Passwords do not match');
      return;
    }

    setState(() => loading = true);

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        _show('User not found');
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userQuery.docs.first.id)
          .update({'password': password});

      await FirebaseFirestore.instance
          .collection('password_resets')
          .doc(email)
          .delete();

      _show('Password updated');
      Navigator.pop(context);
    } catch (e) {
      _show('Failed to reset password');
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (step == 1) ...[
              _emailField(),
              _button('Send OTP', _sendOtp),
            ],
            if (step == 2) ...[
              _otpField(),
              _button('Verify OTP', _verifyOtp),
            ],
            if (step == 3) ...[
              _passwordField(),
              const SizedBox(height: 16),
              _confirmPasswordField(), // ✅ NEW FIELD
              _button('Reset Password', _resetPassword),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emailField() => TextField(
    controller: emailController,
    keyboardType: TextInputType.emailAddress,
    decoration: const InputDecoration(
      labelText: 'Email',
      filled: true,
      fillColor: Colors.white,
    ),
  );

  Widget _otpField() => TextField(
    controller: otpController,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
      labelText: 'OTP',
      filled: true,
      fillColor: Colors.white,
    ),
  );

  Widget _passwordField() => TextField(
    controller: passwordController,
    obscureText: true,
    decoration: const InputDecoration(
      labelText: 'New Password',
      filled: true,
      fillColor: Colors.white,
    ),
  );

  Widget _confirmPasswordField() => TextField(
    controller: confirmPasswordController,
    obscureText: true,
    decoration: const InputDecoration(
      labelText: 'Confirm Password',
      filled: true,
      fillColor: Colors.white,
    ),
  );

  Widget _button(String text, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: loading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(text),
    ),
  );

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
