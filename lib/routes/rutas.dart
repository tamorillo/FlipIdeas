import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/add_edit_idea_page.dart';
import '../pages/splash_page.dart'; // Importamos la nueva pantalla
import '../pages/settings_page.dart'; // Importamos la página de ajustes

/// Configuración del mapa de navegación de la app (GoRouter).
final GoRouter router = GoRouter(
  initialLocation: '/splash', // Ahora la app empieza en el Splash
  routes: [
    // Pantalla de Splash
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    // Pantalla Principal
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    // Pantalla de Ajustes
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    // Pantalla para Añadir una nueva Idea
    GoRoute(
      path: '/add-idea',
      builder: (context, state) => const AddEditIdeaPage(),
    ),
    // Pantalla para Editar una Idea existente (necesita el ID)
    GoRoute(
      path: '/edit-idea/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AddEditIdeaPage(ideaId: id);
      },
    ),
  ],
);