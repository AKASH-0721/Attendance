import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/attendance_service.dart';
import '../models/attendance_model.dart';

class StudentAttendancePage extends StatefulWidget {
  final Student? student;

  const StudentAttendancePage({super.key, this.student});

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['This Week', 'This Month', 'This Semester', 'This Year'];
  final AttendanceService _attendanceService = AttendanceService();
  
  AttendanceSummary? _attendanceSummary;
  List<AttendanceRecord> _recentAttendance = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    if (widget.student?.rollNumber == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Get date range based on selected period
      DateTime endDate = DateTime.now();
      DateTime startDate = _getStartDateForPeriod(endDate);

      // Load attendance summary
      _attendanceSummary = await _attendanceService.getStudentAttendanceSummary(
        studentRollNumber: widget.student!.rollNumber,
        startDate: startDate,
        endDate: endDate,
      );

      // Load recent attendance
      _recentAttendance = await _attendanceService.getRecentAttendance(
        widget.student!.rollNumber,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading attendance: ${e.toString()}')),
      );
    }
  }

  DateTime _getStartDateForPeriod(DateTime endDate) {
    switch (_selectedPeriod) {
      case 'This Week':
        return endDate.subtract(const Duration(days: 7));
      case 'This Month':
        return DateTime(endDate.year, endDate.month, 1);
      case 'This Semester':
        return endDate.subtract(const Duration(days: 120));
      case 'This Year':
        return DateTime(endDate.year, 1, 1);
      default:
        return DateTime(endDate.year, endDate.month, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with filter
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // Overall Attendance Card
                  _buildOverallAttendanceCard(),
                  const SizedBox(height: 20),

                  // Subject-wise Attendance
                  _buildSubjectWiseAttendance(),
                  const SizedBox(height: 20),

                  // Recent Attendance
                  _buildRecentAttendance(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.indigo, size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Attendance Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DropdownButton<String>(
              value: _selectedPeriod,
              items: _periods.map((period) => DropdownMenuItem(
                value: period,
                child: Text(period),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
                _loadAttendanceData(); // Reload data when period changes
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallAttendanceCard() {
    if (_attendanceSummary == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No attendance data available'),
        ),
      );
    }
    
    final percentage = _attendanceSummary!.attendancePercentage;
    final color = _getAttendanceColor(percentage);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Attendance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        '${_attendanceSummary!.attendedClasses} out of ${_attendanceSummary!.totalClasses} classes',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator(
                            value: percentage / 100,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAttendanceMetric(
                    'Present',
                    '${_attendanceSummary!.attendedClasses}',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildAttendanceMetric(
                    'Absent',
                    '${_attendanceSummary!.totalClasses - _attendanceSummary!.attendedClasses}',
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildAttendanceMetric(
                    'Total Classes',
                    '${_attendanceSummary!.totalClasses}',
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectWiseAttendance() {
    if (_attendanceSummary == null || _attendanceSummary!.subjectWise.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No subject-wise data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subject-wise Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._attendanceSummary!.subjectWise.entries.map(
              (entry) {
                final subject = entry.key;
                final data = entry.value;
                final percentage = data.percentage;
                final color = _getAttendanceColor(percentage);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${data.attendedClasses}/${data.totalClasses}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAttendance() {
    if (_recentAttendance.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No recent attendance records'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._recentAttendance.map(
              (record) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: record.isPresent 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  child: Icon(
                    record.isPresent ? Icons.check : Icons.close,
                    color: record.isPresent ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(record.subject),
                subtitle: Text(
                  '${record.date.day}/${record.date.month}/${record.date.year}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: record.isPresent 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.isPresent ? 'Present' : 'Absent',
                    style: TextStyle(
                      color: record.isPresent ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceMetric(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 85) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }
}