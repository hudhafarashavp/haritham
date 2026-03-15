import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../widgets/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import '../../worker_calendar_screen.dart';
import 'worker_task_history_screen.dart';
import 'worker_payment_requests_screen.dart';
import '../../worker_management_screen.dart';
import '../../create_complaint_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/pickup_provider.dart';
import '../../models/pickup_model.dart';
import 'worker_tasks_screen.dart';
import 'pickup_list_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  String? _workerId;
  String _workerName = 'Worker';
  late Stream<List<PickupModel>> _pickupsStream;
  bool _isInit = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Location Tracking State
  bool _locationEnabled = false;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadLocationSettings();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadLocationSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('workers').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _locationEnabled = data['locationEnabled'] ?? false;
          });
          if (_locationEnabled) {
            _startTracking();
          }
        }
      } catch (e) {
        debugPrint('Error loading home screen location settings: $e');
      }
    }
  }

  Future<void> _toggleLocation(bool value) async {
    if (value) {
      bool permissionGranted = await _handleLocationPermission();
      if (permissionGranted) {
        await _updateFirestoreStatus(true);
        _startTracking();
      } else {
        setState(() => _locationEnabled = false);
      }
    } else {
      await _updateFirestoreStatus(false);
      _stopTracking();
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.')),
          );
        }
        return false;
      }
    }
    return true;
  }

  void _startTracking() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _updateLocationInFirestore(position);
    });
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  Future<void> _updateFirestoreStatus(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('workers').doc(user.uid).update({
        'locationEnabled': enabled,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _updateLocationInFirestore(Position position) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('workers').doc(user.uid).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _loadUserInfo();
      _isInit = true;
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _workerId = user.uid;
        _workerName = prefs.getString('userName') ?? 'Worker';
        _pickupsStream = Provider.of<PickupProvider>(
          context,
          listen: false,
        ).getPickupsByWorkerStream(_workerId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Haritham Worker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _workerName,
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 12),
            // LOCATION TRACKING CARD (Forcefully implemented for HKS workers)
            Card(
              margin: const EdgeInsets.all(12),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Colors.green),
                title: const Text("Location Tracking"),
                subtitle: const Text("Enable GPS tracking"),
                trailing: Switch(
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                    _toggleLocation(value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCalendar(),
            const SizedBox(height: 24),

            if (_workerId == null)
              const Center(child: CircularProgressIndicator())
            else
              StreamBuilder<List<PickupModel>>(
                stream: _pickupsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  final pickups = snapshot.data ?? [];
                  final today = DateTime.now();
                  final todayPickups = pickups
                      .where(
                        (p) =>
                            p.scheduledDate.year == today.year &&
                            p.scheduledDate.month == today.month &&
                            p.scheduledDate.day == today.day,
                      )
                      .toList();

                  final completed = pickups
                      .where((p) => p.status == 'completed')
                      .length;
                  final pending = pickups
                      .where(
                        (p) =>
                            p.status == 'upcoming' || p.status == 'rescheduled',
                      )
                      .length;
                  final missed = pickups
                      .where((p) => p.status == 'missed')
                      .length;

                  return Column(
                    children: [
                      Row(
                        children: [
                          _StatCard(
                            label: "Today's",
                            count: todayPickups.length.toString(),
                            color: Colors.blue,
                            icon: Icons.today,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: "Completed",
                            count: completed.toString(),
                            color: AppTheme.harithamGreen,
                            icon: Icons.check_circle_outline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatCard(
                            label: "Pending",
                            count: pending.toString(),
                            color: Colors.orange,
                            icon: Icons.pending_actions,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: "Missed",
                            count: missed.toString(),
                            color: Colors.red,
                            icon: Icons.error_outline,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 32),
            const Text(
              "Quick Actions",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _buildActionCard(
                  context,
                  Icons.calendar_month_outlined,
                  "View Pickup\nCalendar",
                  () {
                    if (_workerId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkerCalendarScreen(workerId: _workerId!),
                        ),
                      );
                    }
                  },
                ),
                _buildActionCard(
                  context,
                  Icons.assignment_turned_in_outlined,
                  "My Assigned\nTasks",
                  () {
                    if (_workerId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              WorkerTasksScreen(workerId: _workerId!),
                        ),
                      );
                    }
                  },
                ),
                _buildActionCard(
                  context,
                  Icons.payment_outlined,
                  "Pending\nPayments",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkerPaymentRequestsScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(context, Icons.history, "Task\nHistory", () {
                  if (_workerId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WorkerTaskHistoryScreen(workerId: _workerId!),
                      ),
                    );
                  }
                }),
                _buildActionCard(
                  context,
                  Icons.people_outline,
                  "Workforce\nManagement",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkerManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  Icons.report_problem_outlined,
                  "Submit\nComplaint",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateComplaintScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return HarithamCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: AppTheme.harithamGreen),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return HarithamCard(
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            debugPrint('WorkerHomeScreen: Day selected: $selectedDay');
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            
            final currentWorkerId = _workerId ?? FirebaseAuth.instance.currentUser?.uid ?? 'unknown_worker';
            
            debugPrint('WorkerHomeScreen: Navigating to PickupListScreen for worker: $currentWorkerId');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PickupListScreen(
                  workerId: currentWorkerId,
                  selectedDate: selectedDay,
                ),
              ),
            );
          }
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppTheme.harithamGreen.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppTheme.harithamGreen,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
