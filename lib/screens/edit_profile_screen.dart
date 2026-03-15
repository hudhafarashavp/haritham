import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/app_theme.dart';
import '../widgets/custom_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  final String role;
  const EditProfileScreen({super.key, required this.role});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _workerIdController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _profileImageUrl;
  File? _imageFile;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final collection = widget.role == 'citizen' ? 'users' : 'workers';
      final doc = await _firestore.collection(collection).doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _addressController.text = data['address'] ?? '';
        _profileImageUrl = data['profileImageUrl'];

        if (widget.role == 'citizen') {
          _usernameController.text = data['username'] ?? '';
        } else {
          _workerIdController.text = data['workerId'] ?? data['worker_id'] ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageFile == null) return _profileImageUrl;

    try {
      final ref = _storage.ref().child('profile_photos').child('$uid.jpg');
      await ref.putFile(_imageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<bool> _isUsernameUnique(String username, String currentUid) async {
    if (widget.role != 'citizen') return true;
    
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    if (query.docs.isEmpty) return true;
    
    // Check if the only person with this username is the current user
    return query.docs.every((doc) => doc.id == currentUid);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final currentUid = user.uid;
      
      // 1. Check unique username if citizen
      if (widget.role == 'citizen') {
        final isUnique = await _isUsernameUnique(_usernameController.text.trim(), currentUid);
        if (!isUnique) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Username already taken. Please choose another.')),
            );
          }
          setState(() => _isSaving = false);
          return;
        }
      }

      // 2. Upload image if changed
      final newImageUrl = await _uploadImage(currentUid);

      // 3. Update Firestore
      final collection = widget.role == 'citizen' ? 'users' : 'workers';
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'profileImageUrl': newImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.role == 'citizen') {
        updateData['username'] = _usernameController.text.trim();
      } else {
        updateData['workerId'] = _workerIdController.text.trim();
      }

      await _firestore.collection(collection).doc(currentUid).update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.harithamGreen)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.padding),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Photo
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppTheme.softGrey,
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null) as ImageProvider?,
                            child: _imageFile == null && _profileImageUrl == null
                                ? const Icon(Icons.person, size: 60, color: AppTheme.textGrey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: AppTheme.harithamGreen,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    HarithamTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    
                    if (widget.role == 'citizen')
                      HarithamTextField(
                        label: 'Username',
                        controller: _usernameController,
                        prefixIcon: Icons.alternate_email,
                      ),
                    
                    if (widget.role != 'citizen')
                      HarithamTextField(
                        label: 'Worker ID',
                        controller: _workerIdController,
                        prefixIcon: Icons.badge_outlined,
                      ),
                    
                    const SizedBox(height: 16),
                    HarithamTextField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      prefixIcon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 16),
                    HarithamTextField(
                      label: 'Address',
                      controller: _addressController,
                      prefixIcon: Icons.home_outlined,
                    ),
                    
                    const SizedBox(height: 40),
                    const Text(
                      'Account details are securely stored. Name and Worker/Citizen ID are visible to administrators.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
