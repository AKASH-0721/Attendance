import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final String userType;

  const Sidebar({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.blue.shade900, // Deep blue background
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Profile Section
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade900),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 50, color: Colors.blue),
              ),
              accountName: const Text(
                "AKASH B C",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: const Text(
                "Roll No: 1CR22AD006",
                style: TextStyle(fontSize: 14),
              ),
            ),

            // Menu Items
            _drawerItem(Icons.dashboard, "Dashboard", context),
            _drawerItem(Icons.person, "Profile", context),
            _drawerItem(Icons.schedule, "Time Table", context),
            _drawerItem(Icons.book, "Subjects", context),
            _drawerItem(Icons.assignment, "Assignments", context),
            _drawerItem(Icons.task, "Tasks", context),
            _drawerItem(Icons.notifications, "Notices", context),
            _drawerItem(Icons.message, "Messages", context),
            _drawerItem(Icons.settings, "Settings", context),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context); // Close drawer when tapped
        // TODO: Navigate to respective page
      },
    );
  }
}
