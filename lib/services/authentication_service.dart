import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Secure Login with Email or Username
  Future<User?> loginWithIdentifier(String identifier, String password) async {
    String? email;

    if (identifier.contains('@')) {
      email = identifier.trim().toLowerCase();
    } else {
      // It's a username, look up email in Firestore
      print("AUTH_SERVICE: Resolving username: $identifier");
      email = await _firestoreService.getUserEmailByUsername(identifier.trim().toLowerCase());

      if (email == null) {
        print("AUTH_SERVICE: Username '$identifier' not found.");
        throw 'user-not-found';
      }
    }

    try {
      print("AUTH_SERVICE: Attempting Sign-In for: $email");
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("AUTH_SERVICE: Sign-In SUCCESS. UID: ${result.user?.uid}");
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("AUTH_SERVICE: Auth Exception: ${e.code}");
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
        throw 'invalid-credential';
      }
      rethrow;
    }
  }

  // Legacy login (optional, but keeping it simple)
  Future<User?> login(String email, String password) =>
      loginWithIdentifier(email, password);

  // Register Citizen
  Future<User?> registerCitizen({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    required String wardNumber,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await _firestoreService.createProfile(user.uid, {
          'uid': user.uid,
          'name': name,
          'email': email.toLowerCase(),
          'phone': phone,
          'address': address,
          'ward_number': wardNumber,
          'role': 'citizen',
          'active': true,
        });
      }
      return user;
    } catch (e) {
      print("Registration error: $e");
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
}
