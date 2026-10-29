import 'package:flutter_test/flutter_test.dart';

import 'package:escaner_compras/main.dart';
import 'package:escaner_compras/modelos.dart';

void main() {
  test('clp formatea con puntos de miles', () {
    expect(clp(0), '\$0');
    expect(clp(1500), '\$1.500');
    expect(clp(1234567), '\$1.234.567');
  });

  testWidgets('muestra el total inicial del carrito', (tester) async {
    await tester.pumpWidget(const EscanerComprasApp());
    expect(find.text('\$3.700'), findsOneWidget); // pan 1500 + 2 leches 2200
  });
}
