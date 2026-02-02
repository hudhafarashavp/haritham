import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateNotificationScreen extends StatefulWidget {
  final String? docId;
  final String? oldTitle;
  final String? oldMessage;
  final String? oldTarget;

  // constructor (used for both create & edit)
  CreateNotificationScreen({
    super.key,
    this.docId,
    this.oldTitle,
    this.oldMessage,
    this.oldTarget,
  });

  @override
  State<CreateNotificationScreen> createState() =>
      _CreateNotificationScreenState();
}

class _CreateNotificationScreenState
    extends State<CreateNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  String target = 'citizen';
  String role = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadRole();

    // if this screen is opened for editing, pre-fill existing values
    if (widget.docId != null) {
      titleController.text = widget.oldTitle ?? '';
      messageController.text = widget.oldMessage ?? '';
      target = widget.oldTarget ?? 'citizen';
    }
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    role = prefs.getString('role') ?? '';

    // HKS users are restricted to sending notifications only to citizens
    if (role == 'hks') {
      setState(() {
        target = 'citizen';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final baseData = {
      'title': titleController.text.trim(),
      'message': messageController.text.trim(),
      'target': target,
      'createdBy': role,
    };

    // create a new notification
    if (widget.docId == null) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        ...baseData,
        'createdAt': Timestamp.now(),
        'viewedBy': {
          'citizen': false,
          'hks': false,
        },
      });
    }
    // update an existing notification
    else {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(widget.docId)
          .update(baseData);
    }

    setState(() => loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text('Create Notification'),
        backgroundColor: const Color(0xFFE8F5E9),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: messageController,
                decoration: const InputDecoration(labelText: 'Message'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // target selection is disabled for HKS users
              if (role != 'hks')
                DropdownButtonFormField<String>(
                  value: target,
                  items: const [
                    DropdownMenuItem(
                        value: 'citizen', child: Text('Citizen')),
                    DropdownMenuItem(
                        value: 'hks', child: Text('HKS')),
                    DropdownMenuItem(
                        value: 'all', child: Text('All')),
                  ],
                  onChanged: (v) => setState(() => target = v!),
                  decoration:
                  const InputDecoration(labelText: 'Target'),
                )
              else
                TextFormField(
                  initialValue: 'Citizen',
                  enabled: false,
                  decoration:
                  const InputDecoration(labelText: 'Target'),
                ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('SAVE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
