import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/route_model.dart';
import 'providers/route_provider.dart';
import 'route_map_view.dart';
import 'services/location_service.dart';

class WorkerRouteSequenceScreen extends StatefulWidget {
  final RouteModel route;
  const WorkerRouteSequenceScreen({super.key, required this.route});

  @override
  State<WorkerRouteSequenceScreen> createState() =>
      _WorkerRouteSequenceScreenState();
}

class _WorkerRouteSequenceScreenState extends State<WorkerRouteSequenceScreen> {
  late RouteModel _route;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _route = widget.route;
    _startTracking();
  }

  Future<void> _startTracking() async {
    if (_route.workerId != null) {
      try {
        await _locationService.startTracking(_route.workerId!);
      } catch (e) {
        debugPrint('Location tracking error: $e');
      }
    }
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    super.dispose();
  }

  Future<void> _updateStopStatus(
    String routeId,
    int index,
    String status,
  ) async {
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    await routeProvider.updateStopStatus(routeId, index, status);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RouteModel?>(
      stream: Provider.of<RouteProvider>(
        context,
        listen: false,
      ).watchRouteById(widget.route.routeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final route = snapshot.data;
        if (route == null) {
          return const Scaffold(body: Center(child: Text('Route not found')));
        }

        final completedStops = route.stops
            .where((s) => s.status == 'Completed')
            .length;
        final totalStops = route.stops.length;
        final progress = totalStops > 0 ? completedStops / totalStops : 0.0;

        return Scaffold(
          backgroundColor: const Color(0xFFF1F8E9),
          appBar: AppBar(
            title: const Text('Route Execution'),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.map),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RouteMapView(route: route)),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // --- PROGRESS HEADER ---
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.green.shade700,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Overall Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$completedStops / $totalStops Stops',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.green.shade900,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),

              // --- STOP LIST ---
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: route.stops.length,
                  itemBuilder: (context, index) {
                    final stop = route.stops[index];
                    final isCompleted = stop.status == 'Completed';
                    final isCurrent =
                        !isCompleted &&
                        (index == 0 ||
                            route.stops[index - 1].status == 'Completed');

                    return Card(
                      elevation: isCurrent ? 4 : 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isCurrent
                            ? BorderSide(color: Colors.green.shade700, width: 2)
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isCompleted
                              ? Colors.green
                              : (isCurrent ? Colors.blue : Colors.grey),
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white)
                              : Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                        ),
                        title: Text(
                          stop.stopName,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text('Status: ${stop.status}'),
                        trailing: isCompleted
                            ? null
                            : Checkbox(
                                value: false,
                                onChanged: isCurrent
                                    ? (val) => _updateStopStatus(
                                        route.routeId,
                                        index,
                                        'Completed',
                                      )
                                    : null,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RouteMapView(route: route)),
              ),
              icon: const Icon(Icons.map),
              label: const Text('VIEW FULL MAP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
