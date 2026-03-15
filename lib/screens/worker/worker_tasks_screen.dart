import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../providers/route_provider.dart';
import '../../models/route_model.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import 'package:provider/provider.dart';

class WorkerTasksScreen extends StatefulWidget {
  final String workerId;
  const WorkerTasksScreen({super.key, required this.workerId});

  @override
  State<WorkerTasksScreen> createState() => _WorkerTasksScreenState();
}

class _WorkerTasksScreenState extends State<WorkerTasksScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assigned Tasks'),
        backgroundColor: AppTheme.harithamGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('workerId', isEqualTo: widget.workerId)
            .orderBy('routeDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tasks = snapshot.data?.docs ?? [];

          if (tasks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: AppTheme.textGrey,
                  ),
                  SizedBox(height: 16),
                  Text('No tasks assigned yet'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.padding),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final taskDoc = tasks[index];
              final taskData = taskDoc.data() as Map<String, dynamic>;
              final routeId = taskData['routeId'];

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('routes')
                    .doc(routeId)
                    .snapshots(),
                builder: (context, routeSnapshot) {
                  if (!routeSnapshot.hasData) return const SizedBox.shrink();

                  final route = RouteModel.fromFirestore(routeSnapshot.data!);
                  return _buildTaskCard(taskDoc.id, taskData['status'], route);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(String taskId, String taskStatus, RouteModel route) {
    return HarithamCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                route.routeNumber ?? 'Route',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.harithamGreen,
                ),
              ),
              _buildStatusBadge(taskStatus),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.calendar_today,
            'Date',
            DateFormat('EEE, MMM d, yyyy').format(route.routeDate),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.location_on,
            'Starts',
            route.startStop ?? 'Assigning...',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(Icons.flag, 'Ends', route.endStop ?? 'Assigning...'),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.list,
            'Stops',
            '${route.stops.length} Locations',
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: HarithamButton(
                  label: 'VIEW MAP',
                  isPrimary: false,
                  icon: Icons.map_outlined,
                  onPressed: () {
                    // Navigate to Map View (Mocking for now as per plan)
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HarithamButton(
                  label: taskStatus == 'completed' ? 'COMPLETED' : 'START',
                  isPrimary: true,
                  icon: taskStatus == 'completed'
                      ? Icons.check_circle
                      : Icons.play_arrow,
                  onPressed: taskStatus == 'completed'
                      ? null
                      : () => _updateStatus(taskId, route.routeId, 'completed'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'completed' ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textGrey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Future<void> _updateStatus(
    String taskId,
    String routeId,
    String status,
  ) async {
    final provider = Provider.of<RouteProvider>(context, listen: false);
    await provider.updateTaskStatus(taskId, status);
    await provider.updateRouteStatus(
      routeId,
      status == 'completed' ? 'Completed' : 'Ongoing',
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Task marked as $status')));
    }
  }
}
