import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../providers/pickup_provider.dart';
import '../../models/pickup_model.dart';

class WorkerPickupScreen extends StatefulWidget {
  const WorkerPickupScreen({super.key});

  @override
  State<WorkerPickupScreen> createState() => _WorkerPickupScreenState();
}

class _WorkerPickupScreenState extends State<WorkerPickupScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Please Login")));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Pickups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: StreamBuilder<List<PickupModel>>(
        stream: context.read<PickupProvider>().getPickupsByWorkerStream(
          user.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pickups = snapshot.data ?? [];
          if (pickups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: AppTheme.borderGrey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No pickups scheduled for today",
                    style: TextStyle(color: AppTheme.textGrey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.padding),
            itemCount: pickups.length,
            itemBuilder: (context, index) {
              final pickup = pickups[index];
              final isCompleted = pickup.status == 'completed';

              return HarithamCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withOpacity(0.1)
                                : AppTheme.softGrey,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_circle
                                : Icons.home_outlined,
                            color: isCompleted
                                ? Colors.green
                                : AppTheme.textBlack,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pickup.location ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Scheduled: ${DateFormat('hh:mm a').format(pickup.scheduledDate)}",
                                style: const TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pickup.status.toUpperCase(),
                            style: TextStyle(
                              color: isCompleted ? Colors.green : Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isCompleted) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: HarithamButton(
                              label: "Mark Completed",
                              onPressed: () => context
                                  .read<PickupProvider>()
                                  .updateStatus(pickup.pickupId, 'completed'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: HarithamButton(
                              label: "Mark Missed",
                              isPrimary: false,
                              onPressed: () => context
                                  .read<PickupProvider>()
                                  .updateStatus(pickup.pickupId, 'missed'),
                            ),
                          ),
                        ],
                      ),
                    ],
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
