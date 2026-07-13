import 'package:shared_preferences/shared_preferences.dart';

class Session {
  // stored after login/signup
  static String? token;
  static String? role; // 'customer' or 'technician' or 'admin'
  static int? userId;
  static String? name;
  static String? email;
  static String? phone;
  static String? address;
  static double? latitude;
  static double? longitude;

  static Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) await prefs.setString('token', token!);
    if (role != null) await prefs.setString('role', role!);
    if (userId != null) await prefs.setInt('userId', userId!);
    if (name != null) await prefs.setString('name', name!);
    if (email != null) await prefs.setString('email', email!);
    if (phone != null) await prefs.setString('phone', phone!);
    if (address != null) await prefs.setString('address', address!);
    if (latitude != null) await prefs.setDouble('latitude', latitude!);
    if (longitude != null) await prefs.setDouble('longitude', longitude!);
  }

  static Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    role = prefs.getString('role');
    userId = prefs.getInt('userId');
    name = prefs.getString('name');
    email = prefs.getString('email');
    phone = prefs.getString('phone');
    address = prefs.getString('address');
    latitude = prefs.getDouble('latitude');
    longitude = prefs.getDouble('longitude');
  }

  static Future<void> clear() async {
    token = null;
    role = null;
    userId = null;
    name = null;
    email = null;
    phone = null;
    address = null;
    latitude = null;
    longitude = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
