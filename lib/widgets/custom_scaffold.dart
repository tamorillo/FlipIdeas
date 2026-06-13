import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

// Un "Scaffold" personalizado que envuelve todas las pantallas de la app.
// Proporciona el fondo con degradado y la barra superior estilizada.
class CustomScaffold extends StatelessWidget {
  final Widget body; // El contenido principal de la pantalla
  final bool showBackButton; // Si debe mostrar la flecha de atrás
  final String? title; // Título de la pantalla (si es nulo, muestra el logo)
  final Widget? floatingActionButton; // Botón flotante opcional

  const CustomScaffold({
    super.key,
    required this.body,
    this.showBackButton = true,
    this.title,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    
    // Colores base para el degradado
    final primaryColor = const Color(0xFF1A237E); // Azul Marino oscuro
    final secondaryColor = const Color(0xFF3949AB); // Indigo

    return Scaffold(
      appBar: AppBar(
        // Configura el botón de atrás
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                tooltip: 'Volver',
              )
            : null,
        // Configura el título o el logo en el centro
        title: title != null 
          ? Text(title!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          : Image.asset(
                'assets/images/nuevo_logo.png',
                height: 40,
                fit: BoxFit.contain,
                // Si la imagen falla, muestra una bombilla blanca
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.lightbulb, color: Colors.white, size: 30),
              ),
        centerTitle: true,
        actions: [
          // Botón de Ajustes
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => context.push('/settings'),
            tooltip: 'Ajustes',
          ),
          // Botón para cambiar entre Sol (modo claro) y Luna (modo oscuro)
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              color: Colors.white,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Cambiar tema',
          ),
        ],
        backgroundColor: primaryColor,
        elevation: 0,
        // Aplica el degradado azul a la barra superior
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      // Cuerpo de la pantalla con un fondo degradado suave
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF121212), const Color(0xFF0A0A0A)] // Fondo oscuro más profundo al final
              : [const Color(0xFFE8EAF6), Colors.white], // Fondo claro azulado
          ),
        ),
        // Crea una zona con esquinas redondeadas en la parte superior del contenido
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : Colors.white.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: body, // Aquí se inyecta el contenido de cada pantalla
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
