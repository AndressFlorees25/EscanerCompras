import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:escaner_compras/main.dart';
import 'package:escaner_compras/modelos.dart';

void main() {
  test('clp formatea con puntos de miles', () {
    expect(clp(0), '\$0');
    expect(clp(1500), '\$1.500');
    expect(clp(1234567), '\$1.234.567');
  });

  testWidgets('parte con el carrito vacío', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const EscanerComprasApp());
    await tester.pumpAndSettle();
    expect(find.text('\$0'), findsOneWidget);
    expect(find.text('Escanea o agrega tu primer producto'), findsOneWidget);
  });

  testWidgets('recupera el carrito guardado al abrir la app', (tester) async {
    SharedPreferences.setMockInitialValues({
      'carrito': '[{"nombre":"Espirales","precio":450,"cantidad":3,"codigo":"7802500000053"}]',
      'presupuesto': 10000,
    });
    await tester.pumpWidget(const EscanerComprasApp());
    await tester.pumpAndSettle();
    expect(find.text('Espirales'), findsOneWidget);
    expect(find.text('\$1.350'), findsWidgets); // total y subtotal
  });
}
