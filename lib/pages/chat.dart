//import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hitup_chat/pages/gemini_api.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hitup_chat/pages/profile.dart';
import 'package:intl/intl.dart';
import 'package:parallax_rain/parallax_rain.dart';
import 'package:file_picker/file_picker.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  String _searchQuery = '';
  String? _selectedUserId;
  Map<String, dynamic>? _selectedUserData;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
  }

  Future<void> _selectUser(String userId, Map<String, dynamic> userData) async {
    setState(() {
      _selectedUserId = userId;
      _selectedUserData = userData;
    });
  }

  final ScrollController _scrollController =
      ScrollController(); 

  Future<void> _scrollToBottom() async {
    if (_scrollController.hasClients) {
      await Future.delayed(const Duration(
          milliseconds: 100));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedUserId == null)
      return;

    final messageData = {
      'senderId': _currentUser?.uid,
      'receiverId': _selectedUserId,
      'message': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('chats').add(messageData);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text(
          'HitUp',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            color: Colors.black,
            onSelected: (String value) {
              if (value == 'Profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Profile()),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'Profile',
                  child: Text(
                    'Profile',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(child: _buildUserList()),
              ],
            ),
          ),
          VerticalDivider(color: Colors.grey[700]),
          Expanded(
            flex: 4,
            child: _selectedUserId == null
                ? Center(
                    child: Text(
                      'Select a user to start chatting',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                : _buildChatArea(),
          ),
          VerticalDivider(color: Colors.grey[700]),
          Expanded(
            flex: 2,
            child: _selectedUserId == null
                ? Center(
                    child: Text(
                      'Select a user to view profile',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                : _buildProfileSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        style: TextStyle(color: Colors.white),
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search users...',
          prefixIcon: const Icon(Icons.search, color: Colors.pink),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.pink),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.pink),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No users found.',
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        final users = snapshot.data!.docs.where((userDoc) {
          final user = userDoc.data() as Map<String, dynamic>;
          final matchesSearchQuery = _searchQuery.isEmpty ||
              (user['username'] ?? '').toLowerCase().contains(_searchQuery);
          return matchesSearchQuery && userDoc.id != _currentUser?.uid;
        }).toList();

        if (users.isEmpty) {
          return Center(
            child: Text(
              'No users found.',
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userDoc = users[index];
            final user = userDoc.data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user['profilePicture'] != null
                    ? NetworkImage(user['profilePicture'])
                    : null,
                backgroundColor: Colors.pink,
              ),
              title: Text(
                user['username'] ?? 'Unknown User',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () => _selectUser(userDoc.id, user),
            );
          },
        );
      },
    );
  }

  Widget _buildChatArea() {
  return Stack(
    children: [
      ParallaxRain(
        dropColors: [
          Colors.pink,
          Colors.white.withOpacity(0.8),
        ],
        trail: true,
        dropFallSpeed: 5.0,
        dropWidth: 2.0,
        numberOfDrops: 100,
      ),
      Column(
        children: [
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.grey[850],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: _selectedUserData?['profilePicture'] != null
                      ? NetworkImage(_selectedUserData!['profilePicture'])
                      : null,
                  backgroundColor: Colors.pink,
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedUserData?['username'] ?? 'Unknown User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .orderBy('timestamp', descending: true) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet.',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  );
                }

               
                final groupedMessages = _groupMessagesByDate(snapshot.data!.docs);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom(); 
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: groupedMessages.length,
                  itemBuilder: (context, index) {
                    final entry = groupedMessages.entries.toList()[index];
                    final date = entry.key;
                    final messages = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(
                            child: Text(
                              DateFormat('EEEE, MMM d').format(date),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                       
                        ...messages.map((message) {
                          final messageData = message.data() as Map<String, dynamic>;
                          final isSentByMe = messageData['senderId'] == _currentUser?.uid;
                          final timestamp = messageData['timestamp']?.toDate();
                          final formattedTime = timestamp != null
                              ? DateFormat('hh:mm a').format(timestamp)
                              : '';

                          return Row(
                            mainAxisAlignment: isSentByMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!isSentByMe)
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage:
                                      _selectedUserData?['profilePicture'] != null
                                          ? NetworkImage(
                                              _selectedUserData!['profilePicture'])
                                          : null,
                                  backgroundColor: Colors.pink,
                                ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 12.0),
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                decoration: BoxDecoration(
                                  color:
                                      isSentByMe ? Colors.pink : Colors.grey[700],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: isSentByMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      messageData['message'] ?? '',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formattedTime,
                                      style: TextStyle(
                                          color: Colors.grey[400], fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.pink),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.pink),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                  IconButton(
                    icon: const Icon(Icons.circle_sharp),
                    color: Colors.pink,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) => SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: GeminiApiChat(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.attachment, color: Colors.pink),
                    onPressed: () async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    allowMultiple: true,
  );

  if (result != null && result.files.isNotEmpty) {
    final fileBytes = result.files.single.bytes;
    final fileName = result.files.single.name;
    final fileExtension = result.files.single.extension;

    print('File Name: $fileName');
    print('File Extension: $fileExtension');
    print('Bytes Length: ${fileBytes?.length}');

    if (fileBytes != null) {
      try {
        final storageRef =
            FirebaseStorage.instance.ref().child('chat_files/$fileName');
        final uploadTask = storageRef.putData(fileBytes);
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
    print('Task state: ${snapshot.state}');
    print('Bytes transferred: ${snapshot.bytesTransferred}');
  });
        final snapshot = await uploadTask.whenComplete(() {});
        final fileUrl = await snapshot.ref.getDownloadURL();

        print('File uploaded successfully: $fileUrl');

       
        await _firestore.collection('chats').add({
          'senderId': _currentUser?.uid,
          'receiverId': _selectedUserId,
          'fileUrl': fileUrl,
          'fileName': fileName,
          'fileType': fileExtension,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fileName sent successfully!')),
        );
      } catch (e) {
        print('Error during file upload: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File selection failed. Try again.')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No file selected')),
    );
  }
},

                  ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.pink),
                  onPressed: () {
                    _sendMessage();
                    _scrollToBottom();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}


Map<DateTime, List<QueryDocumentSnapshot>> _groupMessagesByDate(
    List<QueryDocumentSnapshot> messages) {
  final Map<DateTime, List<QueryDocumentSnapshot>> groupedMessages = {};

  for (final message in messages) {
    final timestamp = message['timestamp']?.toDate();
    if (timestamp == null) continue;

    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (groupedMessages[date] == null) {
      groupedMessages[date] = [];
    }
    groupedMessages[date]!.add(message);
  }

  return groupedMessages;
}

  Widget _buildProfileSection() {
    return ListView(
      padding: const EdgeInsets.all(8.0),
     
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: _selectedUserData?['profilePicture'] != null
              ? NetworkImage(_selectedUserData!['profilePicture'])
              : null,
          backgroundColor: Colors.pink,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _selectedUserData?['username'] ?? 'Unknown User',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _selectedUserData?['bio'] ?? 'No bio available.',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
