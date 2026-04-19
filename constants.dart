// lib/constants.dart
class ApiConstants {
  // IP ng Laptop A + Port ng FastAPI
  static const String ipAddress = "10.86.240.68"; 
  static const String baseUrl = "http://$ipAddress:8000";

  // Endpoints
  static const String matchClip = "$baseUrl/match-clip";
}