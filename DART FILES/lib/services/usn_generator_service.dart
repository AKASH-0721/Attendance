import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import 'student_service.dart';

class USNGeneratorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StudentService _studentService = StudentService();

  // Generate all possible USNs for a given pattern
  List<String> generateAllUSNs({
    required String year, // e.g., "22"
    required String college, // e.g., "1CR"
    required String department, // e.g., "AD", "CS", "EC", "ME"
    required int startNumber, // e.g., 1
    required int endNumber, // e.g., 64
  }) {
    List<String> usns = [];
    
    for (int i = startNumber; i <= endNumber; i++) {
      String paddedNumber = i.toString().padLeft(3, '0'); // 001, 002, etc.
      String usn = "$college$year$department$paddedNumber";
      usns.add(usn);
    }
    
    return usns;
  }

  // Generate USNs for all sections and departments
  Map<String, List<String>> generateAllSectionUSNs() {
    Map<String, List<String>> allUSNs = {};
    
    // Common parameters
    String year = "22";
    String college = "1CR";
    List<String> departments = ["AD", "CS", "EC", "ME", "CV", "EE"];
    
    // Section A: 1-64
    for (String dept in departments) {
      String sectionKey = "A_$dept";
      allUSNs[sectionKey] = generateAllUSNs(
        year: year,
        college: college,
        department: dept,
        startNumber: 1,
        endNumber: 64,
      );
    }
    
    // Section B: 65-127 (or 1-63 for section B)
    for (String dept in departments) {
      String sectionKey = "B_$dept";
      allUSNs[sectionKey] = generateAllUSNs(
        year: year,
        college: college,
        department: dept,
        startNumber: 65,
        endNumber: 127,
      );
    }
    
    // Section C: 128-200 (or 1-73 for section C)
    for (String dept in departments) {
      String sectionKey = "C_$dept";
      allUSNs[sectionKey] = generateAllUSNs(
        year: year,
        college: college,
        department: dept,
        startNumber: 128,
        endNumber: 200,
      );
    }
    
    return allUSNs;
  }

  // Check which USNs have active profiles
  Future<Map<String, bool>> checkActiveUSNs(List<String> usns) async {
    Map<String, bool> activeStatus = {};
    
    try {
      // Get all students from Firestore
      List<Student> allStudents = await _studentService.getAllStudents();
      Set<String> registeredUSNs = allStudents.map((s) => s.rollNumber).toSet();
      
      // Check each USN
      for (String usn in usns) {
        activeStatus[usn] = registeredUSNs.contains(usn);
      }
      
    } catch (e) {
      print("Error checking active USNs: $e");
      // Default all to inactive if error
      for (String usn in usns) {
        activeStatus[usn] = false;
      }
    }
    
    return activeStatus;
  }

  // Get active USNs for a specific section
  Future<List<String>> getActiveUSNsForSection(String section) async {
    try {
      List<Student> sectionStudents = await _studentService.getStudentsBySection(section);
      return sectionStudents.map((s) => s.rollNumber).toList();
    } catch (e) {
      print("Error getting active USNs for section $section: $e");
      return [];
    }
  }

  // Get all possible USNs for a section (active + inactive)
  List<String> getAllPossibleUSNsForSection(String section, {String department = "AD"}) {
    String year = "22";
    String college = "1CR";
    
    switch (section.toUpperCase()) {
      case "A":
        return generateAllUSNs(
          year: year,
          college: college,
          department: department,
          startNumber: 1,
          endNumber: 64,
        );
      case "B":
        return generateAllUSNs(
          year: year,
          college: college,
          department: department,
          startNumber: 65,
          endNumber: 127,
        );
      case "C":
        return generateAllUSNs(
          year: year,
          college: college,
          department: department,
          startNumber: 128,
          endNumber: 200,
        );
      default:
        return [];
    }
  }

  // Create attendance map with all USNs (active and inactive)
  Future<Map<String, bool>> createAttendanceMapForSection(String section, {String department = "AD"}) async {
    Map<String, bool> attendanceMap = {};
    
    // Get all possible USNs for the section
    List<String> allUSNs = getAllPossibleUSNsForSection(section, department: department);
    
    // Get active USNs (students with profiles)
    List<String> activeUSNs = await getActiveUSNsForSection(section);
    Set<String> activeUSNsSet = activeUSNs.toSet();
    
    // Create attendance map
    for (String usn in allUSNs) {
      // Only include USNs that have active profiles
      if (activeUSNsSet.contains(usn)) {
        attendanceMap[usn] = false; // Default to absent
      }
    }
    
    return attendanceMap;
  }

  // Get USN details (extract components)
  Map<String, String> parseUSN(String usn) {
    // Example: 1CR22AD006
    RegExp usnRegex = RegExp(r'^(\d+)([A-Z]+)(\d+)([A-Z]+)(\d+)$');
    Match? match = usnRegex.firstMatch(usn);
    
    if (match != null) {
      return {
        'college': match.group(1)! + match.group(2)!, // 1CR
        'year': match.group(3)!, // 22
        'department': match.group(4)!, // AD
        'number': match.group(5)!, // 006
        'position': int.parse(match.group(5)!).toString(), // 6
      };
    }
    
    return {};
  }

  // Get section for a USN based on number range
  String getSectionForUSN(String usn) {
    Map<String, String> components = parseUSN(usn);
    if (components.isNotEmpty) {
      int number = int.parse(components['number']!);
      
      if (number >= 1 && number <= 64) {
        return "A";
      } else if (number >= 65 && number <= 127) {
        return "B";
      } else if (number >= 128 && number <= 200) {
        return "C";
      }
    }
    
    return "A"; // Default
  }

  // Bulk create placeholder students (for testing)
  Future<void> createPlaceholderStudents({
    required String section,
    required String department,
    required List<int> positions,
  }) async {
    try {
      String year = "22";
      String college = "1CR";
      
      for (int position in positions) {
        String paddedNumber = position.toString().padLeft(3, '0');
        String usn = "$college$year$department$paddedNumber";
        
        Student placeholderStudent = Student(
          id: usn,
          name: "Student $department$paddedNumber",
          rollNumber: usn,
          email: "${usn.toLowerCase()}@example.com",
          photo: "",
          section: section,
          department: department,
          year: "2022",
          phoneNumber: "9999999999",
          parentContact: "8888888888",
          dateOfBirth: DateTime(2000, 1, 1),
          address: "Address for $usn",
        );
        
        await _studentService.registerStudent(placeholderStudent);
        print("Created placeholder student: $usn");
      }
    } catch (e) {
      print("Error creating placeholder students: $e");
    }
  }
}