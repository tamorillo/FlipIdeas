import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestiona el tema de la aplicación (Modo Claro / Modo Oscuro)
class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'is_dark_mode'; // Clave para guardar la preferencia
  bool _isDarkMode = false; // Variable que dice si estamos en modo oscuro

  // Permite saber desde fuera si estamos en modo oscuro
  bool get isDarkMode => _isDarkMode;

  // Constructor: Carga la preferencia del tema al abrir la app
  ThemeProvider() {
    _loadThemePreference();
  }

  // Carga si el usuario prefirió modo oscuro la última vez
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false; // Si no hay nada guardado, usa modo claro
    notifyListeners(); // Actualiza la app
  }

  // Cambia entre modo claro y oscuro y lo guarda en el móvil
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode; // Cambia el valor (true -> false o false -> true)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode); // Guarda el nuevo valor
    notifyListeners(); // Actualiza la app inmediatamente
  }
}
