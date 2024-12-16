import 'package:flutter/material.dart';
import 'package:hitup_chat/pages/chat.dart';
import 'package:particles_flutter/component/particle/particle.dart';
import 'package:particles_flutter/core/runner.dart';
import 'package:particles_flutter/painters/circular_painter.dart';
import 'package:particles_flutter/particles_engine.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'auth_gate.dart';

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Login(),
    );
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: CircularParticleScreen(),
        ),
      ),
    );
  }
}

class CircularParticleScreen extends StatelessWidget {
  const CircularParticleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Container(
          color: Colors.black,
          child: Particles(
            awayRadius: 200,
            particles: createParticles(),
            height: screenHeight,
            width: screenWidth,
            onTapAnimation: true,
            awayAnimationDuration: const Duration(milliseconds: 100),
            awayAnimationCurve: Curves.linear,
            enableHover: true,
            hoverRadius: 90,
            connectDots: true,
          ),
        ),
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'HitUp',
                style: TextStyle(
                  fontSize: 200,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                label: Text(
                  'Login',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding: const EdgeInsets.fromLTRB(50.0, 20.0, 50.0, 20.0),
                  side: const BorderSide(color: Color.fromARGB(255, 172, 7, 62), width: 2), // Border color and width
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  try {
                    
                    print("Navigating to AuthGate...");
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthGate()),
                    );
                  } catch (e) {
                    print('Login error: $e');
                    
                  }
                },
                icon: const Icon(Icons.login, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Particle> createParticles() {
    var rng = Random();
    List<Particle> particles = [];
    for (int i = 0; i < 140; i++) {
      particles.add(Particle(
        color: Colors.pink.withOpacity(0.6),
        size: rng.nextDouble() * 10,
        velocity: Offset(
          rng.nextDouble() * 200 * randomSign(),
          rng.nextDouble() * 200 * randomSign(),
        ),
      ));
    }
    return particles;
  }

  double randomSign() {
    var rng = Random();
    return rng.nextBool() ? 1 : -1;
  }
}
