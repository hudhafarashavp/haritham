import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> initializeTestUsers() async {
  print("--- DEBUG: Creating/Verifying Master Test Users ---");

  final users = [
    {
      'email': 'panchayath@test.com',
      'password': '123456',
      'role': 'panchayath',
      'name': 'Panchayath Admin',
      'username': 'panchayath_admin',
    },
    {
      'email': 'panchayath1@test.com',
      'password': '123456',
      'role': 'panchayath',
      'name': 'Panchayath Alpha',
      'username': 'panchayath1',
    },
    {
      'email': 'panchayath2@test.com',
      'password': '123456',
      'role': 'panchayath',
      'name': 'Panchayath Beta',
      'username': 'panchayath2',
    },
    {
      'email': 'hks@test.com',
      'password': '123456',
      'role': 'hks',
      'name': 'HKS Worker',
      'username': 'hks_worker',
    },
    {
      'email': 'hks1@test.com',
      'password': '123456',
      'role': 'hks',
      'name': 'HKS Unit 1',
      'username': 'hks1',
    },
    {
      'email': 'hks2@test.com',
      'password': '123456',
      'role': 'hks',
      'name': 'HKS Unit 2',
      'username': 'hks2',
    },
    {
      'email': 'citizen@test.com',
      'password': '123456',
      'role': 'citizen',
      'name': 'Test Citizen',
      'username': 'citizen_test',
    },
  ];

  for (var u in users) {
    try {
      print("\n[STEP] Processing ${u['email']}...");
      UserCredential credential;
      try {
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: u['email']!,
          password: u['password']!,
        );
        print("✅ Auth account CREATED: ${credential.user?.uid}");
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          print("ℹ️ Auth account already exists. Signing in...");
          credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: u['email']!,
            password: u['password']!,
          );
          print("✅ Auth account VERIFIED: ${credential.user?.uid}");
        } else {
          print("❌ Auth Error: ${e.code} - ${e.message}");
          rethrow;
        }
      }

      final uid = credential.user!.uid;

      // Update Firestore WITHOUT storing password
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': u['email']!.toLowerCase(),
        'username': u['username']!.toString().toLowerCase(),
        'role': u['role'],
        'name': u['name'],
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("✅ Firestore record SYNCED for UID: $uid");
    } catch (e) {
      print("❌ CRITICAL Error processing ${u['email']}: $e");
    }
  }

  print("\n[STEP] Cleaning up legacy data (removing 'password' fields)...");
  final cleanupSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .get();
  for (var doc in cleanupSnapshot.docs) {
    if (doc.data().containsKey('password')) {
      await doc.reference.update({'password': FieldValue.delete()});
      print("🗑️ Removed 'password' field from UID: ${doc.id}");
    }
  }

  print("\n--- FINAL SYSTEM CHECK: Firestore Users ---");
  final snapshot = await FirebaseFirestore.instance.collection('users').get();
  for (var doc in snapshot.docs) {
    final d = doc.data();
    print(
      "UID: ${doc.id.padRight(28)} | Role: ${d['role']?.toString().padRight(12)} | Email: ${d['email']}",
    );
  }
  print("\n--- DEBUG SCRIPT COMPLETE ---");
}
