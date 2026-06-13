import 'package:flutter/material.dart';

// Widget de botón personalizado y reutilizable.
// Se usa para mantener el mismo estilo en toda la aplicación.
class CustomButton extends StatelessWidget {
  final String text; // Texto que muestra el botón
  final VoidCallback onPressed; // Lo que ocurre al pulsarlo
  final Color? color; // Color del botón (opcional)
  final IconData? icon; // Icono opcional al lado del texto

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Si no se pasa color, usa el azul marino por defecto
    final primaryColor = color ?? const Color(0xFF1A237E);
    
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white, // Texto siempre blanco
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Bordes curvos
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0, // Sin sombra
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // El botón solo ocupa el espacio necesario
        children: [
          if (icon != null) ...[ // Si hay icono, lo añade
            Icon(icon, size: 20),
            const SizedBox(width: 8), // Separación entre icono y texto
          ],
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
