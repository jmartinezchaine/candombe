import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:candombe/main.dart';
import 'package:candombe/features/candombe_sequencer/presentation/pages/sequencer_page.dart';

void main() {
  testWidgets('Candombe Play setup smoke test', (WidgetTester tester) async {
    // Inicializar SharedPreferences mock
    SharedPreferences.setMockInitialValues({});

    // Construir la app y disparar un frame
    await tester.pumpWidget(const MyApp());

    // Verificar que se muestra la pantalla de carga inicial o la página principal
    expect(find.byType(SequencerPage), findsOneWidget);

    // Permitir que finalicen las inicializaciones asíncronas simuladas
    await tester.pumpAndSettle();

    // Verificar que el título del proyecto y el estilo se muestran correctamente
    expect(find.textContaining('Candombe Play'), findsOneWidget);
    expect(find.text('Ansina - Ansina Básico'), findsOneWidget);

    // Verificar que se muestran los controles básicos (Matriz / Cascada)
    expect(find.text('Matriz'), findsOneWidget);
    expect(find.text('Cascada'), findsOneWidget);
  });
}
