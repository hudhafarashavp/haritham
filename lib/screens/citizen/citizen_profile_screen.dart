import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../payment_history_screen.dart';
import '../../login_screen.dart';
import 'citizen_settings_screen.dart';
import '../edit_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CitizenProfileScreen extends StatefulWidget {
  const CitizenProfileScreen({super.key});

  @override
  State<CitizenProfileScreen> createState() => _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends State<CitizenProfileScreen> {
  String _name = 'Loading...';
  String _id = '';
  String _address = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _name = data['name'] ?? prefs.getString('userName') ?? 'Citizen';
          _id = user.uid.substring(0, 8);
          _address = data['address'] ?? "No address set";
          _phone = data['phone'] ?? "No phone set";
        });
      } else {
        setState(() {
          _name = prefs.getString('userName') ?? 'Citizen';
          _id = user.uid.substring(0, 8);
          _address = "No address set";
          _phone = "No phone set";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_name, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CitizenSettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.softGrey,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(width: 40),
                  const Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'Pickups', count: '24'),
                        _StatItem(label: 'Reports', count: '2'),
                        _StatItem(label: 'Level', count: 'Gold'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Bio Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Citizen ID: #$_id",
                    style: const TextStyle(color: AppTheme.textGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(_address),
                  Text(_phone),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Profile Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: Row(
                children: [
                  Expanded(
                    child: HarithamButton(
                      label: "Edit Profile",
                      isPrimary: false,
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen(role: 'citizen')),
                        );
                        if (result == true) _loadProfile();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),
            // Quick Links
            _ProfileLink(
              icon: Icons.history,
              label: "Payment History",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
              ),
            ),
            _ProfileLink(
              icon: Icons.lock_outline,
              label: "Change Password",
              onTap: () {},
            ),
            _ProfileLink(
              icon: Icons.logout,
              label: "Logout",
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (r) => false,
                  );
                }
              },
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String count;
  const _StatItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
        ),
      ],
    );
  }
}

class _ProfileLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileLink({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.textBlack),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? AppTheme.textBlack,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
