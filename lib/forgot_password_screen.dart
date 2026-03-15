import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController identifierController = TextEditingController();
  bool loading = false;

  Future<void> _sendResetLink() async {
    final identifier = identifierController.text.trim();
    if (identifier.isEmpty) {
      _show('Please enter your username or email');
      return;
    }

    setState(() => loading = true);
    try {
      final firestoreService = FirestoreService();
      
      // Attempt to resolve email if username is provided
      String email = identifier;
      if (!identifier.contains('@')) {
        final resolvedEmail = await firestoreService.getUserEmailByUsername(identifier);
        if (resolvedEmail == null) {
          _show('User not found');
          return;
        }
        email = resolvedEmail;
      }

      // 1. Send password reset email using Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      _show('Password reset link sent to your email.');

      if (!mounted) return;
      // After sending the link, we can go back to login since the user handles the rest via email
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = 'Failed to send reset email';
      if (e.code == 'user-not-found') msg = 'No user found with this email';
      if (e.code == 'invalid-email') msg = 'Invalid email address';
      _show(msg);
    } catch (e) {
      _show('Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    identifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Reset Password',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter your registered email or username and we will send you a reset link.',
                textAlign: TextAlign.left,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 48),
              
              const Text(
                'Email / Username',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: identifierController,
                decoration: InputDecoration(
                  hintText: 'Enter your email or username',
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.green),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 48),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: loading ? null : _sendResetLink,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'SEND RESET LINK',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Login', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
