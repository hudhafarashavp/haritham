import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/pickup_model.dart';

class PickupListScreen extends StatefulWidget {
  final String workerId;
  final DateTime selectedDate;

  const PickupListScreen({
    super.key,
    required this.workerId,
    required this.selectedDate,
  });

  @override
  State<PickupListScreen> createState() => _PickupListScreenState();
}

class _PickupListScreenState extends State<PickupListScreen> {
  bool _isLoading = false;
  final Map<String, String> _unsavedChanges = {};

  final List<Map<String, String>> _skeleton = [
    {'ward': 'Ward 1', 'name': 'Anil Kumar', 'house': '12', 'addr': 'Vazhathope, Idukki'},
    {'ward': 'Ward 1', 'name': 'Suma Teacher', 'house': '14', 'addr': 'Vazhathope, Idukki'},
    {'ward': 'Ward 1', 'name': 'Joseph Mathew', 'house': '18', 'addr': 'Vazhathope, Idukki'},
    {'ward': 'Ward 2', 'name': 'Babu Varghese', 'house': '4', 'addr': 'Vazhathope, Idukki'},
    {'ward': 'Ward 2', 'name': 'Latha Krishnan', 'house': '6', 'addr': 'Vazhathope, Idukki'},
    {'ward': 'Ward 2', 'name': 'Sunil Kumar', 'house': '8', 'addr': 'Vazhathope, Idukki'},
    {'ward': 'Ward 3', 'name': 'Rajan', 'house': '2', 'addr': 'Vazhathope, Idukki'},
    {'ward': 'Ward 3', 'name': 'Beena', 'house': '5', 'addr': 'Vazhathope, Idukki'},
  ];

  @override
  void initState() {
    super.initState();
  }

  // Helper to get normalized date (midnight)
  DateTime get _normalizedDate => DateTime(
    widget.selectedDate.year,
    widget.selectedDate.month,
    widget.selectedDate.day,
  );

  String _generateDocId(String houseId) {
    // Format: workerId_houseId_yyyy-MM-dd
    String dateStr = DateFormat('yyyy-MM-dd').format(_normalizedDate);
    return "${widget.workerId}_${houseId}_$dateStr";
  }

  void _showStatusUpdateOptions(PickupModel pickup) {
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
              'Mark Pickup Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green, size: 30),
              title: const Text('Mark Completed', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => _updateLocalStatus(pickup, 'completed'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red, size: 30),
              title: const Text('Missed Pickup', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => _updateLocalStatus(pickup, 'missed'),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.grey, size: 30),
              title: const Text('Reset to Pending', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => _updateLocalStatus(pickup, 'pending'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _updateLocalStatus(PickupModel pickup, String status) {
    if (pickup.houseId != null) {
      setState(() {
        _unsavedChanges[pickup.houseId!] = status;
      });
    }
    Navigator.pop(context);
  }

  void _showSaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Save'),
        content: Text('Do you want to save the pickup updates for ${_unsavedChanges.length} houses?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveAllChanges();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            child: const Text('Yes, Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAllChanges() async {
    setState(() => _isLoading = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection('pickup_status');
      
      for (var entry in _unsavedChanges.entries) {
        final houseId = entry.key;
        final status = entry.value;
        final docId = _generateDocId(houseId);

        final meta = _skeleton.firstWhere((item) => item['house'] == houseId);

        batch.set(collection.doc(docId), {
          'status': status,
          'workerId': widget.workerId,
          'houseId': houseId,
          'houseOwnerName': meta['name'],
          'wardNumber': meta['ward'],
          'address': meta['addr'],
          'date': Timestamp.fromDate(_normalizedDate), // Normalized date
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pickup updates saved successfully'), backgroundColor: Colors.green),
        );
        setState(() {
          _unsavedChanges.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error saving changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pickups Schedule')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final startOfDay = _normalizedDate;
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pickups Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              DateFormat('EEEE, MMM d, yyyy').format(widget.selectedDate),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('pickup_status')
            .where('workerId', isEqualTo: widget.workerId)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('date', isLessThan: Timestamp.fromDate(endOfDay))
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('PickupListScreen Stream Error: ${snapshot.error}');
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final Map<String, String> firestoreStatuses = {};
          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data();
              final houseId = data['houseId'] as String?;
              final status = data['status'] as String?;
              if (houseId != null && status != null) {
                firestoreStatuses[houseId] = status;
              }
            }
          }

          final List<PickupModel> pickups = _skeleton.map((item) {
            final houseId = item['house']!;
            String status = 'pending';
            if (_unsavedChanges.containsKey(houseId)) {
              status = _unsavedChanges[houseId]!;
            } else if (firestoreStatuses.containsKey(houseId)) {
              status = firestoreStatuses[houseId]!;
            }

            return PickupModel(
              pickupId: _generateDocId(houseId),
              routeId: 'vazhathope_route',
              workerId: widget.workerId,
              citizenId: 'cz_${houseId}',
              scheduledDate: widget.selectedDate,
              status: status,
              updatedAt: DateTime.now(),
              location: item['addr'],
              wardNumber: item['ward'],
              houseOwnerName: item['name'],
              houseId: houseId,
            );
          }).toList();

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                itemCount: pickups.length,
                itemBuilder: (context, index) {
                  final p = pickups[index];
                  final status = p.status.toLowerCase();
                  final isCompleted = status == 'completed';
                  final isMissed = status == 'missed';
                  final isLast = index == pickups.length - 1;
                  final isUnsaved = p.houseId != null && _unsavedChanges.containsKey(p.houseId);

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 40,
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => _showStatusUpdateOptions(p),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCompleted
                                        ? Colors.green
                                        : isMissed
                                            ? Colors.red
                                            : Colors.white,
                                    border: Border.all(
                                      color: isMissed ? Colors.red : Colors.green,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: (isCompleted || isMissed)
                                      ? Icon(
                                          isCompleted ? Icons.check : Icons.close,
                                          size: 18,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: Colors.green.shade200,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.houseOwnerName ?? "Unknown Owner",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1B261B),
                                        ),
                                      ),
                                    ),
                                    if (isUnsaved)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "Unsaved",
                                          style: TextStyle(fontSize: 10, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "House ${p.houseId ?? 'N/A'} • ${p.wardNumber ?? 'N/A'}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        p.location ?? "No address provided",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isCompleted 
                                    ? "Status: Completed" 
                                    : isMissed 
                                      ? "Status: Missed" 
                                      : "Status: Pending Pickup",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted 
                                      ? Colors.green 
                                      : isMissed 
                                        ? Colors.red 
                                        : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (_unsavedChanges.isNotEmpty)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _showSaveConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Save All Updates",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
