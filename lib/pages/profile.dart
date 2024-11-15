import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  DateTime? _dob;
  File? _profileImage;
  String? _profileImageUrl;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
      final snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        // Safely cast the data from LinkedMap to Map<String, dynamic> with null checks
        final data = snapshot.value as Map<Object?, Object?>?;

        if (data != null) {
          final Map<String, dynamic> castedData = Map<String, dynamic>.fromEntries(
            data.entries.map((entry) {
              return MapEntry(entry.key?.toString() ?? '', entry.value ?? '');
            }),
          );

          setState(() {
            _nameController.text = castedData['name'] ?? '';
            _usernameController.text = castedData['username'] ?? '';
            _bioController.text = castedData['bio'] ?? '';
            _profileImageUrl = castedData['profilePicture'] ?? '';
            _dob = castedData['dob'] != null ? DateTime.tryParse(castedData['dob']) : null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load profile: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImage == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${user.uid}');
      final uploadTask = storageRef.putFile(_profileImage!);
      final snapshot = await uploadTask.whenComplete(() {});
      _profileImageUrl = await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    try {
      await _uploadProfileImage();
      final DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${user.uid}');

      await userRef.set({
        'name': _nameController.text,
        'username': _usernameController.text,
        'bio': _bioController.text,
        'dob': _dob?.toIso8601String(),
        'profilePicture': _profileImageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Your Profile'), backgroundColor: Colors.pink),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 70,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                child: _profileImage == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                    ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white)
                    : null,
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              style: const TextStyle(color: Colors.pink),
              cursorColor: Colors.pink,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              style: const TextStyle(color: Colors.pink),
              cursorColor: Colors.pink,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              cursorColor: Colors.pink,
              style: const TextStyle(color: Colors.pink),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  setState(() => _dob = pickedDate);
                }
              },
              style: TextButton.styleFrom(backgroundColor: Colors.pink),
              child: Text(
                _dob == null ? 'Select Date of Birth' : 'DOB: ${_dob!.toLocal()}',
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save Profile',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            ),
          ],
        ),
      ),
    );
  }
}
