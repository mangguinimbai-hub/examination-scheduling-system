import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardLayout extends StatelessWidget {
  final String title;
  final String roleText;
  final List<Widget> children;

  const DashboardLayout({
    super.key,
    required this.title,
    required this.roleText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.school, size: 80, color: Colors.blue),
          const SizedBox(height: 15),
          Text(
            roleText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (user?.email != null) ...[
            const SizedBox(height: 5),
            Text(
              user!.email!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
          const SizedBox(height: 25),
          ...children,
        ],
      ),
    );
  }
}