import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get localUrl => dotenv.env['API_LOCAL_DEVICE_URL'] ?? '';
}
