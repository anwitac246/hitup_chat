import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:hitup_chat/pages/chat.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hitup_chat/firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hitup_chat/pages/profile.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _checkUserProfile(User user) async {
    final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      await userRef.set({
        'name': '',
        'username': '',
        'bio': '',
        'dob': '',
        'profilePicture': '',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error initializing Firebase: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (authSnapshot.hasError) {
              return Center(
                child: Text(
                  'Auth error: ${authSnapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (!authSnapshot.hasData) {
              return SignInScreen(
                providers: [
                  EmailAuthProvider(),
                ],
                headerBuilder: (context, constraints, shrinkOffset) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.asset('assets/images/hituplogo.png'),
                    ),
                  );
                },
                subtitleBuilder: (context, action) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: action == AuthAction.signIn
                        ? const Text('Welcome to HitUp Chat, please sign in!')
                        : const Text('Welcome to HitUp Chat, please sign up!'),
                  );
                },
                footerBuilder: (context, action) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'By signing in, you agree to our terms and conditions.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                },
                sideBuilder: (context, shrinkOffset) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image.asset('assets/images/hituplogo.png'),
                    ),
                  );
                },
              );
            }

            final user = authSnapshot.data!;
            return FutureBuilder(
              future: _checkUserProfile(user),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
                return FutureBuilder<DatabaseEvent>(
                  future: userRef.once(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (userSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading user data: ${userSnapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (userSnapshot.hasData && userSnapshot.data!.snapshot.exists) {
                      final data = userSnapshot.data!.snapshot.value;
                      if (data != null && data is Map) {
                        final name = data['name'] as String? ?? '';
                        final username = data['username'] as String? ?? '';

                        if (name.isEmpty || username.isEmpty) {
                          return const Profile();
                        }
                      } else {
                        return const Center(
                          child: Text(
                            'Unexpected user data format.',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }
                    }

                    return const Chat();
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
