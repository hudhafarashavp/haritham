import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'hks_home_screen.dart';
import 'panchayath_home_screen.dart';
import 'admin_home_screen.dart';
import 'citizen_signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // 👁 NEW ONLY
  bool _hidePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.recycling, size: 100, color: Colors.green),
                const SizedBox(height: 12),

                const Text(
                  'HARITHAM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'Sign in',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    labelText: 'Email / Username',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'This field is required'
                      : null,
                ),

                const SizedBox(height: 16),

                // 🔥 PASSWORD WITH EYE ONLY
                TextFormField(
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _hidePassword = !_hidePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? 'Password is required'
                      : null,
                ),

                const SizedBox(height: 6),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _loading
                      ? null
                      : () {
                    if (_formKey.currentState!.validate()) {
                      _login();
                    }
                  },
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'LOGIN',
                    style:
                    TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CitizenSignupScreen(),
                      ),
                    );
                  },
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // LOGIN LOGIC UNTOUCHED
  Future<void> _login() async {
    final input = _inputController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _loading = true);

    try {
      final usersRef = FirebaseFirestore.instance.collection('users');

      if (input.contains('@')) {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: input,
          password: password,
        );

        if (!cred.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          _showMessage('Please verify your email before login');
          return;
        }

        final citizenSnap = await usersRef
            .where('email', isEqualTo: input)
            .limit(1)
            .get();

        final role = citizenSnap.docs.isNotEmpty
            ? (citizenSnap.docs.first.data()
        as Map<String, dynamic>)['role']
            : 'citizen';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('role', role);

        _go(const HomeScreen());
        return;
      }

      final query = await usersRef
          .where('username', isEqualTo: input)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showMessage('User not found');
        return;
      }

      final data = query.docs.first.data() as Map<String, dynamic>;
      final role = data['role'];

      if ((data['password'] ?? '').toString() != password) {
        _showMessage('Wrong password');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('role', role);

      if (role == 'hks') {
        _go(const HksHomeScreen());
      } else if (role == 'panchayath') {
        _go(const PanchayathHomeScreen());
      } else if (role == 'admin') {
        _go(const AdminHomeScreen());
      } else {
        _showMessage('Invalid role');
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Login failed');
    } catch (e) {
      _showMessage('Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _go(Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(),
      ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
