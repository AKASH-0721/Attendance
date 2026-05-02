# 📱 Attendance Management System

A comprehensive Flutter-based attendance tracking application with facial recognition technology and multi-role user management for educational institutions.

## 🌟 Features

### 🎯 Core Functionality
- **Facial Recognition Attendance** - AI-powered automatic student identification
- **Multi-Role System** - Students, Teachers, and Admins with distinct dashboards
- **Real-time Updates** - Live attendance tracking and synchronization
- **Cross-Platform** - Works on Android, iOS, Web, and Desktop

### 👥 User Management
- **Student Portal** - Personal attendance tracking, schedules, and academic info
- **Teacher Portal** - Class management, attendance marking, and student oversight
- **Admin Dashboard** - Complete system management and user administration

### 🔐 Authentication & Security
- **Firebase Authentication** - Secure email/password login system
- **Role-based Access Control** - Appropriate permissions for each user type
- **Password Reset** - Email-based password recovery
- **Profile Management** - Edit profiles, change passwords, upload photos

## 🏗️ Architecture

### 📱 Frontend
- **Flutter** - Cross-platform mobile framework
- **Material Design 3** - Modern, responsive UI/UX
- **State Management** - Efficient app state handling
- **Image Processing** - Camera integration and photo management

### ☁️ Backend
- **Firebase Firestore** - NoSQL cloud database
- **Firebase Authentication** - User management and security
- **Firebase Storage** - Profile photos and file storage
- **Python Flask API** - Facial recognition processing

### 🤖 AI Integration
- **Facial Recognition API** - Automated student identification
- **Image Processing** - Photo capture and analysis
- **Attendance Automation** - Smart attendance marking

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Android Studio / VS Code
- Firebase account
- Python environment (for facial recognition API)

### 📦 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/attendance_interface.git
   cd attendance_interface
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Create Firestore Database
   - Enable Storage
   - Download and place `google-services.json` in `android/app/`

4. **Configure Firebase**
   ```bash
   flutter pub global activate flutterfire_cli
   flutterfire configure
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## 📱 User Roles & Features

### 🎓 Students
- **Registration** - Complete profile setup with photo upload
- **Login** - Secure authentication
- **Dashboard** - Personal attendance statistics and academic info
- **Schedule** - View daily classes and upcoming events
- **Profile** - Update personal information

### 👨‍🏫 Teachers
- **Registration** - Professional profile with class assignments
- **Login** - Role-based authentication
- **Attendance Marking** - Camera-based facial recognition
- **Class Management** - Section-wise student management
- **Manual Override** - Adjust attendance as needed
- **Profile Editing** - Update professional information

### 👨‍💼 Admins
- **Dashboard** - System overview with statistics
- **User Management** - Manage teachers and students
- **Reports** - Generate attendance and performance reports
- **System Settings** - Configure application parameters
- **Data Management** - Backup and restore functionality

## 🔧 Configuration

### Firebase Setup
1. **Authentication Rules**
   ```javascript
   // Enable Email/Password authentication
   ```

2. **Firestore Security Rules**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

3. **Storage Rules**
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

### API Configuration
- **Facial Recognition API**: `http://192.168.0.3:5000`
- **Image Processing**: Automatic resizing and optimization
- **Network Timeout**: 30 seconds for API calls

## 📊 Database Structure

### Collections
- **`teachers`** - Teacher profiles and class assignments
- **`students`** - Student information and academic details
- **`admins`** - Administrator accounts and permissions
- **`attendance`** - Daily attendance records
- **`classes`** - Class schedules and section information

### Data Models
```dart
// Teacher Model
class Teacher {
  String id, name, email, designation, photo;
  List<String> classes;
}

// Student Model
class Student {
  String id, name, rollNumber, email, photo;
  String section, department, year;
  DateTime dateOfBirth;
}

// Admin Model
class Admin {
  String id, name, email, photo, role;
  List<String> permissions;
}
```

## 🎨 UI/UX Features

### Design System
- **Material Design 3** - Modern, accessible interface
- **Responsive Layout** - Adapts to different screen sizes
- **Dark/Light Theme** - User preference support
- **Consistent Branding** - Unified color scheme and typography

### User Experience
- **Intuitive Navigation** - Clear user flows
- **Loading States** - Visual feedback for operations
- **Error Handling** - User-friendly error messages
- **Offline Support** - Basic functionality without internet

## 🔒 Security Features

### Authentication
- **Firebase Auth** - Industry-standard security
- **Email Verification** - Account validation
- **Password Policies** - Strong password requirements
- **Session Management** - Secure login sessions

### Data Protection
- **Encrypted Storage** - Secure data at rest
- **HTTPS Communication** - Encrypted data in transit
- **Role-based Access** - Appropriate data access controls
- **Privacy Compliance** - GDPR/CCPA considerations

## 📱 Platform Support

### Mobile
- **Android** - API level 21+ (Android 5.0+)
- **iOS** - iOS 11.0+

### Desktop
- **Windows** - Windows 10+
- **macOS** - macOS 10.14+
- **Linux** - Ubuntu 18.04+

### Web
- **Modern Browsers** - Chrome, Firefox, Safari, Edge
- **Progressive Web App** - Installable web experience

## 🛠️ Development

### Project Structure
```
lib/
├── models/          # Data models
├── services/        # API and Firebase services
├── student/         # Student-related screens
├── teacher/         # Teacher-related screens
├── admin/           # Admin-related screens
├── main.dart        # App entry point
└── firebase_options.dart
```

### Code Style
- **Dart Style Guide** - Consistent formatting
- **Documentation** - Comprehensive code comments
- **Testing** - Unit and widget tests
- **CI/CD** - Automated build and deployment

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Email**: support@attendanceapp.com
- **Documentation**: [Wiki](https://github.com/yourusername/attendance_interface/wiki)
- **Issues**: [GitHub Issues](https://github.com/yourusername/attendance_interface/issues)

## 🙏 Acknowledgments

- **Flutter Team** - Amazing cross-platform framework
- **Firebase** - Reliable backend services
- **Material Design** - Beautiful design system
- **Open Source Community** - Inspiration and packages

---

**Built with ❤️ using Flutter and Firebase**
