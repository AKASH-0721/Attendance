import 'package:flutter/material.dart';

class AttendanceGrid extends StatelessWidget {
  final Map<String, bool> attendance;
  final Function(String) onToggle;
  final List<String> registeredUSNs; // Add this to know which students have profiles

  const AttendanceGrid({
    super.key,
    required this.attendance,
    required this.onToggle,
    required this.registeredUSNs,
  });

  @override
  Widget build(BuildContext context) {
    // Sort the roll numbers in ascending order
    List<String> sortedRollNumbers = attendance.keys.toList()..sort();
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Reduced from 5 to 3 for larger cells
        childAspectRatio: 1.2, // Reduced from 2 to 1.2 for taller cells
        crossAxisSpacing: 8, // Added spacing between columns
        mainAxisSpacing: 8, // Added spacing between rows
      ),
      itemCount: sortedRollNumbers.length,
      itemBuilder: (context, i) {
        String rollNumber = sortedRollNumbers[i];
        bool present = attendance[rollNumber] ?? false;
        bool hasProfile = registeredUSNs.contains(rollNumber);
        
        // Color logic: Green if present, Red if absent, Gray border if no profile
        Color cardColor = present ? Colors.green[600]! : Colors.red[600]!;
        Color? borderColor = hasProfile ? null : Colors.orange;
        double borderWidth = hasProfile ? 0 : 3;
        
        return GestureDetector(
          onTap: () => onToggle(rollNumber),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: borderColor ?? Colors.transparent,
                width: borderWidth,
              ),
            ),
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile indicator
                  if (!hasProfile)
                    Icon(
                      Icons.person_off,
                      color: Colors.white,
                      size: 12,
                    ),
                  Text(
                    rollNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Icon(
                    present ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 16,
                  ),
                  Text(
                    present ? 'Present' : 'Absent',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Show profile status
                  if (!hasProfile)
                    Text(
                      'No Profile',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
