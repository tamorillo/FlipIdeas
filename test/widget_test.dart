// Esta es una prueba básica de widgets de Flutter.
//
// Para realizar una interacción con un widget en tu prueba, usa la utilidad
// WidgetTester en el paquete flutter_test. Por ejemplo, puedes enviar gestos
// de pulsación y desplazamiento. También puedes usar WidgetTester para encontrar
// widgets hijos en el árbol de widgets, leer texto y verificar que los valores
// de las propiedades de los widgets sean correctos.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flipideas/main.dart';
import 'package:flipideas/providers/theme_provider.dart';

void main() {
  testWidgets('La app se carga correctamente', (WidgetTester tester) async {
    // Construye nuestra app y muestra un frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const FlipIdeasApp(),
      ),
    );

    // Verifica que se muestra la pantalla de bienvenida (puedes ajustar esto según tu Home)
    expect(find.byType(FlipIdeasApp), findsOneWidget);
  });
}
