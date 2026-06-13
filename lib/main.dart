import 'package:flutter/material.dart'; // Importa las herramientas visuales de Flutter
import 'package:flutter_localizations/flutter_localizations.dart'; // Importa para el idioma español
import 'package:provider/provider.dart'; // Importa el gestor de estados para compartir datos
import 'providers/idea_provider.dart'; // Importa el gestor de las ideas
import 'providers/theme_provider.dart'; // Importa el gestor del tema (claro/oscuro)
import 'providers/security_provider.dart'; // Importa el gestor de seguridad
import 'routes/rutas.dart'; // Importa la configuración de navegación
import 'widgets/privacy_overlay.dart'; // Importa la capa de privacidad

void main() {
  runApp(
    MultiProvider( // Permite usar varios "almacenes de datos" en toda la app
      providers: [
        ChangeNotifierProvider(create: (_) => IdeaProvider()), // Crea el almacén de ideas
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // Crea el almacén del tema
        ChangeNotifierProvider(create: (_) => SecurityProvider()), // Crea el almacén de seguridad
      ],
      child: const FlipIdeasApp(), // Lanza la aplicación principal
    ),
  );
}

class FlipIdeasApp extends StatelessWidget {
  const FlipIdeasApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha los cambios en el tema (claro/oscuro)
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp.router(
      title: 'FlipIdeas', // Nombre de la aplicación
      debugShowCheckedModeBanner: false, // Quita la banda roja de "Debug"
      routerConfig: router, // Configura las rutas de navegación
      
      // --- CONFIGURACIÓN PARA IDIOMA ESPAÑOL ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
      ],
      locale: const Locale('es', 'ES'), // Forzamos español por defecto

      // Decide si mostrar modo oscuro o claro según la preferencia guardada
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildTheme(Brightness.light), // Estilo para el modo claro
      darkTheme: _buildTheme(Brightness.dark), // Estilo para el modo oscuro

      // Envuelve toda la app con la capa de privacidad
      builder: (context, child) {
        return PrivacyOverlay(child: child!);
      },
    );
  }

  // Función que construye el diseño visual de la app (colores, bordes, etc.)
  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark; // ¿Es modo oscuro?
    final primaryColor = const Color(0xFF1A237E); // Color azul marino principal

    return ThemeData(
      useMaterial3: true, // Usa el diseño moderno de Google (Material 3)
      brightness: brightness,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: primaryColor,
        secondary: const Color(0xFF3949AB), // Color secundario para botones
      ),
      // Fondo de la pantalla según el modo
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      
      // Estilo de los cuadros de texto (donde el usuario escribe)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), // Bordes redondeados
          borderSide: BorderSide(color: isDark ? Colors.indigo[300]! : Colors.indigo),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.indigo.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primaryColor, width: 2), // Borde más grueso al escribir
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      
      // Estilo de las tarjetas de ideas
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 4, // Sombra de la tarjeta
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Estilo de los textos
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold, 
          color: isDark ? Colors.white : primaryColor
        ),
        bodyLarge: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
      ),
    );
  }
}
