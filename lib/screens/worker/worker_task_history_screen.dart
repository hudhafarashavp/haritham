import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../providers/pickup_provider.dart';
import '../../models/pickup_model.dart';

class WorkerTaskHistoryScreen extends StatelessWidget {
  final String workerId;
  const WorkerTaskHistoryScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task History')),
      body: StreamBuilder<List<PickupModel>>(
        stream: context.read<PickupProvider>().getPickupsByWorkerStream(
          workerId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPickups = snapshot.data ?? [];
          final completedPickups = allPickups
              .where((p) => p.status == 'completed')
              .toList();

          if (completedPickups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppTheme.borderGrey),
                  const SizedBox(height: 16),
                  const Text(
                    "No completed tasks yet",
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.padding),
            itemCount: completedPickups.length,
            itemBuilder: (context, index) {
              final pickup = completedPickups[index];
              return HarithamCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pickup.location ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'MMM d, yyyy',
                          ).format(pickup.scheduledDate),
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Citizen ID: ${pickup.citizenId}"),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "COMPLETED",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
