/// Edstream Global Constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Edstream';
  static const String appTagline = 'Smart School Management & Learning Platform';

  // API Endpoints Base URL
  static const String baseUrl = 'https://api.edstream.ng/api/v1';

  // Storage Keys
  static const String tokenKey = 'edstream_auth_token';
  static const String roleKey = 'edstream_user_role';
  static const String userProfileKey = 'edstream_user_profile';

  // Role Identifiers
  static const String roleTeacher = 'teacher';
  static const String roleStudent = 'student';
}

enum UserRole {
  teacher,
  student,
}
