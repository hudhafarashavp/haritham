import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'widgets/app_theme.dart';
import 'widgets/custom_widgets.dart';

class CreateComplaintScreen extends StatefulWidget {
  const CreateComplaintScreen({super.key});

  @override
  State<CreateComplaintScreen> createState() => _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends State<CreateComplaintScreen> {
  final _formKey = GlobalKey<FormState>();

  final descriptionController = TextEditingController();
  final photoUrlController = TextEditingController();
  final locationController = TextEditingController();
  final phoneController = TextEditingController(); // ✅ NEW

  String? issueType;
  bool loading = false;

  final issues = [
    "Missed Collection",
    "Overflowing Bin",
    "Illegal Dumping",
    "Burning Waste",
    "Blocked Drain",
    "Other",
  ];

  Future<void> submit() async {
    if (!_formKey.currentState!.validate() || issueType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all required fields")));
      return;
    }

    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final hksUsername = prefs.getString('hksUsername');

    if (hksUsername == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("HKS not logged")));
      setState(() => loading = false);
      return;
    }

    await FirebaseFirestore.instance.collection("hks_complaints").add({
      "hksUsername": hksUsername,
      "issueType": issueType,
      "location": locationController.text.trim(),
      "description": descriptionController.text.trim(),
      "photoUrl": photoUrlController.text.trim(),
      "contactNumber": phoneController.text.trim(), // ✅ SAVED
      "createdAt": Timestamp.now(),
      "status": "pending",
    });

    setState(() => loading = false);
    Navigator.pop(context);
  }

  InputDecoration input(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6F3),
      appBar: AppBar(
        title: const Text("Submit Complaint"),
        backgroundColor: Colors.green,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HarithamCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    section("Issue Type"),
                    DropdownButtonFormField(
                      value: issueType,
                      decoration: input("Select issue"),
                      items: issues
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => issueType = v.toString()),
                      validator: (v) => v == null ? "Select issue" : null,
                    ),
                    const SizedBox(height: 18),
                    section("Location"),
                    TextFormField(
                      controller: locationController,
                      decoration: input("Ward / Street / Area"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Enter location" : null,
                    ),
                    const SizedBox(height: 18),
                    section("Description"),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: input("Explain the problem clearly"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Enter description" : null,
                    ),
                    const SizedBox(height: 18),
                    section("Photo URL (optional)"),
                    TextField(
                      controller: photoUrlController,
                      decoration: input("Paste image link"),
                    ),
                    const SizedBox(height: 18),
                    section("Contact Number"),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: input("10 digit mobile number"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter phone number";
                        }
                        if (value.length != 10) {
                          return "Phone must be 10 digits";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              HarithamButton(
                label: loading ? "SUBMITTING..." : "SUBMIT COMPLAINT",
                onPressed: loading ? null : submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
