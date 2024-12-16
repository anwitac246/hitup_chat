import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;
import 'package:mime/mime.dart';
import 'dart:typed_data';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  DateTime? _dob;
  Uint8List? _profileImageBytes;
  String? _profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          _nameController.text = data['name'] ?? '';
          _usernameController.text = data['username'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _profileImageUrl = data['profilePicture'] ?? '';
          _dob = data['dob'] != null ? DateTime.tryParse(data['dob']) : null;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load profile: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final html.File? file = uploadInput.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((event) {
          if (reader.result != null) {
            final bytes = reader.result as Uint8List;
            final mimeType = lookupMimeType(file.name, headerBytes: bytes);

            if (mimeType == 'image/jpeg' || mimeType == 'image/png') {
              setState(() => _profileImageBytes = bytes);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Only JPG or PNG images are allowed.')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to read the selected file.')),
            );
          }
        });
      }
    });
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected to upload.')),
      );
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated.')),
      );
      return null;
    }

    try {
      final mimeType =
          lookupMimeType('', headerBytes: _profileImageBytes!) ?? 'image/jpeg';
      String extension = mimeType.split('/').last;

      if (extension != 'jpeg' && extension != 'png') extension = 'jpg';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profilePictures/${user.uid}.$extension');

      final uploadTask = storageRef.putData(
        _profileImageBytes!,
        SettableMetadata(contentType: mimeType),
      );

      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Image upload timed out');
        },
      );

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile image: $e')),
      );
      return null;
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

    setState(() => _isLoading = true);

    try {
      if (_profileImageBytes != null) {
        final profilePictureUrl = await _uploadProfileImage();
        if (profilePictureUrl != null) {
          _profileImageUrl = profilePictureUrl;
        }
      }

      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      await userDocRef.set({
        'name': _nameController.text,
        'username': _usernameController.text,
        'bio': _bioController.text,
        'dob': _dob?.toIso8601String(),
        'profilePicture': _profileImageUrl ?? '',
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.pink),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Your Profile'),
        backgroundColor: Colors.pink,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 70,
                  backgroundImage: _profileImageBytes != null
                      ? MemoryImage(_profileImageBytes!)
                      : _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!) as ImageProvider
                          : null,
                  child: _profileImageBytes == null &&
                          (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                      ? const Icon(Icons.add_a_photo,
                          size: 40, color: Colors.white)
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
                  _dob == null
                      ? 'Select Date of Birth'
                      : 'DOB: ${_dob!.toLocal()}',
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text(
                  'Save Profile',
                  style:
                      TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _logout(context);
                  }
                },
                child: const Text(
                  'Logout',
                  style:
                      TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
