import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  print("--- DEBUG: VERIFYING USERS IN FIREBASE ---");

  final emails = ['panchayath@test.com', 'hks@test.com'];

  for (var email in emails) {
    print("\nChecking $email...");
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isEmpty) {
        print("RESULT: ❌ NOT FOUND in Firestore");
      } else {
        final data = snapshot.docs.first.data();
        print("RESULT: ✅ FOUND in Firestore");
        print("UID: ${data['uid']}");
        print("Role: ${data['role']}");
      }
    } catch (e) {
      print("ERROR: $e");
    }
  }

  print("\n--- ALL USERS IN COLLECTION ---");
  final all = await FirebaseFirestore.instance.collection('users').get();
  for (var doc in all.docs) {
    print("${doc.id} => ${doc.data()['email']} (${doc.data()['role']})");
  }
  print("\n--- DONE ---");
}
