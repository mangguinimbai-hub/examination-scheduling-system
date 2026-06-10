import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'screens/post_announcement_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SmartExamSchedulerApp());
}

class SmartExamSchedulerApp extends StatelessWidget {
  const SmartExamSchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Exam Scheduler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),

      // First screen after app starts
      home: const AuthGate(),

      // App routes
      routes: {
        '/post-announcement': (context) => const PostAnnouncementScreen(),
      },
    );
  }
}