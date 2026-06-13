import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityProvider with ChangeNotifier {
  static const String _passwordKey = 'archive_password';
  String? _password;

  String? get password => _password;
  bool get isPasswordSet => _password != null && _password!.isNotEmpty;

  SecurityProvider() {
    _loadPassword();
  }

  Future<void> _loadPassword() async {
    final prefs = await SharedPreferences.getInstance();
    _password = prefs.getString(_passwordKey);
    notifyListeners();
  }

  Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordKey, password);
    _password = password;
    notifyListeners();
  }

  Future<void> removePassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordKey);
    _password = null;
    notifyListeners();
  }

  bool checkPassword(String input) {
    return _password == input;
  }
}
