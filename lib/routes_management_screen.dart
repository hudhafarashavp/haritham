import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/route_provider.dart';
import 'schedule_route_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'models/route_model.dart';
import 'widgets/app_theme.dart';
import 'widgets/custom_widgets.dart';

class RoutesManagementScreen extends StatefulWidget {
  const RoutesManagementScreen({super.key});

  @override
  State<RoutesManagementScreen> createState() => _RoutesManagementScreenState();
}

class _RoutesManagementScreenState extends State<RoutesManagementScreen> {
  String? _panchayathId;
  bool _isLoadingId = true;
  Stream<List<RouteModel>>? _routesStream;

  @override
  void initState() {
    super.initState();
    _loadPanchayathId();
  }

  Future<void> _loadPanchayathId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          _panchayathId = user.uid;
          _isLoadingId = false;
        });
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _panchayathId = prefs.getString('userId');
          _isLoadingId = false;
        });
      }
    }

    // Still listen for changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return;
      if (user != null && _panchayathId != user.uid) {
        setState(() {
          _panchayathId = user.uid;
          _isLoadingId = false;
          _initStream();
        });
      }
    });

    if (_panchayathId != null) {
      _initStream();
    }
  }

  void _initStream() {
    if (_panchayathId != null) {
      _routesStream = Provider.of<RouteProvider>(
        context,
        listen: false,
      ).watchRoutesByPanchayath(_panchayathId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text('Route Management'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingId
          ? const Center(child: CircularProgressIndicator())
          : _panchayathId == null
          ? const Center(
              child: Text('Authentication error. Please log in again.'),
            )
          : _routesStream == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<RouteModel>>(
              stream: _routesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.orange,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Database Syncing...\nIf this persists, check your connection.',
                            style: TextStyle(color: Colors.grey.shade700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          HarithamButton(
                            label: 'RETRY',
                            onPressed: () => setState(() => _initStream()),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final routes = snapshot.data ?? [];

                if (routes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.route_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No routes created yet',
                          style: TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        HarithamButton(
                          label: 'CREATE FIRST ROUTE',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ScheduleRouteScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      route.routeNumber ??
                                          route.routeType ??
                                          'Route',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.harithamGreen,
                                      ),
                                    ),
                                    Text(
                                      DateFormat(
                                        'EEE, MMM d, yyyy',
                                      ).format(route.routeDate),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                _buildStatusBadge(route.status),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildInfoRow(
                              Icons.person_outline,
                              'Worker',
                              route.assignedWorkerName ?? 'Not Assigned',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.location_on_outlined,
                              'Stops',
                              '${route.stops.length} locations',
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ScheduleRouteScreen(route: route),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  label: const Text('VIEW'),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) =>
                                      _handleAction(value, route),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit Route'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'assign',
                                      child: Text('Assign Worker'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'Delete Route',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                  child: const Icon(Icons.more_vert),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScheduleRouteScreen()),
        ),
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'active':
      case 'ongoing':
        color = Colors.blue;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  void _handleAction(String action, RouteModel route) {
    switch (action) {
      case 'edit':
      case 'assign':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ScheduleRouteScreen(route: route)),
        );
        break;
      case 'delete':
        _confirmDelete(route);
        break;
    }
  }

  void _confirmDelete(RouteModel route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<RouteProvider>(
                context,
                listen: false,
              ).deleteRoute(route.routeId);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
