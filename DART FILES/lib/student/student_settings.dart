import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/auth_service.dart';

class StudentSettingsPage extends StatefulWidget {
  final Student? student;

  const StudentSettingsPage({super.key, this.student});

  @override
  State<StudentSettingsPage> createState() => _StudentSettingsPageState();
}

class _StudentSettingsPageState extends State<StudentSettingsPage> {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _attendanceReminders = true;
  bool _assignmentReminders = true;
  String _language = 'English';
  String _theme = 'System';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          if (widget.student != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.indigo,
                      backgroundImage: widget.student!.photo.isNotEmpty
                          ? NetworkImage(widget.student!.photo)
                          : null,
                      child: widget.student!.photo.isEmpty
                          ? const Icon(Icons.person, size: 40, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.student!.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Roll No: ${widget.student!.rollNumber}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '${widget.student!.department} - ${widget.student!.year}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      widget.student!.email,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Notifications Section
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Receive app notifications'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive notifications via email'),
                  value: _emailNotifications,
                  onChanged: _notificationsEnabled ? (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  } : null,
                ),
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive push notifications on device'),
                  value: _pushNotifications,
                  onChanged: _notificationsEnabled ? (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  } : null,
                ),
                SwitchListTile(
                  title: const Text('Attendance Reminders'),
                  subtitle: const Text('Get reminded about attendance'),
                  value: _attendanceReminders,
                  onChanged: _notificationsEnabled ? (value) {
                    setState(() {
                      _attendanceReminders = value;
                    });
                  } : null,
                ),
                SwitchListTile(
                  title: const Text('Assignment Reminders'),
                  subtitle: const Text('Get reminded about due assignments'),
                  value: _assignmentReminders,
                  onChanged: _notificationsEnabled ? (value) {
                    setState(() {
                      _assignmentReminders = value;
                    });
                  } : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Academic Preferences
          const Text(
            'Academic Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Default View'),
                  subtitle: const Text('Overview'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showDefaultViewDialog();
                  },
                ),
                ListTile(
                  title: const Text('Attendance Goal'),
                  subtitle: const Text('85%'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showAttendanceGoalDialog();
                  },
                ),
                ListTile(
                  title: const Text('Grade Display'),
                  subtitle: const Text('Percentage'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showGradeDisplayDialog();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // App Preferences
          const Text(
            'App Preferences',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Language'),
                  subtitle: Text(_language),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showLanguageDialog();
                  },
                ),
                ListTile(
                  title: const Text('Theme'),
                  subtitle: Text(_theme),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showThemeDialog();
                  },
                ),
                ListTile(
                  title: const Text('Data Usage'),
                  subtitle: const Text('Optimize for mobile data'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Show data usage settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data usage settings coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Privacy & Security
          const Text(
            'Privacy & Security',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Implement change password
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change password feature coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Show privacy policy
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy policy coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Data & Privacy'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Show data privacy settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data privacy settings coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Support & About
          const Text(
            'Support & About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Show help page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help page coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.feedback),
                  title: const Text('Send Feedback'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Show feedback form
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Feedback form coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('About'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    _showSignOutDialog();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Hindi', 'Kannada'].map((lang) => RadioListTile<String>(
            title: Text(lang),
            value: lang,
            groupValue: _language,
            onChanged: (value) {
              setState(() {
                _language = value!;
              });
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['System', 'Light', 'Dark'].map((theme) => RadioListTile<String>(
            title: Text(theme),
            value: theme,
            groupValue: _theme,
            onChanged: (value) {
              setState(() {
                _theme = value!;
              });
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showDefaultViewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default View'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Overview', 'Attendance', 'Schedule', 'Assignments'].map((view) => 
            ListTile(
              title: Text(view),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Default view set to $view')),
                );
              },
            )
          ).toList(),
        ),
      ),
    );
  }

  void _showAttendanceGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Attendance Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['75%', '80%', '85%', '90%', '95%'].map((goal) => 
            ListTile(
              title: Text(goal),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Attendance goal set to $goal')),
                );
              },
            )
          ).toList(),
        ),
      ),
    );
  }

  void _showGradeDisplayDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grade Display'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Percentage', 'GPA', 'Letter Grade'].map((display) => 
            ListTile(
              title: Text(display),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Grade display set to $display')),
                );
              },
            )
          ).toList(),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Student Portal',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.school, size: 48),
      children: [
        const Text('A comprehensive student management system for tracking attendance, assignments, and academic performance.'),
      ],
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to sign out: ${e.toString()}')),
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}