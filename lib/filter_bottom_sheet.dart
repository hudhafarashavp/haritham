import 'package:flutter/material.dart';

class FilterBottomSheet extends StatefulWidget {
  final String selectedStatus;
  final DateTime? selectedDate;
  final Function(String, DateTime?) onApply;

  const FilterBottomSheet({
    super.key,
    required this.selectedStatus,
    required this.selectedDate,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String status;
  DateTime? date;

  @override
  void initState() {
    status = widget.selectedStatus;
    date = widget.selectedDate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          const Text("Filters", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          const SizedBox(height: 12),

          DropdownButtonFormField(
            value: status,
            items: const [
              DropdownMenuItem(value: "all", child: Text("All")),
              DropdownMenuItem(value: "pending", child: Text("Pending")),
              DropdownMenuItem(value: "in progress", child: Text("In Progress")),
              DropdownMenuItem(value: "resolved", child: Text("Resolved")),
            ],
            onChanged: (v) => setState(() => status = v.toString()),
            decoration: const InputDecoration(labelText: "Status"),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => date = picked);
            },
            child: Text(date == null
                ? "Select Date"
                : "${date!.day}-${date!.month}-${date!.year}"),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(status, date);
                Navigator.pop(context);
              },
              child: const Text("Apply Filters"),
            ),
          ),
        ],
      ),
    );
  }
}
