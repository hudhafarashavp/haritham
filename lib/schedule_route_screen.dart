import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/route_model.dart';
import 'providers/route_provider.dart';
import 'widgets/app_theme.dart';
import 'widgets/custom_widgets.dart';
import 'assign_route_map_screen.dart';

class ScheduleRouteScreen extends StatefulWidget {
  final RouteModel? route;
  const ScheduleRouteScreen({super.key, this.route});

  @override
  State<ScheduleRouteScreen> createState() => _ScheduleRouteScreenState();
}

class _ScheduleRouteScreenState extends State<ScheduleRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  String? _selectedRouteNumber;
  String? _selectedWorkerId;
  String? _selectedWorkerName;

  final TextEditingController _startStopController = TextEditingController();
  final TextEditingController _endStopController = TextEditingController();
  final List<TextEditingController> _intermediateControllers = [];
  List<RouteStop> _mapSelectedStops = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.route != null) {
      _selectedDate = widget.route!.routeDate;
      _selectedRouteNumber = widget.route!.routeType;
      _selectedWorkerId = widget.route!.workerId;
      _selectedWorkerName = widget.route!.assignedWorkerName;
      _startStopController.text = widget.route!.startStop ?? '';
      _endStopController.text = widget.route!.endStop ?? '';
      for (var stop in widget.route!.intermediateStops) {
        _intermediateControllers.add(TextEditingController(text: stop));
      }
    } else {
      _selectedDate = DateTime.now();
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _addStop() {
    setState(() => _intermediateControllers.add(TextEditingController()));
  }

  void _removeStop(int index) {
    setState(() => _intermediateControllers.removeAt(index));
  }

  Future<void> _saveRoute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final provider = context.read<RouteProvider>();

      final routeData = RouteModel(
        routeId: widget.route?.routeId ?? '',
        panchayathId: user?.uid ?? 'system',
        routeName: _selectedRouteNumber ?? 'New Route',
        routeType: _selectedRouteNumber,
        workerId: _selectedWorkerId,
        assignedWorkerName: _selectedWorkerName,
        startStop: _startStopController.text,
        endStop: _endStopController.text,
        intermediateStops: _intermediateControllers.map((c) => c.text).toList(),
        routeDate: _selectedDate,
        startTime: "08:00", // Default
        stops: _mapSelectedStops.isNotEmpty
            ? _mapSelectedStops
            : [
                RouteStop(stopName: _startStopController.text),
                ..._intermediateControllers.map(
                  (c) => RouteStop(stopName: c.text),
                ),
                RouteStop(stopName: _endStopController.text),
              ],
        createdAt: widget.route?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.route == null) {
        await provider.addRoute(routeData);
      } else {
        await provider.updateRoute(routeData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Route'),
        backgroundColor: AppTheme.harithamGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildRouteNumberCard(),
              const SizedBox(height: 16),
              _buildWorkerCard(),
              const SizedBox(height: 16),
              _buildStopsCard(),
              const SizedBox(height: 16),
              _buildDateCard(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: HarithamButton(
                  label: _isSaving ? 'SAVING...' : 'SAVE ROUTE',
                  onPressed: _isSaving ? null : _saveRoute,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteNumberCard() {
    return HarithamCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Number',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedRouteNumber,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.softGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: ['Route 1', 'Route 2', 'Route 3', 'Route 4'].map((r) {
              return DropdownMenuItem(value: r, child: Text(r));
            }).toList(),
            onChanged: (v) => setState(() => _selectedRouteNumber = v),
            validator: (v) => v == null ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard() {
    return HarithamCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assigned Worker',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', whereIn: ['hks', 'hks_worker'])
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              final workers = snapshot.data?.docs ?? [];
              return DropdownButtonFormField<String>(
                value: _selectedWorkerId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.softGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                hint: const Text('Select Worker'),
                items: workers.map((w) {
                  final data = w.data() as Map<String, dynamic>;
                  final name = data['name'] ?? data['username'] ?? 'Unit';
                  final hksId = data['hksId'] ?? 'ID: ${w.id.substring(0, 5)}';
                  return DropdownMenuItem(
                    value: w.id,
                    child: Text('$name ($hksId)'),
                  );
                }).toList(),
                onChanged: (v) {
                  final worker = workers.firstWhere((w) => w.id == v);
                  final data = worker.data() as Map<String, dynamic>;
                  setState(() {
                    _selectedWorkerId = v;
                    _selectedWorkerName = data['name'] ?? data['username'];
                  });
                },
                validator: (v) => v == null ? 'Required' : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStopsCard() {
    return HarithamCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Route Stops',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () async {
                  final List<RouteStop>? selected = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssignRouteMapScreen(
                        initialStops: widget.route?.stops ?? [],
                      ),
                    ),
                  );

                  if (selected != null && mounted) {
                    setState(() {
                      _mapSelectedStops = selected;
                      if (selected.isNotEmpty) {
                        _startStopController.text = selected.first.stopName;
                        if (selected.length > 1) {
                          _endStopController.text = selected.last.stopName;
                        }
                        _intermediateControllers.clear();
                        if (selected.length > 2) {
                          for (int i = 1; i < selected.length - 1; i++) {
                            _intermediateControllers.add(
                              TextEditingController(text: selected[i].stopName),
                            );
                          }
                        }
                      }
                    });
                  }
                },
                icon: const Icon(Icons.map, color: AppTheme.harithamGreen),
                label: const Text(
                  'ASSIGN VIA MAP',
                  style: TextStyle(color: AppTheme.harithamGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStopField(
            'START STOP',
            _startStopController,
            Icons.arrow_forward,
            Colors.blue,
          ),
          const Divider(height: 32),
          const Text(
            'INTERMEDIATE STOPS',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...List.generate(_intermediateControllers.length, (idx) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.softGrey,
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _intermediateControllers[idx],
                      decoration: const InputDecoration(
                        hintText: 'Location Name',
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _removeStop(idx),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: _addStop,
            icon: const Icon(Icons.add),
            label: const Text('ADD STOP'),
          ),
          const Divider(height: 32),
          _buildStopField(
            'END STOP',
            _endStopController,
            Icons.flag,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStopField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.textGrey,
          ),
        ),
        Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Select Location',
                  border: InputBorder.none,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateCard() {
    return HarithamCard(
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: AppTheme.harithamGreen),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Route Date',
                  style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
                ),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _selectDate,
            child: const Text(
              'CHANGE',
              style: TextStyle(
                color: AppTheme.harithamGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
