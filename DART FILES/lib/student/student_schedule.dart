import 'package:flutter/material.dart';
import '../models/student_model.dart';

class StudentSchedulePage extends StatefulWidget {
  final Student? student;

  const StudentSchedulePage({super.key, this.student});

  @override
  State<StudentSchedulePage> createState() => _StudentSchedulePageState();
}

class _StudentSchedulePageState extends State<StudentSchedulePage> {
  final List<String> _weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  final List<String> _timeSlots = [
    '9:00 - 10:00',
    '10:15 - 11:15',
    '11:30 - 12:30',
    '1:30 - 2:30',
    '2:45 - 3:45',
    '4:00 - 5:00',
  ];

  // Sample schedule data
  final Map<String, Map<String, Map<String, String>>> _schedule = {
    'Monday': {
      '9:00 - 10:00': {'subject': 'Machine Learning', 'room': 'Room 301', 'teacher': 'Dr. Smith'},
      '10:15 - 11:15': {'subject': 'Data Structures', 'room': 'Room 205', 'teacher': 'Prof. Johnson'},
      '11:30 - 12:30': {'subject': 'Database Systems', 'room': 'Lab 1', 'teacher': 'Dr. Brown'},
      '2:45 - 3:45': {'subject': 'Software Engineering', 'room': 'Room 401', 'teacher': 'Prof. Davis'},
    },
    'Tuesday': {
      '9:00 - 10:00': {'subject': 'Computer Networks', 'room': 'Room 302', 'teacher': 'Dr. Wilson'},
      '10:15 - 11:15': {'subject': 'Operating Systems', 'room': 'Room 206', 'teacher': 'Prof. Miller'},
      '1:30 - 2:30': {'subject': 'Machine Learning Lab', 'room': 'Lab 2', 'teacher': 'Dr. Smith'},
      '2:45 - 3:45': {'subject': 'Database Lab', 'room': 'Lab 1', 'teacher': 'Dr. Brown'},
    },
    'Wednesday': {
      '9:00 - 10:00': {'subject': 'Software Engineering', 'room': 'Room 401', 'teacher': 'Prof. Davis'},
      '10:15 - 11:15': {'subject': 'Machine Learning', 'room': 'Room 301', 'teacher': 'Dr. Smith'},
      '11:30 - 12:30': {'subject': 'Computer Networks', 'room': 'Room 302', 'teacher': 'Dr. Wilson'},
      '2:45 - 3:45': {'subject': 'Data Structures Lab', 'room': 'Lab 3', 'teacher': 'Prof. Johnson'},
    },
    'Thursday': {
      '9:00 - 10:00': {'subject': 'Operating Systems', 'room': 'Room 206', 'teacher': 'Prof. Miller'},
      '10:15 - 11:15': {'subject': 'Database Systems', 'room': 'Lab 1', 'teacher': 'Dr. Brown'},
      '11:30 - 12:30': {'subject': 'Data Structures', 'room': 'Room 205', 'teacher': 'Prof. Johnson'},
      '1:30 - 2:30': {'subject': 'Software Engineering Lab', 'room': 'Lab 4', 'teacher': 'Prof. Davis'},
    },
    'Friday': {
      '9:00 - 10:00': {'subject': 'Machine Learning', 'room': 'Room 301', 'teacher': 'Dr. Smith'},
      '10:15 - 11:15': {'subject': 'Computer Networks', 'room': 'Room 302', 'teacher': 'Dr. Wilson'},
      '11:30 - 12:30': {'subject': 'Operating Systems', 'room': 'Room 206', 'teacher': 'Prof. Miller'},
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 20),

            // Today's Classes
            _buildTodaysClasses(),
            const SizedBox(height: 20),

            // Weekly Schedule
            _buildWeeklySchedule(),
            const SizedBox(height: 20),

            // Upcoming Classes
            _buildUpcomingClasses(),
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
            Icon(Icons.schedule, color: Colors.indigo, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Class Schedule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your weekly timetable',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysClasses() {
    final today = DateTime.now().weekday;
    final todayName = _weekDays[today - 1];
    final todaysClasses = _schedule[todayName] ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Classes ($todayName)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (todaysClasses.isEmpty)
              const Text(
                'No classes scheduled for today',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...todaysClasses.entries.map((entry) {
                final time = entry.key;
                final classInfo = entry.value;
                return _buildClassCard(time, classInfo, Colors.green);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Time')),
                  ..._weekDays.take(5).map((day) => DataColumn(
                    label: Text(day.substring(0, 3)),
                  )).toList(),
                ],
                rows: _timeSlots.map((timeSlot) {
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        timeSlot,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      )),
                      ..._weekDays.take(5).map((day) {
                        final classInfo = _schedule[day]?[timeSlot];
                        return DataCell(
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: classInfo != null 
                                  ? Colors.indigo.withOpacity(0.1)
                                  : null,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              classInfo?['subject'] ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: classInfo != null 
                                    ? FontWeight.w500 
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingClasses() {
    // Get next few classes from schedule
    final upcomingClasses = [
      {'time': '2:45 - 3:45', 'subject': 'Software Engineering', 'room': 'Room 401', 'teacher': 'Prof. Davis'},
      {'time': '9:00 - 10:00', 'subject': 'Operating Systems', 'room': 'Room 206', 'teacher': 'Prof. Miller'},
      {'time': '10:15 - 11:15', 'subject': 'Database Systems', 'room': 'Lab 1', 'teacher': 'Dr. Brown'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upcoming, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Upcoming Classes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...upcomingClasses.map((classInfo) => 
              _buildClassCard(classInfo['time']!, classInfo, Colors.orange)
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(String time, Map<String, String> classInfo, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classInfo['subject'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${classInfo['room']} • ${classInfo['teacher']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}