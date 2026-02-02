import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';

class CitizenSignupScreen extends StatefulWidget {
  const CitizenSignupScreen({super.key});

  @override
  State<CitizenSignupScreen> createState() => _CitizenSignupScreenState();
}

class _CitizenSignupScreenState extends State<CitizenSignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController retypePasswordController =
  TextEditingController();

  bool otpSent = false;
  bool verified = false;
  bool loading = false;

  // ✅ ONLY NEW
  bool hidePassword = true;
  bool hideRetypePassword = true;

  bool _isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10}$').hasMatch(phone);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w]{2,4}$').hasMatch(email);
  }

  bool _validateEmailPhone() {
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    if (email.isEmpty) {
      _show('Email is required');
      return false;
    }
    if (!_isValidEmail(email)) {
      _show('Enter valid email');
      return false;
    }

    if (phone.isEmpty) {
      _show('Phone number is required');
      return false;
    }
    if (!_isValidPhone(phone)) {
      _show('Enter valid 10-digit phone number');
      return false;
    }

    return true;
  }

  bool _validatePasswords() {
    final pass = passwordController.text.trim();
    final rePass = retypePasswordController.text.trim();

    if (pass.isEmpty) {
      _show('Password is required');
      return false;
    }
    if (pass.length < 6) {
      _show('Password must be at least 6 characters');
      return false;
    }
    if (rePass.isEmpty) {
      _show('Please retype password');
      return false;
    }
    if (pass != rePass) {
      _show('Passwords do not match');
      return false;
    }
    return true;
  }

  Future<void> _sendOtp() async {
    if (!_validateEmailPhone()) return;

    final email = emailController.text.trim();

    setState(() => loading = true);
    try {
      final userCred =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: 'Temp@1234',
      );

      await userCred.user!.sendEmailVerification();
      otpSent = true;

      _show('Verification link sent to email');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _checkOtp() async {
    setState(() => loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.reload();

      if (user.emailVerified) {
        verified = true;
        _show('Email verified');
      } else {
        _show('Please verify email first');
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _finishSignup() async {
    if (!_validateEmailPhone()) return;
    if (!_validatePasswords()) return;

    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final pass = passwordController.text.trim();

    setState(() => loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.updatePassword(pass);

      await FirebaseFirestore.instance.collection('users').add({
        'email': email,
        'phone': phone,
        'password': pass,
        'role': 'citizen',
        'createdAt': Timestamp.now(),
      });

      await FirebaseAuth.instance.signOut();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    retypePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Citizen Signup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                filled: true,
                fillColor: Colors.white,
                counterText: "",
              ),
            ),

            const SizedBox(height: 24),

            if (!otpSent)
              ElevatedButton(
                onPressed: loading ? null : _sendOtp,
                child: const Text('Send OTP'),
              ),

            if (otpSent && !verified)
              ElevatedButton(
                onPressed: loading ? null : _checkOtp,
                child: const Text('Verify OTP'),
              ),

            if (verified) ...[
              const SizedBox(height: 16),

              // 🔥 PASSWORD WITH EYE
              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: 'Create Password',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(
                        hidePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => hidePassword = !hidePassword);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔥 RETYPE PASSWORD WITH EYE
              TextField(
                controller: retypePasswordController,
                obscureText: hideRetypePassword,
                decoration: InputDecoration(
                  labelText: 'Retype Password',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: Icon(hideRetypePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() =>
                      hideRetypePassword = !hideRetypePassword);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: loading ? null : _finishSignup,
                child: const Text('Complete Signup'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
