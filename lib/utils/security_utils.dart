import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';

/// Muestra un diálogo para confirmar la contraseña antes de archivar una idea.
Future<bool> confirmArchivePassword(BuildContext context) async {
  final securityProvider = context.read<SecurityProvider>();
  
  // Si no hay contraseña configurada, permitimos la acción directamente.
  if (!securityProvider.isPasswordSet) return true;

  String inputPassword = '';
  
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false, // Forzamos a elegir una opción
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          return StatefulBuilder(
            builder: (context, setState) {
              String? errorMessage;

              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                title: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: Color(0xFF3949AB)),
                    const SizedBox(width: 10),
                    Text(
                      'Seguridad',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1A237E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Introduce tu contraseña para confirmar esta acción.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      obscureText: true,
                      autofocus: true,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Contraseña',
                        errorText: errorMessage,
                        prefixIcon: const Icon(Icons.password_rounded, size: 20),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.indigo[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        inputPassword = value;
                        if (errorMessage != null) {
                          setState(() => errorMessage = null);
                        }
                      },
                      onSubmitted: (_) {
                        if (securityProvider.checkPassword(inputPassword)) {
                          Navigator.pop(context, true);
                        } else {
                          setState(() => errorMessage = 'Contraseña incorrecta');
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'CANCELAR',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (securityProvider.checkPassword(inputPassword)) {
                        Navigator.pop(context, true);
                      } else {
                        setState(() => errorMessage = 'Contraseña incorrecta');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3949AB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('CONFIRMAR'),
                  ),
                ],
              );
            },
          );
        },
      ) ??
      false;
}
