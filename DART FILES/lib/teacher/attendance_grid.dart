import 'package:flutter/material.dart';

class AttendanceGrid extends StatelessWidget {
  final Map<int, bool> attendance;
  final Function(int) onToggle;

  const AttendanceGrid({
    super.key,
    required this.attendance,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 2,
      ),
      itemCount: attendance.keys.length,
      itemBuilder: (context, i) {
        int roll = attendance.keys.elementAt(i);
        bool present = attendance[roll] ?? false;
        return GestureDetector(
          onTap: () => onToggle(roll),
          child: Card(
            color: present ? Colors.green : Colors.red,
            child: Center(
              child: Text(
                "$roll",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
