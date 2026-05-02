import 'package:flutter/material.dart';
import '../models/teacher_model.dart';

class TeacherReportsPage extends StatefulWidget {
  final Teacher? teacher;

  const TeacherReportsPage({super.key, this.teacher});

  @override
  State<TeacherReportsPage> createState() => _TeacherReportsPageState();
}

class _TeacherReportsPageState extends State<TeacherReportsPage> {
  String _selectedPeriod = 'This Month';
  String _selectedClass = 'All Classes';
  
  final List<String> _periods = ['This Week', 'This Month', 'This Semester', 'This Year'];
  
  // Sample data - In real app, this would come from database
  final Map<String, dynamic> _reportData = {
    'totalClasses': 45,
    'classesHeld': 42,
    'averageAttendance': 87.5,
    'totalStudents': 180,
    'presentToday': 156,
    'absentToday': 24,
    'attendanceTrend': [85, 88, 82, 90, 87, 89, 86],
    'classWiseAttendance': {
      'AI & DS A': 89.2,
      'AI & DS B': 85.8,
      'AI & DS C': 87.1,
    },
    'topPerformers': [
      {'name': 'John Doe', 'rollNo': '1CR22AD001', 'attendance': 98.5},
      {'name': 'Jane Smith', 'rollNo': '1CR22AD002', 'attendance': 96.8},
      {'name': 'Bob Johnson', 'rollNo': '1CR22AD003', 'attendance': 95.2},
    ],
    'lowAttendance': [
      {'name': 'Alice Brown', 'rollNo': '1CR22AD045', 'attendance': 65.2},
      {'name': 'Charlie Wilson', 'rollNo': '1CR22AD046', 'attendance': 68.8},
      {'name': 'David Lee', 'rollNo': '1CR22AD047', 'attendance': 72.1},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.teacher == null
          ? const Center(child: Text('No teacher data available'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with filters
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // Summary Cards
                  _buildSummaryCards(),
                  const SizedBox(height: 20),

                  // Attendance Chart
                  _buildAttendanceChart(),
                  const SizedBox(height: 20),

                  // Class-wise Performance
                  _buildClassWisePerformance(),
                  const SizedBox(height: 20),

                  // Top Performers
                  _buildTopPerformers(),
                  const SizedBox(height: 20),

                  // Low Attendance Students
                  _buildLowAttendanceStudents(),
                  const SizedBox(height: 20),

                  // Export Options
                  _buildExportOptions(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.indigo, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Attendance Reports',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(
                      labelText: 'Time Period',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _periods.map((period) => DropdownMenuItem(
                      value: period,
                      child: Text(period),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'All Classes', child: Text('All Classes')),
                      ...?widget.teacher?.classes.map((className) => DropdownMenuItem(
                        value: className,
                        child: Text(className),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedClass = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildSummaryCard(
          'Classes Held',
          '${_reportData['classesHeld']}/${_reportData['totalClasses']}',
          Icons.class_,
          Colors.blue,
          '${((_reportData['classesHeld'] / _reportData['totalClasses']) * 100).toStringAsFixed(1)}%',
        ),
        _buildSummaryCard(
          'Avg. Attendance',
          '${_reportData['averageAttendance']}%',
          Icons.trending_up,
          Colors.green,
          'Good',
        ),
        _buildSummaryCard(
          'Present Today',
          '${_reportData['presentToday']}',
          Icons.check_circle,
          Colors.orange,
          '${_reportData['totalStudents']} total',
        ),
        _buildSummaryCard(
          'Absent Today',
          '${_reportData['absentToday']}',
          Icons.cancel,
          Colors.red,
          '${(((_reportData['absentToday'] / _reportData['totalStudents']) * 100)).toStringAsFixed(1)}%',
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Trend (Last 7 Days)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final attendance = _reportData['attendanceTrend'][index];
                  final height = (attendance / 100) * 150;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$attendance%',
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 30,
                        height: height,
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index],
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassWisePerformance() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Class-wise Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(_reportData['classWiseAttendance'] as Map<String, dynamic>).entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: entry.value / 100,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          entry.value >= 85 ? Colors.green : 
                          entry.value >= 75 ? Colors.orange : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPerformers() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Top Performers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_reportData['topPerformers'] as List).asMap().entries.map(
              (entry) {
                final index = entry.key;
                final student = entry.value;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: [Colors.amber, Colors.grey, Colors.brown][index],
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(student['name']),
                  subtitle: Text(student['rollNo']),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${student['attendance']}%',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLowAttendanceStudents() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Students Needing Attention',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_reportData['lowAttendance'] as List).map(
              (student) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  child: Icon(Icons.person, color: Colors.red),
                ),
                title: Text(student['name']),
                subtitle: Text(student['rollNo']),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${student['attendance']}%',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () {
                  // TODO: Show detailed student attendance
                },
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Export to PDF
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PDF export feature coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Export to Excel
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Excel export feature coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Export Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      foregroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Share report
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share feature coming soon!')),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.withOpacity(0.1),
                  foregroundColor: Colors.indigo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}