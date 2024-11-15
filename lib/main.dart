import 'package:flutter/material.dart';
import 'package:hitup_chat/pages/loading.dart';
import 'package:hitup_chat/pages/login.dart';
import 'package:firebase_database/firebase_database.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:hitup_chat/pages/profile.dart';
import 'package:hitup_chat/firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// flutter run --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
void main()async {
   WidgetsFlutterBinding.ensureInitialized();
 await dotenv.load();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase initialization error: $e");
    return; 
  }
  runApp(MaterialApp(
    theme: ThemeData(
        primaryColor: Colors.pink,
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.pink),  // Focused border color
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.pink),  // Inactive border color
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),  // Default text color
        ),
      ),
    debugShowCheckedModeBanner: false,
    initialRoute: '/',
    routes: {
    '/':(context)=>Loading(),
    '/login' : (context)=>Login(),
     }
  ));
}

