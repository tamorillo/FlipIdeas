import 'dart:ui';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

/// Un widget que envuelve la aplicación y muestra un desenfoque (blur),
/// un degradado de marca y una frase motivadora cuando la aplicación
/// pasa a segundo plano.
class PrivacyOverlay extends StatefulWidget {
  final Widget child;
  /// Permite desactivar el overlay temporalmente (ej: al abrir la galería)
  static bool showOverlay = true;

  const PrivacyOverlay({super.key, required this.child});

  @override
  State<PrivacyOverlay> createState() => _PrivacyOverlayState();
}

class _PrivacyOverlayState extends State<PrivacyOverlay> with WidgetsBindingObserver {
  bool _isPrivacyActive = false;
  late String _currentPhrase;

  final List<String> _phrases = [
    "Tus ideas están a salvo.",
    "Grandes cosas nacen de pequeñas ideas.",
    "Captura el momento, protege tu visión.",
    "La creatividad requiere valentía.",
    "Tus pensamientos, tu privacidad.",
    "Inspiración en pausa...",
    "Diseñando el futuro de tus ideas.",
    "Un respiro para tu creatividad.",
  ];

  @override
  void initState() {
    super.initState();
    _currentPhrase = _phrases[Random().nextInt(_phrases.length)];
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Timer? _privacyTimer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _privacyTimer?.cancel(); // Cancelamos cualquier temporizador previo

    if (state == AppLifecycleState.resumed) {
      setState(() => _isPrivacyActive = false);
    } else if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Si la app pasa a segundo plano o multitarea, esperamos 300ms.
      // Esto es suficiente para que iOS tome la captura de pantalla sin la máscara,
      // pero oculta la app cuando el usuario entra en el "App Switcher".
      _privacyTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isPrivacyActive = PrivacyOverlay.showOverlay;
            _currentPhrase = _phrases[Random().nextInt(_phrases.length)];
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isPrivacyActive)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A237E).withValues(alpha: 0.85), // Azul Marino
                      const Color(0xFF3949AB).withValues(alpha: 0.85), // Indigo
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo con efecto sutil de sombra
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo_inicio.png',
                            width: 160,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.lightbulb_outline,
                              color: Colors.white,
                              size: 80,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Frase motivadora
                        Text(
                          _currentPhrase,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.5,
                            decoration: TextDecoration.none,
                            fontFamily: 'sans-serif',
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Indicador visual de privacidad
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded, 
                                 color: Colors.white.withValues(alpha: 0.7), 
                                 size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "CONTENIDO PRIVADO",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                decoration: TextDecoration.none,
                                fontFamily: 'sans-serif',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
