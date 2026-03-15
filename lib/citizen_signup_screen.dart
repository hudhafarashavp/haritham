import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';

class CitizenSignupScreen extends StatefulWidget {
  const CitizenSignupScreen({super.key});

  @override
  State<CitizenSignupScreen> createState() => _CitizenSignupScreenState();
}

class _CitizenSignupScreenState extends State<CitizenSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  int currentStep = 0; // 0: Details, 1: Verification, 2: Credentials

  // Step 1 Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController houseNumberController = TextEditingController();
  final TextEditingController wardNumberController = TextEditingController();
  final TextEditingController panchayatController = TextEditingController();

  // Step 3 Controllers
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  Future<void> _sendVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);
    try {
      final email = emailController.text.trim();
      // Create user with a temporary password (will be updated in Step 3)
      final tempPassword = "TempPassword123!"; 
      
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );

      final user = userCredential.user;
      if (user == null) throw Exception("User creation failed");

      await user.sendEmailVerification();
      
      setState(() => currentStep = 1);
      _show('Verification email sent to $email');
    } on FirebaseAuthException catch (e) {
      String msg = 'Signup failed';
      if (e.code == 'email-already-in-use') msg = 'Email already registered';
      _show(msg);
    } catch (e) {
      _show('Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      if (user != null && user.emailVerified) {
        setState(() => currentStep = 2);
        _show('Email verified successfully!');
      } else {
        _show('Email not verified yet. Please check your inbox.');
      }
    } catch (e) {
      _show('Error checking verification: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _finalizeAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (passwordController.text != confirmPasswordController.text) {
      _show('Passwords do not match');
      return;
    }

    setState(() => loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User session lost");

      // Update password
      await user.updatePassword(passwordController.text.trim());

      // Save to Firestore
      final firestoreService = FirestoreService();
      await firestoreService.finalizeCitizenSignup(user.uid, {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'houseNumber': houseNumberController.text.trim(),
        'wardNumber': wardNumberController.text.trim(),
        'panchayat': panchayatController.text.trim(),
        'username': usernameController.text.trim(),
      });

      _show('Account created successfully!');
      if (!mounted) return;
      Navigator.pop(context); // Back to login
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
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    houseNumberController.dispose();
    wardNumberController.dispose();
    panchayatController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Citizen Signup', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentStep == 0) _buildStep1(),
              if (currentStep == 1) _buildStep2(),
              if (currentStep == 2) _buildStep3(),
            ],
          ),
        ),
      ),
    );
  }

  // --- STEP 1: BASIC DETAILS ---
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Name'),
        _buildInput(nameController, 'Enter your name', Icons.person_outline),
        _buildLabel('Email'),
        _buildInput(emailController, 'Enter your email', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        _buildLabel('Phone Number'),
        _buildInput(phoneController, 'Enter 10-digit phone', Icons.phone_outlined, keyboardType: TextInputType.number, maxLength: 10),
        _buildLabel('House Number'),
        _buildInput(houseNumberController, 'Enter house number', Icons.home_outlined),
        _buildLabel('Ward Number'),
        _buildInput(wardNumberController, 'Enter ward number', Icons.map_outlined),
        _buildLabel('Panchayat'),
        _buildInput(panchayatController, 'Enter panchayat', Icons.location_city_outlined),
        const SizedBox(height: 32),
        _buildButton('SEND VERIFICATION', _sendVerification),
      ],
    );
  }

  // --- STEP 2: VERIFY EMAIL ---
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.mark_email_read_outlined, size: 100, color: Colors.green),
        const SizedBox(height: 24),
        const Text(
          'Verify Email',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'A verification link has been sent to your email. Please check your email and verify.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 48),
        _buildButton('CHECK VERIFICATION', _checkVerification),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => currentStep = 0),
          child: const Text('Back to Edit Details', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  // --- STEP 3: CREATE CREDENTIALS ---
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Credentials',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 8),
        const Text('Finalize your login details', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 32),
        _buildLabel('Username'),
        _buildInput(usernameController, 'Choose a username', Icons.alternate_email_outlined),
        _buildLabel('Password'),
        _buildPasswordInput(passwordController, 'Minimum 6 characters'),
        _buildLabel('Confirm Password'),
        _buildPasswordInput(confirmPasswordController, 'Re-type password', isConfirm: true),
        const SizedBox(height: 32),
        _buildButton('CREATE ACCOUNT', _finalizeAccount),
      ],
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.green, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.green)),
        filled: true,
        fillColor: Colors.grey.shade50,
        counterText: "",
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (maxLength == 10 && v.length != 10) return 'Must be 10 digits';
        if (keyboardType == TextInputType.emailAddress && !v.contains('@')) return 'Invalid email';
        return null;
      },
    );
  }

  Widget _buildPasswordInput(TextEditingController controller, String hint, {bool isConfirm = false}) {
    return TextFormField(
      controller: controller,
      obscureText: !isConfirm ? hidePassword : true,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.green, size: 20),
        suffixIcon: !isConfirm ? IconButton(
          icon: Icon(hidePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
          onPressed: () => setState(() => hidePassword = !hidePassword),
        ) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.green)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (v.length < 6) return 'Min 6 characters';
        if (isConfirm && v != passwordController.text) return 'Passwords mismatch';
        return null;
      },
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
