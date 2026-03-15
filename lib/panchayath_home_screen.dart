import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'routes_management_screen.dart';
import 'login_screen.dart';
import 'notification_screen.dart';
import 'create_notification_screen.dart';
import 'panchayath_notification_management_screen.dart';
import 'panchayath_complaints_screen.dart';
import 'panchayath_illegal_dumping_screen.dart';
import 'panchayath_hks_complaints_screen.dart';
import 'worker_management_screen.dart';
import 'screens/citizen/citizen_settings_screen.dart';

class PanchayathHomeScreen extends StatelessWidget {
  const PanchayathHomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9), // Very light green
      appBar: AppBar(
        title: const Text(
          'Panchayath Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeaderSection(),
            const SizedBox(height: 24),
            const _SummarySection(),
            const SizedBox(height: 32),
            Text(
              "Administrative Actions",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 16),
            const _ActionGrid(),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back, Admin",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900,
          ),
        ),
        Text(
          "Manage and monitor your panchayath's waste management status.",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.green.shade800),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _CounterCard(
              title: "Citizen Complaints",
              subtitle: "Pending",
              collection: "complaints",
              query: (q) => q.where('status', isEqualTo: 'pending'),
              icon: Icons.people_outline,
              color: Colors.red.shade400,
            ),
            _CounterCard(
              title: "HKS Complaints",
              subtitle: "Pending",
              collection: "hks_complaints",
              query: (q) => q.where('status', isEqualTo: 'pending'),
              icon: Icons.work_history_outlined,
              color: Colors.orange.shade400,
            ),
            _CounterCard(
              title: "Active Workers",
              subtitle: "Total",
              collection: "users",
              query: (q) => q.where('role', isEqualTo: 'hks'),
              icon: Icons.groups_outlined,
              color: Colors.blue.shade400,
            ),
            _CounterCard(
              title: "Schedules",
              subtitle: "Assigned Today",
              collection: "worker_schedules",
              query: (q) {
                final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                return q.where('date', isEqualTo: today);
              },
              icon: Icons.calendar_today_outlined,
              color: Colors.teal.shade400,
            ),
            _CounterCard(
              title: "Payments",
              subtitle: "Total Completed",
              collection: "payments",
              query: (q) => q.where('paymentStatus', isEqualTo: 'completed'),
              icon: Icons.payments_outlined,
              color: Colors.green.shade400,
            ),
          ],
        );
      },
    );
  }
}

class _CounterCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String collection;
  final Query Function(Query) query;
  final IconData icon;
  final Color color;

  const _CounterCard({
    required this.title,
    required this.subtitle,
    required this.collection,
    required this.query,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                StreamBuilder<QuerySnapshot>(
                  stream: query(
                    FirebaseFirestore.instance.collection(collection),
                  ).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    return Text(
                      "${snapshot.data?.docs.length ?? 0}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _ActionCard(
          title: "Announcements",
          icon: Icons.campaign,
          color: Colors.green.shade600,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateNotificationScreen()),
          ),
        ),
        _ActionCard(
          title: "Manage Alerts",
          icon: Icons.edit_notifications,
          color: Colors.green.shade600,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PanchayathNotificationManagementScreen(),
            ),
          ),
        ),
        _ActionCard(
          title: "Citizen Reports",
          icon: Icons.assignment,
          color: Colors.green.shade600,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PanchayathComplaintsScreen(),
            ),
          ),
        ),
        _ActionCard(
          title: "HKS Feedback",
          icon: Icons.rate_review,
          color: Colors.green.shade600,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PanchayathHksComplaintsScreen(),
            ),
          ),
        ),
        _ActionCard(
          title: "Illegal Dumping",
          icon: Icons.delete_forever,
          color: Colors.red.shade600,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PanchayathIllegalDumpingScreen(),
            ),
          ),
        ),
        _ActionCard(
          title: "Workforce",
          icon: Icons.badge,
          color: Colors.blue.shade600,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkerManagementScreen()),
          ),
        ),
        _ActionCard(
          title: "Manage Routes",
          icon: Icons.add_location_alt,
          color: Colors.teal.shade600,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoutesManagementScreen()),
          ),
        ),
        _ActionCard(
          title: "Profile & Settings",
          icon: Icons.settings,
          color: Colors.blueGrey,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CitizenSettingsScreen(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.green.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
