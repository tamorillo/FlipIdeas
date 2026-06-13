import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../widgets/custom_scaffold.dart';
import '../widgets/custom_button.dart';

/// Pantalla de Ajustes de la aplicación.
/// Permite configurar la seguridad (contraseña para archivar) y ver información del sistema.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _passwordController = TextEditingController();
  bool _isObscured = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _savePassword() {
    final password = _passwordController.text.trim();
    if (password.isNotEmpty) {
      if (password.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La contraseña debe tener al menos 8 caracteres')),
        );
        return;
      }
      context.read<SecurityProvider>().setPassword(password);
      _passwordController.clear();
      FocusScope.of(context).unfocus(); // Cierra el teclado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Contraseña configurada con éxito!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, escribe una contraseña válida')),
      );
    }
  }

  void _removePassword() {
    // Diálogo de confirmación antes de eliminar
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar seguridad?'),
        content: const Text('Ya no se pedirá contraseña al archivar ideas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              context.read<SecurityProvider>().removePassword();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seguridad desactivada')),
              );
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final securityProvider = context.watch<SecurityProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomScaffold(
      title: 'Ajustes',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECCIÓN SEGURIDAD ---
            _buildSectionHeader("SEGURIDAD Y PRIVACIDAD"),
            const SizedBox(height: 20),
            
            Card(
              elevation: 0,
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.indigo[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          securityProvider.isPasswordSet ? Icons.lock_rounded : Icons.lock_open_rounded,
                          color: const Color(0xFF3949AB),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Archivo Seguro",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      securityProvider.isPasswordSet
                          ? "Tu contenido está protegido. Se solicitará la contraseña para archivar nuevas ideas."
                          : "Configura una contraseña para proteger tus ideas al archivarlas.",
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    
                    TextField(
                      controller: _passwordController,
                      obscureText: _isObscured,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: securityProvider.isPasswordSet ? 'Cambiar contraseña' : 'Nueva contraseña',
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _isObscured = !_isObscured),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: securityProvider.isPasswordSet ? 'ACTUALIZAR' : 'ACTIVAR',
                            onPressed: _savePassword,
                          ),
                        ),
                        if (securityProvider.isPasswordSet) ...[
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            onPressed: _removePassword,
                            icon: const Icon(Icons.delete_outline_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- SECCIÓN INFORMACIÓN ---
            _buildSectionHeader("INFORMACIÓN"),
            const SizedBox(height: 20),
            
            _buildInfoTile(Icons.info_outline, "Versión", "1.0"),
            //_buildInfoTile(Icons.code_rounded, "Desarrollado con", "Flutter 3.41.9"),
            _buildInfoTile(Icons.favorite_border_rounded, "Hecho por", "Tamara M."),
            _buildInfoTile(Icons.code_rounded, "Código fuente", "https://github.com/tamorillo/FlipIdeas"),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3949AB),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3949AB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF3949AB)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}
