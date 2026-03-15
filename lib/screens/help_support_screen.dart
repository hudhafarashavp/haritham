import 'package:flutter/material.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/custom_widgets.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            HarithamCard(
              child: Column(
                children: [
                  _buildContactItem(
                    Icons.email_outlined,
                    'Email Us',
                    'hudhafarasha0@gmail.com',
                  ),
                  const Divider(height: 32),
                  _buildContactItem(
                    Icons.phone_outlined,
                    'Call Us',
                    '9895884756',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const Spacer(),
            Center(
              child: Text(
                'Haritham Support Team',
                style: TextStyle(color: AppTheme.textGrey.withOpacity(0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.mintGreen,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.harithamGreen),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    );
  }
}
