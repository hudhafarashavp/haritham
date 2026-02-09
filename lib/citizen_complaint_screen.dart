import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CitizenComplaintScreen extends StatefulWidget {
  const CitizenComplaintScreen({super.key});

  @override
  State<CitizenComplaintScreen> createState() => _CitizenComplaintScreenState();
}

class _CitizenComplaintScreenState extends State<CitizenComplaintScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController proofUrlController = TextEditingController();
  final TextEditingController hksWorkerController = TextEditingController();
  final TextEditingController wardController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  String? selectedIssueType;
  bool loading = false;

  final List<String> issueTypes = [
    "Illegal dumping",
    "Missed waste collection",
    "Overflowing bin",
    "Burning waste",
    "Plastic waste",
    "Other",
  ];

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      final citizenEmail = user?.email ?? '';
      final citizenUid = user?.uid ?? '';

      final proofUrl = proofUrlController.text.trim();

      await FirebaseFirestore.instance.collection("complaints").add({
        "citizenEmail": citizenEmail,
        "citizenUid": citizenUid,
        "issueType": selectedIssueType,
        "description": descriptionController.text.trim(),
        "proofUrl": proofUrl.isEmpty ? null : proofUrl,
        "hksWorkerName": hksWorkerController.text.trim(),
        "wardNo": wardController.text.trim(),
        "contactNo": contactController.text.trim(),
        "createdAt": Timestamp.now(),
        "status": "pending",
      });

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Complaint Submitted ✅"),
          content: const Text("Your complaint has been submitted successfully."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );

      setState(() {
        selectedIssueType = null;
        descriptionController.clear();
        proofUrlController.clear();
        hksWorkerController.clear();
        wardController.clear();
        contactController.clear();
      });
    } catch (e) {
      _show("Failed: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    descriptionController.dispose();
    proofUrlController.dispose();
    hksWorkerController.dispose();
    wardController.dispose();
    contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text("Submit Complaint"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: selectedIssueType,
                decoration: const InputDecoration(
                  labelText: "Type of Issue",
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: issueTypes
                    .map((issue) => DropdownMenuItem(
                  value: issue,
                  child: Text(issue),
                ))
                    .toList(),
                onChanged: (value) => setState(() => selectedIssueType = value),
                validator: (value) =>
                value == null ? "Please select issue type" : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: "Description",
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: proofUrlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: "Proof URL (Optional)",
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  if (!_isValidUrl(value)) return "Invalid URL";
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: hksWorkerController,
                decoration: const InputDecoration(
                  labelText: "HKS Worker Name (Optional)",
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: wardController,
                decoration: const InputDecoration(
                  labelText: "Ward No",
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) =>
                v == null || v.isEmpty ? "Ward required" : null,
              ),

              const SizedBox(height: 16),

              // ✅ FIXED 10 DIGIT VALIDATION
              TextFormField(
                controller: contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Contact Number",
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Contact required";
                  }

                  final phone = v.trim();

                  if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
                    return "Enter valid 10 digit mobile number";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: loading ? null : _submitComplaint,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Complaint"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
