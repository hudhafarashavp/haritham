import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'providers/pickup_provider.dart';
import 'models/pickup_model.dart';
import 'screens/worker/pickup_list_screen.dart';

class PickupCalendarScreen extends StatefulWidget {
  final bool isWorker;
  final String userId;
  final String? routeId; // For workers to see their specific route

  const PickupCalendarScreen({
    super.key,
    required this.isWorker,
    required this.userId,
    this.routeId,
  });

  @override
  State<PickupCalendarScreen> createState() => _PickupCalendarScreenState();
}

class _PickupCalendarScreenState extends State<PickupCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Removed _getStatusColor as it's no longer used

  void _showStatusUpdatePopup(PickupModel pickup) {
    if (!widget.isWorker) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Update Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green, size: 30),
              title: const Text('Mark Completed', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () async {
                await context.read<PickupProvider>().updateStatus(
                  pickup.pickupId,
                  'completed',
                );
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red, size: 30),
              title: const Text('Missed Pickup', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () async {
                await context.read<PickupProvider>().updateStatus(
                  pickup.pickupId,
                  'missed',
                );
                if (mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Removed _showReschedulePicker as it's no longer used in the new status system

  @override
  Widget build(BuildContext context) {
    final pickupProvider = context.read<PickupProvider>();
    late Stream<List<PickupModel>> pickupStream;

    if (widget.isWorker) {
      if (widget.routeId != null) {
        pickupStream = pickupProvider.getPickupsByRouteStream(widget.routeId!);
      } else {
        pickupStream = pickupProvider.getPickupsByWorkerStream(widget.userId);
      }
    } else {
      pickupStream = pickupProvider.getPickupsByCitizenStream(widget.userId);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text(
          widget.isWorker ? 'Route Schedule Calendar' : 'Pickup Calendar',
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<PickupModel>>(
        stream: pickupStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${snapshot.error}\nYou might need to create a Firestore index.'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pickups = snapshot.data ?? [];
          final Map<DateTime, List<PickupModel>> events = {};

          for (var p in pickups) {
            final date = DateTime(
              p.scheduledDate.year,
              p.scheduledDate.month,
              p.scheduledDate.day,
            );
            if (events[date] == null) events[date] = [];
            events[date]!.add(p);
          }

          return Column(
            children: [
              _buildLegend(),
              Card(
                margin: const EdgeInsets.all(12),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      debugPrint('PickupCalendarScreen: Day selected: $selectedDay');
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });

                      debugPrint('PickupCalendarScreen: Navigating to PickupListScreen for ID: ${widget.userId}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PickupListScreen(
                            workerId: widget.userId,
                            selectedDate: selectedDay,
                          ),
                        ),
                      );
                    }
                  },
                  onFormatChanged: (format) =>
                      setState(() => _calendarFormat = format),
                  eventLoader: (day) {
                    return events[DateTime(day.year, day.month, day.day)] ?? [];
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      final pickup = events.first as PickupModel;

                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: pickup.status.toLowerCase() == 'completed'
                                ? Colors.green
                                : pickup.status.toLowerCase() == 'missed'
                                    ? Colors.red
                                    : null,
                            border: (pickup.status.toLowerCase() != 'completed' &&
                                    pickup.status.toLowerCase() != 'missed')
                                ? Border.all(color: Colors.green, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Icon(
                              _getIconForStatus(pickup.status),
                              size: 14,
                              color: (pickup.status.toLowerCase() != 'completed' &&
                                      pickup.status.toLowerCase() != 'missed')
                                  ? Colors.green
                                  : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (!widget.isWorker)
                Expanded(
                  child: _buildPickupList(
                    events[DateTime(
                          _selectedDay!.year,
                          _selectedDay!.month,
                          _selectedDay!.day,
                        )] ??
                        [],
                  ),
                ),
              if (widget.isWorker)
                const Expanded(
                  child: Center(
                    child: Text('Select a date to view pickups'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  IconData _getIconForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check;
      case 'missed':
        return Icons.close;
      case 'pending':
      case 'upcoming':
      default:
        return Icons.circle; // Empty effectively due to color nulling
    }
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _legendItem(Colors.green, 'Completed', solid: true),
          _legendItem(Colors.green, 'Pending', solid: false),
          _legendItem(Colors.red, 'Missed', solid: true),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, {required bool solid}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: solid ? color : null,
            border: !solid ? Border.all(color: color, width: 2) : null,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPickupList(List<PickupModel> dayPickups) {
    if (dayPickups.isEmpty) {
      return const Center(
        child: Text(
          'No houses assigned for pickup on this date.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: dayPickups.length,
      separatorBuilder: (context, index) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final p = dayPickups[index];
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('citizens')
              .doc(p.citizenId)
              .get()
              .then((doc) {
            if (!doc.exists) {
              return FirebaseFirestore.instance
                  .collection('users')
                  .doc(p.citizenId)
                  .get();
            }
            return doc;
          }),
          builder: (context, snapshot) {
            String houseInfo = "House Info Loading...";
            String address = "Address Loading...";

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final hNum = data['houseNumber'] ?? data['house_number'] ?? '';
              final name = data['name'] ?? '';
              houseInfo = hNum.isNotEmpty ? "$hNum / $name" : name;
              address = data['address'] ?? 'No Address';
            } else if (snapshot.hasError) {
              houseInfo = "Error loading house";
              address = "";
            } else if (snapshot.connectionState == ConnectionState.done &&
                !snapshot.data!.exists) {
              houseInfo = "Unknown House";
              address = p.location ?? "No Address Provided";
            }

            final status = p.status.toLowerCase();
            final isCompleted = status == 'completed';
            final isMissed = status == 'missed';

            return InkWell(
              onTap: () => _showStatusUpdatePopup(p),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          houseInfo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Status Circle Icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Colors.green
                          : isMissed
                              ? Colors.red
                              : Colors.transparent,
                      border: (!isCompleted && !isMissed)
                          ? Border.all(color: Colors.green, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: (isCompleted || isMissed)
                          ? Icon(
                              isCompleted ? Icons.check : Icons.close,
                              size: 20,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
