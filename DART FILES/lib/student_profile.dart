import 'package:flutter/material.dart';

class StudentProfile extends StatelessWidget {
  const StudentProfile({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Student Dashboard"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Row(
        children: [
          Container(
            width: 250,
            color: Colors.indigo.shade900,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/student.jpg'),
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    'AKASH B C\nRoll No: 1CR22AD006',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Divider(color: Colors.white70),
                sidebarTile(Icons.dashboard, "Dashboard"),
                sidebarTile(Icons.person, "Profile"),
                sidebarTile(Icons.schedule, "Time Table"),
                sidebarTile(Icons.book, "Subjects"),
                sidebarTile(Icons.assignment, "Assignments"),
                sidebarTile(Icons.task, "Tasks"),
                sidebarTile(Icons.notifications, "Notices"),
                sidebarTile(Icons.message, "Messages"),
                sidebarTile(Icons.settings, "Settings"),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dashboard", style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      metricBox("Attendance", "78.28%", Colors.orange),
                      metricBox("Subjects", "6", Colors.blue),
                      metricBox("Assignments Due", "4", Colors.red),
                      metricBox("Tasks", "5", Colors.green),
                      metricBox("Messages", "3", Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text("Today's Schedule", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  scheduleBox("08:00 AM - 10:00 AM", "ML Lab"),
                  scheduleBox("10:20 AM - 11:20 AM", "ML"),
                  scheduleBox("11:20 AM - 12:20 PM", "NLP"),
                  scheduleBox("01:00 PM - 02:00 PM", "REPP"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sidebarTile(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: TextStyle(color: Colors.white)),
      onTap: () {},
    );
  }

  Widget metricBox(String title, String value, Color color) {
    return Container(
      width: 140,
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
          Spacer(),
          Text(title, style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget scheduleBox(String time, String subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Text(time, style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Text(subject),
        ],
      ),
    );
  }
}
