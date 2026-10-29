import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:escaner_compras/api_productos.dart';

void main() {
  test('devuelve el nombre si Open Food Facts encuentra el producto', () async {
    final cliente = MockClient((_) async => http.Response(
        '{"status":1,"product":{"product_name":"Lucchetti Spaghetti"}}', 200));
    expect(await buscarNombreEnInternet('7802500000053', cliente: cliente), 'Lucchetti Spaghetti');
  });

  test('devuelve null si el producto no existe', () async {
    final cliente = MockClient((_) async => http.Response('{"status":0}', 200));
    expect(await buscarNombreEnInternet('000', cliente: cliente), isNull);
  });

  test('devuelve null si no hay internet', () async {
    final cliente = MockClient((_) async => throw http.ClientException('sin red'));
    expect(await buscarNombreEnInternet('000', cliente: cliente), isNull);
  });
}
