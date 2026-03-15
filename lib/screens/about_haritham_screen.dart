import 'package:flutter/material.dart';
import '../../widgets/app_theme.dart';

class AboutHarithamScreen extends StatelessWidget {
  const AboutHarithamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Haritham')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.recycling, size: 80, color: AppTheme.harithamGreen),
            ),
            const SizedBox(height: 24),
            Text(
              'Haritham Waste Management System',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.harithamGreen,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Haritham is a comprehensive waste management application designed to streamline the collection, monitoring, and reporting of waste within panchayaths. Our mission is to promote a cleaner and greener environment through efficient resource management and community participation.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem(Icons.location_on, 'Real-time worker tracking'),
            _buildFeatureItem(Icons.report_problem, 'Citizen complaint reporting'),
            _buildFeatureItem(Icons.calendar_today, 'Scheduled waste collection'),
            _buildFeatureItem(Icons.payment, 'Seamless payment history'),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: AppTheme.textGrey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.harithamGreen),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
