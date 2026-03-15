import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'models/route_model.dart';
import 'providers/route_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'assign_route_map_screen.dart';

class RouteSchedulingScreen extends StatefulWidget {
  final RouteModel? route;
  const RouteSchedulingScreen({super.key, this.route});

  @override
  State<RouteSchedulingScreen> createState() => _RouteSchedulingScreenState();
}

class _RouteSchedulingScreenState extends State<RouteSchedulingScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _selectedWorkerId;
  String? _selectedWorkerName; // New
  String? _selectedRouteType; // Route 1, Route 2, Route 3

  // New Controllers for the new stop structure
  final TextEditingController _startStopController = TextEditingController();
  final TextEditingController _endStopController = TextEditingController();
  final List<TextEditingController> _intermediateControllers = [];
  List<RouteStop> _mapSelectedStops = [];

  bool _isSaving = false;
  String? _panchayathId;

  @override
  void initState() {
    super.initState();
    _loadPanchayathId();
    if (widget.route != null) {
      _selectedDate = widget.route!.routeDate;
      final timeParts = widget.route!.startTime.split(':');
      if (timeParts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      } else {
        _selectedTime = const TimeOfDay(hour: 8, minute: 0);
      }
      _selectedWorkerId = widget.route!.workerId;
      _selectedWorkerName = widget.route!.assignedWorkerName;
      _selectedRouteType = widget.route!.routeType;
      _startStopController.text = widget.route!.startStop ?? '';
      _endStopController.text = widget.route!.endStop ?? '';
      for (var stop in widget.route!.intermediateStops) {
        _intermediateControllers.add(TextEditingController(text: stop));
      }
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = const TimeOfDay(hour: 8, minute: 0);
    }
  }

  @override
  void dispose() {
    _startStopController.dispose();
    _endStopController.dispose();
    for (var controller in _intermediateControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPanchayathId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _panchayathId = user.uid;
    } else {
      final prefs = await SharedPreferences.getInstance();
      _panchayathId = prefs.getString('userId');
    }
  }

  void _addIntermediateStop() {
    setState(() {
      _intermediateControllers.add(TextEditingController());
    });
  }

  void _removeIntermediateStop(int index) {
    setState(() {
      _intermediateControllers[index].dispose();
      _intermediateControllers.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final routeProvider = Provider.of<RouteProvider>(context, listen: false);

    final intermediateStops = _intermediateControllers
        .map((c) => c.text)
        .toList();

    // Compatibility stops list
    final List<RouteStop> legacyStops = [];

    if (_mapSelectedStops.isNotEmpty) {
      // Use coordinates from map if available
      legacyStops.addAll(_mapSelectedStops);
    } else {
      legacyStops.add(RouteStop(stopName: _startStopController.text));
      legacyStops.addAll(intermediateStops.map((s) => RouteStop(stopName: s)));
      legacyStops.add(RouteStop(stopName: _endStopController.text));
    }

    final routeData = RouteModel(
      routeId: widget.route?.routeId ?? '',
      panchayathId: _panchayathId ?? 'unknown',
      workerId: _selectedWorkerId,
      assignedWorkerName: _selectedWorkerName,
      routeType: _selectedRouteType,
      startStop: _startStopController.text,
      endStop: _endStopController.text,
      intermediateStops: intermediateStops,
      routeDate: _selectedDate,
      startTime:
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      stops: legacyStops,
      totalDistance: 0.0,
      estimatedTime: 'Manual Route',
      createdAt: widget.route?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      status: widget.route?.status ?? 'Scheduled',
    );

    bool success;
    String? newRouteId;

    if (widget.route == null) {
      newRouteId = await routeProvider.addRoute(routeData);
      success = newRouteId != null;
    } else {
      success = await routeProvider.updateRoute(routeData);
      newRouteId = widget.route!.routeId;
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.route == null ? 'Route scheduled!' : 'Route updated!',
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${routeProvider.error}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: Text(widget.route == null ? 'Schedule Route' : 'Edit Route'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- ROUTE NUMBER ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Route Number',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedRouteType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: ['Route 1', 'Route 2', 'Route 3'].map((r) {
                          return DropdownMenuItem(value: r, child: Text(r));
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedRouteType = val),
                        validator: (v) => v == null ? 'Required' : null,
                        hint: const Text('Select Route Number'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- WORKER SELECTION ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned Worker',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('role', whereIn: ['hks', 'hks_worker'])
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return const LinearProgressIndicator();

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                            return const Text(
                              "No workers found",
                              style: TextStyle(color: Colors.red),
                            );

                          var workers = snapshot.data!.docs;

                          return DropdownButtonFormField<String>(
                            value: _selectedWorkerId,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            items: workers.map((w) {
                              final data = w.data() as Map<String, dynamic>;
                              final name =
                                  data['name'] ?? data['username'] ?? 'Unknown';
                              return DropdownMenuItem(
                                value: w.id,
                                child: Text(name),
                              );
                            }).toList(),
                            onChanged: (val) {
                              final workerDoc = workers.firstWhere(
                                (w) => w.id == val,
                              );
                              final workerData =
                                  workerDoc.data() as Map<String, dynamic>;
                              setState(() {
                                _selectedWorkerId = val;
                                _selectedWorkerName =
                                    workerData['name'] ??
                                    workerData['username'] ??
                                    'Unknown';
                              });
                            },
                            hint: const Text('Select a worker'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- ROUTE STOPS ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Route Stops',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final List<RouteStop>? selected =
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AssignRouteMapScreen(
                                        initialStops: widget.route?.stops ?? [],
                                      ),
                                    ),
                                  );

                              if (selected != null && mounted) {
                                setState(() {
                                  if (selected.isNotEmpty) {
                                    _startStopController.text =
                                        selected.first.stopName;
                                    if (selected.length > 1) {
                                      _endStopController.text =
                                          selected.last.stopName;
                                    }
                                    if (selected.length > 2) {
                                      _intermediateControllers.clear();
                                      for (
                                        int i = 1;
                                        i < selected.length - 1;
                                        i++
                                      ) {
                                        _intermediateControllers.add(
                                          TextEditingController(
                                            text: selected[i].stopName,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                  // We will store the coordinates in a temporary list to use during save
                                  _mapSelectedStops = selected;
                                });
                              }
                            },
                            icon: const Icon(Icons.map),
                            label: const Text('ASSIGN VIA MAP'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Start Stop
                      TextFormField(
                        controller: _startStopController,
                        decoration: const InputDecoration(
                          labelText: 'Start Stop',
                          prefixIcon: Icon(Icons.start, color: Colors.blue),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),

                      const SizedBox(height: 16),

                      // Intermediate Stops
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Intermediate Stops',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          TextButton.icon(
                            onPressed: _addIntermediateStop,
                            icon: const Icon(Icons.add),
                            label: const Text('ADD'),
                          ),
                        ],
                      ),

                      ...List.generate(_intermediateControllers.length, (
                        index,
                      ) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _intermediateControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Intermediate Stop ${index + 1}',
                                    isDense: true,
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeIntermediateStop(index),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // End Stop
                      TextFormField(
                        controller: _endStopController,
                        decoration: const InputDecoration(
                          labelText: 'End Stop',
                          prefixIcon: Icon(Icons.flag, color: Colors.green),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- DATE & TIME ---
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.green,
                      ),
                      title: const Text('Route Date'),
                      subtitle: Text(
                        DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                      ),
                      trailing: TextButton(
                        onPressed: () => _selectDate(context),
                        child: const Text('CHANGE'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.access_time,
                        color: Colors.green,
                      ),
                      title: const Text('Start Time'),
                      subtitle: Text(_selectedTime.format(context)),
                      trailing: TextButton(
                        onPressed: () => _selectTime(context),
                        child: const Text('CHANGE'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.route == null
                            ? 'SCHEDULE ROUTE'
                            : 'UPDATE ROUTE',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
