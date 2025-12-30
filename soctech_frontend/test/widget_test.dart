import 'package:flutter_test/flutter_test.dart';
import 'package:soctech_frontend/main.dart';

void main() {
  testWidgets('ERP smoke test', (WidgetTester tester) async {
    // Construye la app usando el nombre nuevo: SoctechERP
    await tester.pumpWidget(const SoctechERP());
    
    // Aquí podríamos agregar pruebas reales en el futuro, 
    // por ahora solo verificamos que no explote al iniciar.
  });
}