import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/dashboard_button.dart';
import '../widgets/dashboard_layout.dart';
import 'view_schedules_screen.dart';
import 'view_announcements_screen.dart';

class FacultyDashboard extends StatelessWidget {
  const FacultyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Faculty Dashboard',
      roleText: 'Welcome, Faculty',
      children: [
        DashboardButton(
          icon: Icons.list_alt,
          label: 'View Exam Schedules',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ViewSchedulesScreen(),
              ),
            );
          },
        ),

        DashboardButton(
          icon: Icons.campaign,
          label: 'View Announcements',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ViewAnnouncementsScreen(),
              ),
            );
          },
        ),

        DashboardButton(
          icon: Icons.logout,
          label: 'Logout',
          onTap: () async {
            await FirebaseAuth.instance.signOut();
          },
        ),
      ],
    );
  }
}