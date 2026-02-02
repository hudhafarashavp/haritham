import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool waste = true;
  bool complaint = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  // Load saved notification preferences
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone');
    if (phone == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      setState(() {
        waste = data['notificationPref']?['waste'] ?? true;
        complaint = data['notificationPref']?['complaint'] ?? true;
      });
    }
  }

  // Save notification preferences
  Future<void> _save() async {
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone');
    if (phone == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({
        'notificationPref': {
          'waste': waste,
          'complaint': complaint,
        }
      });
    }

    setState(() => loading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),

      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E9),
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Notification Settings'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text(
                'Waste Notifications',
                style: TextStyle(color: Colors.green),
              ),
              activeColor: Colors.green,
              value: waste,
              onChanged: (v) => setState(() => waste = v),
            ),

            SwitchListTile(
              title: const Text(
                'Complaint Notifications',
                style: TextStyle(color: Colors.green),
              ),
              activeColor: Colors.green,
              value: complaint,
              onChanged: (v) => setState(() => complaint = v),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: 180,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: loading ? null : _save,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
