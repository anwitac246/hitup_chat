import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hitup_chat/pages/gemini_api.dart';
import 'package:hitup_chat/pages/profile.dart';
import 'package:intl/intl.dart';
import 'package:parallax_rain/parallax_rain.dart';
import 'package:vitality/vitality.dart';


class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final databaseRef = FirebaseDatabase.instance.ref();

  User? _currentUser;
  String _searchQuery = '';
  DatabaseReference? _selectedUserRef;
  Map<String, dynamic>? _selectedUserData; 

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
  }

  Future<void> _selectUser(DatabaseReference userRef) async {
    final snapshot = await userRef.get();
    if (snapshot.exists) {
      setState(() {
        _selectedUserRef = userRef;
        _selectedUserData = Map<String, dynamic>.from(snapshot.value as Map);
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedUserRef == null) return;

    final messageData = {
      'senderId': _currentUser?.uid,
      'receiverId': _selectedUserRef?.key,
      'message': _messageController.text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    await databaseRef.child('chats').push().set(messageData);
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
            child: _selectedUserRef == null
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
            child: _selectedUserRef == null
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
    final usersRef = databaseRef.child('users');
    return StreamBuilder<DatabaseEvent>(
      stream: usersRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return Center(
            child: Text(
              'No users found.',
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }

        final usersData = snapshot.data!.snapshot.value as Map? ?? {};
        final users = usersData.entries.where((userEntry) {
          final user = userEntry.value;
          final matchesSearchQuery =
              _searchQuery.isEmpty || (user['username'] ?? '').toLowerCase().contains(_searchQuery);
          return matchesSearchQuery;
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
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.value['profilePicture'] != null
                    ? NetworkImage(user.value['profilePicture'])
                    : null,
                backgroundColor: Colors.pink,
              ),
              title: Text(
                user.value['username'] ?? 'Unknown User',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () => _selectUser(usersRef.child(user.key)),
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: _selectedUserData?['profilePicture'] != null
                        ? NetworkImage(_selectedUserData!['profilePicture'])
                        : null,
                    backgroundColor: Colors.pink,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedUserData?['username'] ?? 'Unknown User',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: databaseRef.child('chats').orderByChild('timestamp').onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messagesData = snapshot.data!.snapshot.value as Map? ?? {};
                  final messages = messagesData.entries.where((entry) {
                    final message = entry.value;
                    return (message['senderId'] == _currentUser?.uid && message['receiverId'] == _selectedUserRef?.key) ||
                        (message['senderId'] == _selectedUserRef?.key && message['receiverId'] == _currentUser?.uid);
                  }).toList();

                  messages.sort((a, b) => DateTime.parse(b.value['timestamp']).compareTo(DateTime.parse(a.value['timestamp'])));

                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - index - 1].value;
                      final isSentByMe = message['senderId'] == _currentUser?.uid;
                      final timestamp = DateTime.parse(message['timestamp']);
                      final formattedTime = DateFormat('hh:mm a').format(timestamp);

                      return Row(
                        mainAxisAlignment: isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isSentByMe)
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: _selectedUserData?['profilePicture'] != null
                                  ? NetworkImage(_selectedUserData!['profilePicture'])
                                  : null,
                              backgroundColor: Colors.pink,
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            decoration: BoxDecoration(
                              color: isSentByMe ? Colors.pink : Colors.grey[700],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: isSentByMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['message'] ?? '',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedTime,
                                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                                ),
                              ],
                            ),
                          ),
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
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.pink),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    if (_selectedUserData == null) {
      return const Center(
        child: Text(
          'Select a user to view profile',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final bio = _selectedUserData?['bio'] ?? 'No bio available';
    final username = _selectedUserData?['username'] ?? 'Unknown User';
    final profilePicture = _selectedUserData?['profilePicture'];

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: profilePicture != null ? NetworkImage(profilePicture) : null,
          backgroundColor: Colors.pink,
        ),
        const SizedBox(height: 8),
        Text(
          username,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        const SizedBox(height: 8),
        Text(
          bio,
          style: const TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
