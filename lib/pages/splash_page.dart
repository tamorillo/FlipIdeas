import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Espera 1.2 segundos (tiempo más ágil) y luego navega a la Home
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E), // Tu azul marino
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de inicio
            Image.asset(
              'assets/images/logo_inicio.png',
              width: MediaQuery.of(context).size.width * 0.45, // Reducido al 45% para que no se vea tan grande
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.lightbulb,
                color: Colors.white,
                size: 80,
              ),
            ),
            const SizedBox(height: 30),
            // Indicador de carga opcional
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}