import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'attendance_grid.dart';
import 'api_service.dart';
import '../services/attendance_service.dart';
import '../services/student_service.dart';
import '../services/usn_generator_service.dart';
import '../models/student_model.dart';

class MarkAttendanceTab extends StatefulWidget {
  const MarkAttendanceTab({super.key});

  @override
  State<MarkAttendanceTab> createState() => _MarkAttendanceTabState();
}

class _MarkAttendanceTabState extends State<MarkAttendanceTab> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  XFile? _capturedImage;
  String selectedSection = "A";
  Map<String, bool> attendance = {}; // Changed to use roll numbers as keys
  List<Student> sectionStudents = [];
  final AttendanceService _attendanceService = AttendanceService();
  final StudentService _studentService = StudentService();
  final USNGeneratorService _usnGeneratorService = USNGeneratorService();
  final TextEditingController _subjectController = TextEditingController();
  String selectedSubject = "Machine Learning";
  String selectedDepartment = "AD";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeAttendance();
  }

  void _initializeAttendance() async {
    attendance.clear();
    try {
      // Get ALL possible USNs for the section and department (not just active ones)
      List<String> allPossibleUSNs = _usnGeneratorService
          .getAllPossibleUSNsForSection(
            selectedSection,
            department: selectedDepartment,
          );

      // Create attendance map for ALL possible USNs
      for (String usn in allPossibleUSNs) {
        attendance[usn] = false; // Initialize all as absent
      }

      // Also get registered students for reference (but don't limit to them)
      sectionStudents = await _studentService.getStudentsBySection(
        selectedSection,
      );
      sectionStudents = sectionStudents.where((student) {
        return student.rollNumber.contains(selectedDepartment);
      }).toList();

      print(
        "Initialized attendance for Section $selectedSection, Department $selectedDepartment",
      );
      print("All possible USNs: ${attendance.keys.toList()}");
      print("Total USNs: ${attendance.length}");
      print(
        "Registered students: ${sectionStudents.map((s) => s.rollNumber).toList()}",
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading students: ${e.toString()}')),
      );
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final rawImage = await _controller!.takePicture();
    setState(() => _capturedImage = rawImage);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _capturedImage = XFile(picked.path));
  }

  Future<void> _recognizeFaces() async {
    if (_capturedImage == null) return;
    try {
      final file = File(_capturedImage!.path);
      final res = await ApiService.recognizeFace(file);

      // Debug: Print the full API response
      print("=== FACE RECOGNITION DEBUG ===");
      print("API Response: $res");
      print("Selected Department: $selectedDepartment");
      print("Selected Section: $selectedSection");
      print("Attendance Map Sample: ${attendance.keys.take(5).toList()}");

      int markedCount = 0;

      // Check different API response formats
      List<String> recognizedRolls = [];
      
      if (res['marked_ids'] != null) {
        print("Using marked_ids format: ${res['marked_ids']}");
        recognizedRolls = res['marked_ids'].map<String>((item) => item.toString()).toList();
      } else if (res['recognized_students'] != null) {
        print("Using recognized_students format: ${res['recognized_students']}");
        recognizedRolls = res['recognized_students'].map<String>((item) => item.toString()).toList();
      } else if (res['marked_rolls'] != null) {
        print("Using marked_rolls format: ${res['marked_rolls']}");
        recognizedRolls = res['marked_rolls'].map<String>((item) => item.toString()).toList();
      }
      
      if (recognizedRolls.isNotEmpty) {
        print("Processing recognized rolls: $recognizedRolls");
        
        for (String backendRollStr in recognizedRolls) {
          backendRollStr = backendRollStr.trim();
          print("\n--- Processing: '$backendRollStr' ---");

          // SIMPLE DIRECT MAPPING
          String expectedUSN = "";
          
          if (backendRollStr.length >= 5 && backendRollStr.contains('AD')) {
            // Format: "AD006" -> "1CR22AD006"
            expectedUSN = "1CR22$backendRollStr";
          } else if (backendRollStr.length == 3) {
            // Format: "006" -> "1CR22AD006" (using selected department)
            expectedUSN = "1CR22$selectedDepartment$backendRollStr";
          } else if (backendRollStr.startsWith('AD') || backendRollStr.startsWith('CS') || 
                     backendRollStr.startsWith('EC') || backendRollStr.startsWith('ME')) {
            // Format: "AD006", "CS012", etc. -> "1CR22AD006", "1CR22CS012"
            expectedUSN = "1CR22$backendRollStr";
          }
          
          print("Expected USN: '$expectedUSN'");
          print("Checking if '$expectedUSN' exists in attendance map...");
          
          // Check if this exact USN exists in attendance map
          if (attendance.containsKey(expectedUSN)) {
            attendance[expectedUSN] = true;
            markedCount++;
            print("✅ SUCCESS: '$backendRollStr' -> '$expectedUSN' MARKED PRESENT");
          } else {
            // Fallback: search for any USN containing the backend roll
            bool found = false;
            print("Direct match failed, searching for partial matches...");
            
            for (String usn in attendance.keys) {
              if (usn.contains(backendRollStr) || usn.endsWith(backendRollStr)) {
                attendance[usn] = true;
                markedCount++;
                found = true;
                print("✅ FALLBACK SUCCESS: '$backendRollStr' -> '$usn' MARKED PRESENT");
                break;
              }
            }
            
            if (!found) {
              print("❌ FAILED: No USN found for '$backendRollStr'");
              print("Sample available USNs: ${attendance.keys.take(5).join(', ')}...");
              print("Total USNs in map: ${attendance.length}");
            }
          }
        }
      } else {
        print("❌ No recognized students found in API response");
        print("Available response keys: ${res.keys.toList()}");
      }
      
      // Fallback: Check for old format with numeric positions or partial labels
      if (res['marked_rolls'] != null && recognizedRolls.isEmpty) {
        print("Using marked_rolls format: ${res['marked_rolls']}");
        for (var item in res['marked_rolls']) {
          String itemStr = item.toString();
          print("Processing item: $itemStr");

          // Check if it's a partial roll number (like "AD006")
          if (itemStr.contains('AD') ||
              itemStr.contains('CS') ||
              itemStr.contains('EC') ||
              itemStr.contains('ME')) {
            String? matchingRollNumber = _findRollNumberByPartialMatch(itemStr);
            if (matchingRollNumber != null &&
                attendance.containsKey(matchingRollNumber)) {
              attendance[matchingRollNumber] = true;
              markedCount++;
              print("Partial match: $itemStr -> $matchingRollNumber");
            } else {
              print("No matching student found for partial roll: $itemStr");
            }
          }
          // Try direct roll number match
          else if (attendance.containsKey(itemStr)) {
            attendance[itemStr] = true;
            markedCount++;
            print("Direct match found: $itemStr");
          }
          // Try numeric position mapping
          else if (int.tryParse(itemStr) != null) {
            int numericRoll = int.parse(itemStr);
            String? matchingRollNumber = _findRollNumberByPosition(numericRoll);
            if (matchingRollNumber != null &&
                attendance.containsKey(matchingRollNumber)) {
              attendance[matchingRollNumber] = true;
              markedCount++;
              print(
                "Position-based match: $numericRoll -> $matchingRollNumber",
              );
            } else {
              print("No mapping found for position: $numericRoll");
            }
          }
        }
      } else {
        print("No recognized students or marked rolls in response");
      }

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${res['message'] ?? 'Face recognition completed'} - $markedCount students marked",
          ),
        ),
      );

      // Show debug dialog if no students were marked
      if (markedCount == 0) {
        _showDebugDialog(res);
      }
    } catch (e) {
      print("Face recognition error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _showDebugDialog(Map<String, dynamic> apiResponse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Debug Info"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("API Response: ${apiResponse.toString()}"),
            const SizedBox(height: 10),
            Text(
              "Available Students: ${sectionStudents.map((s) => s.rollNumber).join(', ')}",
            ),
            const SizedBox(height: 10),
            const Text(
              "No students were automatically marked. You can mark them manually by tapping on the grid.",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String? _findRollNumberByPartialMatch(String partialRoll) {
    print("=== PARTIAL MATCH DEBUG ===");
    print("Looking for partial match: '$partialRoll'");
    print("Available students in attendance map: ${attendance.keys.toList()}");
    print(
      "Section students: ${sectionStudents.map((s) => s.rollNumber).toList()}",
    );

    // Clean the partial roll (remove any whitespace)
    String cleanPartialRoll = partialRoll.trim();

    // Method 1: Direct search in attendance map keys
    for (String fullUSN in attendance.keys) {
      if (fullUSN.contains(cleanPartialRoll)) {
        print(
          "✅ Direct match in attendance map: $cleanPartialRoll -> $fullUSN",
        );
        return fullUSN;
      }

      if (fullUSN.endsWith(cleanPartialRoll)) {
        print("✅ End match in attendance map: $cleanPartialRoll -> $fullUSN");
        return fullUSN;
      }
    }

    // Method 2: Parse partial roll and construct full USN
    RegExp partialRegex = RegExp(r'([A-Z]{2})(\d+)');
    Match? partialMatch = partialRegex.firstMatch(cleanPartialRoll);

    if (partialMatch != null) {
      String dept = partialMatch.group(1)!; // AD, CS, EC, etc.
      String number = partialMatch.group(2)!; // 006, 011, etc.

      print("Parsed partial: dept='$dept', number='$number'");

      // Construct expected full USN
      String paddedNumber = number.padLeft(3, '0'); // Ensure 3 digits
      String expectedUSN = "1CR22$dept$paddedNumber";

      print("Expected full USN: $expectedUSN");

      // Check if this USN exists in our attendance map
      if (attendance.containsKey(expectedUSN)) {
        print("✅ Constructed USN match: $cleanPartialRoll -> $expectedUSN");
        return expectedUSN;
      }

      // Also check variations
      for (String fullUSN in attendance.keys) {
        if (fullUSN.contains(dept) && fullUSN.contains(paddedNumber)) {
          print("✅ Pattern match: $cleanPartialRoll -> $fullUSN");
          return fullUSN;
        }
      }
    }

    // Method 3: Fuzzy matching for any attendance key containing the partial
    for (String fullUSN in attendance.keys) {
      String lowerFullUSN = fullUSN.toLowerCase();
      String lowerPartial = cleanPartialRoll.toLowerCase();

      if (lowerFullUSN.contains(lowerPartial)) {
        print("✅ Fuzzy match: $cleanPartialRoll -> $fullUSN");
        return fullUSN;
      }
    }

    print("❌ No match found for partial roll: $cleanPartialRoll");
    print("Available USNs: ${attendance.keys.join(', ')}");
    return null;
  }

  String? _findRollNumberByPosition(int position) {
    print("=== POSITION MAPPING DEBUG ===");
    print(
      "Trying to map position $position in section $selectedSection, department $selectedDepartment",
    );
    print("Available students in attendance map: ${attendance.keys.toList()}");

    // Method 1: Direct USN construction based on position
    String paddedPosition = position.toString().padLeft(3, '0');
    String expectedUSN = "1CR22$selectedDepartment$paddedPosition";

    print("Expected USN for position $position: $expectedUSN");

    if (attendance.containsKey(expectedUSN)) {
      print("✅ Direct USN construction: position $position -> $expectedUSN");
      return expectedUSN;
    }

    // Method 2: Check if position matches any USN suffix in attendance map
    for (String usn in attendance.keys) {
      RegExp regExp = RegExp(r'(\d+)$');
      Match? match = regExp.firstMatch(usn);

      if (match != null) {
        int usnNumber = int.parse(match.group(1)!);
        if (usnNumber == position) {
          print("✅ USN suffix match: position $position -> $usn");
          return usn;
        }
      }
    }

    // Method 3: Section-based sequential mapping
    List<String> sortedUSNs = attendance.keys.toList()..sort();

    int index = -1;
    if (selectedSection == "A" && position >= 1 && position <= 64) {
      index = position - 1;
    } else if (selectedSection == "B" && position >= 65 && position <= 127) {
      index = position - 65;
    } else if (selectedSection == "C" && position >= 128 && position <= 200) {
      index = position - 128;
    }

    if (index >= 0 && index < sortedUSNs.length) {
      print("✅ Sequential mapping: position $position -> ${sortedUSNs[index]}");
      return sortedUSNs[index];
    }

    // Method 4: Try to find any USN containing the department and position
    for (String usn in attendance.keys) {
      if (usn.contains(selectedDepartment) && usn.contains(paddedPosition)) {
        print("✅ Department + position match: position $position -> $usn");
        return usn;
      }
    }

    print("❌ No match found for position $position");
    print("Available USNs: ${attendance.keys.join(', ')}");
    return null;
  }

  void _toggleRoll(String rollNumber) {
    setState(() => attendance[rollNumber] = !(attendance[rollNumber] ?? false));
  }

  void _saveAttendance() async {
    if (selectedSubject.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a subject")));
      return;
    }

    List<String> presentRolls = [];
    attendance.forEach((rollNumber, present) {
      if (present) presentRolls.add(rollNumber);
    });

    try {
      // Save to Firebase for ALL students marked present (regardless of profile existence)
      await _attendanceService.saveAttendanceRecords(
        presentStudentRolls: presentRolls,
        teacherId: "current_teacher_id", // You should get this from auth
        subject: selectedSubject,
        section: selectedSection,
        date: DateTime.now(),
      );

      // Also save to a separate collection for students without profiles
      await _saveAttendanceForUnregisteredStudents(presentRolls);

      // Also save to external API if needed
      try {
        // Convert full USNs to backend format (AD006, AD057, etc.)
        List<String> backendFormatRolls = [];
        for (String fullUSN in presentRolls) {
          String? backendFormat = _convertUSNToBackendFormat(fullUSN);
          if (backendFormat != null) {
            backendFormatRolls.add(backendFormat);
          }
        }

        print("Converting for backend: $presentRolls -> $backendFormatRolls");

        // Try to save with backend format first
        await ApiService.saveAttendanceByUSN(
          backendFormatRolls,
          selectedSection,
          selectedSubject,
        );
        print("Saved using backend format method");
      } catch (apiError) {
        // Fallback: Convert roll numbers to numeric positions for old API compatibility
        try {
          List<int> numericRolls = [];
          for (String rollNumber in presentRolls) {
            int? position = _findPositionByRollNumber(rollNumber);
            if (position != null) numericRolls.add(position);
          }

          await ApiService.saveAttendance(numericRolls, selectedSection);
          print("Saved using fallback numeric method");
        } catch (fallbackError) {
          // Both API methods failed, but Firebase save succeeded
          print("Both API save methods failed: $fallbackError");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance saved successfully")),
      );

      // Navigate back
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving attendance: ${e.toString()}")),
      );
    }
  }

  int? _findPositionByRollNumber(String rollNumber) {
    print(
      "Finding position for roll number: $rollNumber in section $selectedSection",
    );

    // Sort students by roll number to ensure consistent ordering
    List<Student> sortedStudents = List.from(sectionStudents);
    sortedStudents.sort((a, b) => a.rollNumber.compareTo(b.rollNumber));

    // Method 1: Find student in sorted list and calculate position
    for (int i = 0; i < sortedStudents.length; i++) {
      if (sortedStudents[i].rollNumber == rollNumber) {
        int position;
        if (selectedSection == "A") {
          position = i + 1; // Section A: 1-64
        } else if (selectedSection == "B") {
          position = i + 65; // Section B: 65-127
        } else if (selectedSection == "C") {
          position = i + 128; // Section C: 128-200
        } else {
          position = i + 1; // Default
        }
        print("Found position by sorting: $rollNumber -> $position");
        return position;
      }
    }

    // Method 2: Try to extract position from roll number suffix
    RegExp regExp = RegExp(r'(\d+)$');
    Match? match = regExp.firstMatch(rollNumber);

    if (match != null) {
      int rollNumericPart = int.parse(match.group(1)!);

      // Verify this student actually exists in our section
      bool studentExists = sectionStudents.any(
        (s) => s.rollNumber == rollNumber,
      );
      if (studentExists) {
        print("Found position by suffix: $rollNumber -> $rollNumericPart");
        return rollNumericPart;
      }
    }

    print("No position found for roll number: $rollNumber");
    return null;
  }

  String? _convertUSNToBackendFormat(String fullUSN) {
    // Convert full USN like "1CR22AD006" to backend format like "AD006"
    print("Converting USN to backend format: $fullUSN");

    // Extract department and number from full USN
    // Pattern: 1CR22AD006 -> AD006
    RegExp usnRegex = RegExp(r'1CR\d+([A-Z]{2})(\d{3})$');
    Match? match = usnRegex.firstMatch(fullUSN);

    if (match != null) {
      String department = match.group(1)!; // AD, CS, EC, etc.
      String number = match.group(2)!; // 006, 057, etc.
      String backendFormat = department + number;

      print("Converted: $fullUSN -> $backendFormat");
      return backendFormat;
    }

    // Fallback: try alternative patterns
    RegExp alternativeRegex = RegExp(r'([A-Z]{2})(\d+)$');
    Match? altMatch = alternativeRegex.firstMatch(fullUSN);

    if (altMatch != null) {
      String department = altMatch.group(1)!;
      String number = altMatch.group(2)!.padLeft(3, '0'); // Ensure 3 digits
      String backendFormat = department + number;

      print("Alternative conversion: $fullUSN -> $backendFormat");
      return backendFormat;
    }

    print("Could not convert USN: $fullUSN");
    return null;
  }

  String? _convertBackendFormatToUSN(String backendFormat) {
    // Convert backend format like "AD006" to full USN like "1CR22AD006"
    print("Converting backend format to USN: $backendFormat");

    RegExp backendRegex = RegExp(r'^([A-Z]{2})(\d+)$');
    Match? match = backendRegex.firstMatch(backendFormat);

    if (match != null) {
      String department = match.group(1)!; // AD, CS, EC, etc.
      String number = match.group(2)!.padLeft(3, '0'); // Ensure 3 digits
      String fullUSN = "1CR22$department$number";

      print("Converted: $backendFormat -> $fullUSN");
      return fullUSN;
    }

    print("Could not convert backend format: $backendFormat");
    return null;
  }

  Future<void> _saveAttendanceForUnregisteredStudents(
    List<String> presentRolls,
  ) async {
    try {
      // Get registered USNs
      Set<String> registeredUSNs = sectionStudents
          .map((s) => s.rollNumber)
          .toSet();

      // Find unregistered students who were marked present
      List<String> unregisteredPresentStudents = presentRolls
          .where((usn) => !registeredUSNs.contains(usn))
          .toList();

      if (unregisteredPresentStudents.isNotEmpty) {
        // Save to a separate collection for unregistered students
        for (String usn in unregisteredPresentStudents) {
          Map<String, dynamic> unregisteredAttendanceRecord = {
            'usn': usn,
            'teacherId': "current_teacher_id",
            'subject': selectedSubject,
            'section': selectedSection,
            'department': selectedDepartment,
            'date': DateTime.now().toIso8601String(),
            'isPresent': true,
            'hasProfile': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };

          // Save to Firebase in a separate collection
          await FirebaseFirestore.instance
              .collection('unregistered_attendance')
              .add(unregisteredAttendanceRecord);
        }

        print(
          "Saved attendance for ${unregisteredPresentStudents.length} unregistered students: $unregisteredPresentStudents",
        );
      }
    } catch (e) {
      print("Error saving unregistered student attendance: $e");
    }
  }


  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Section toggle buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ["A", "B", "C"].map((sec) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedSection == sec
                    ? Colors.blue
                    : Colors.grey,
              ),
              onPressed: () {
                selectedSection = sec;
                _initializeAttendance();
              },
              child: Text(sec),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Department selection
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                "Department: ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: DropdownButton<String>(
                  value: selectedDepartment,
                  isExpanded: true,
                  items: ["AD", "CS", "EC", "ME", "CV", "EE"]
                      .map(
                        (dept) =>
                            DropdownMenuItem(value: dept, child: Text(dept)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDepartment = value!;
                      _initializeAttendance(); // Reload students for new department
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Subject selection
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                "Subject: ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: DropdownButton<String>(
                  value: selectedSubject,
                  isExpanded: true,
                  items:
                      [
                            "Machine Learning",
                            "Data Structures",
                            "Database Systems",
                            "Software Engineering",
                            "Computer Networks",
                            "Web Development",
                            "Mobile App Development",
                          ]
                          .map(
                            (subject) => DropdownMenuItem(
                              value: subject,
                              child: Text(subject),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSubject = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Camera preview or selected image
        Expanded(
          child: _capturedImage == null
              ? CameraPreview(_controller!)
              : Image.file(File(_capturedImage!.path), fit: BoxFit.contain),
        ),
        const SizedBox(height: 10),

        // Buttons Row 1
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _captureImage,
              child: const Text("Capture"),
            ),
            ElevatedButton(onPressed: _pickImage, child: const Text("Upload")),
            ElevatedButton(
              onPressed: _recognizeFaces,
              child: const Text("Recognize"),
            ),
            ElevatedButton(
              onPressed: _saveAttendance,
              child: const Text("Save"),
            ),
          ],
        ),
        const SizedBox(height: 5),

        const SizedBox(height: 10),
        const SizedBox(height: 10),

        // Attendance Grid
        Expanded(
          child: AttendanceGrid(
            attendance: attendance,
            onToggle: _toggleRoll,
            registeredUSNs: sectionStudents.map((s) => s.rollNumber).toList(),
          ),
        ),
      ],
    );
  }
}
