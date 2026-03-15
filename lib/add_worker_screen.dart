import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:haritham/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddWorkerScreen extends StatefulWidget {
  const AddWorkerScreen({super.key});

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final wardController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> addWorker() async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        emailController.text.isEmpty ||
        usernameController.text.isEmpty ||
        wardController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final userService = UserService(); // Declaration added here
      // 0. Check for unique username
      final String username = usernameController.text.trim();
      final String email = emailController.text.trim();
      final String password = passwordController.text.trim();

      final usernameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      bool existsInFirestore = usernameQuery.docs.isNotEmpty;

      // 1. Create worker account in Firebase Auth
      UserCredential? userCred;
      try {
        userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // If it exists in Auth AND Firestore, then it's actually taken.
          if (existsInFirestore) {
            throw 'Username and Email are already taken.';
          } else {
            // Exists in Auth but not Firestore? Unusual, but we can't link without UID.
            throw 'Email is already taken in Authentication system.';
          }
        }
        rethrow;
      }

      final String uid = userCred.user!.uid;

      // 2. Save worker profile using standardized UserService
      await userService.createWorker(
        uid: uid,
        name: nameController.text.trim(),
        username: username.toLowerCase(),
        email: email.toLowerCase(),
        phone: phoneController.text.trim(),
        role: 'hks_worker', // Standardized role
      );

      // 3. Save additional HKS specific data if needed
      await FirebaseFirestore.instance.collection('workers').doc(uid).update({
        'wardNo': wardController.text.trim(),
        'active': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Worker added successfully")),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Authentication failed")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Worker"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Worker Name"),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Phone"),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "Username"),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: wardController,
                decoration: const InputDecoration(labelText: "Ward No"),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : addWorker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save Worker"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
