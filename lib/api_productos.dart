import 'dart:convert';

import 'package:http/http.dart' as http;

/// Busca el nombre de un producto por su código de barras en Open Food Facts,
/// una base de datos abierta y gratuita (no necesita clave).
/// Devuelve null si no lo encuentra o si no hay internet.
Future<String?> buscarNombreEnInternet(String codigo, {http.Client? cliente}) async {
  final c = cliente ?? http.Client();
  try {
    final url = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$codigo.json',
      {'fields': 'product_name,brands'},
    );
    // Open Food Facts pide identificar la app en el User-Agent
    final resp = await c
        .get(url, headers: {'User-Agent': 'EscanerCompras/0.4 (app de portafolio)'})
        .timeout(const Duration(seconds: 5));
    if (resp.statusCode != 200) return null;

    final datos = jsonDecode(resp.body) as Map<String, dynamic>;
    if (datos['status'] != 1) return null; // 1 = producto encontrado
    final producto = datos['product'] as Map<String, dynamic>;
    final nombre = (producto['product_name'] as String?)?.trim();
    return (nombre == null || nombre.isEmpty) ? null : nombre;
  } catch (_) {
    return null; // sin internet, timeout, respuesta rara: el usuario lo escribe a mano
  } finally {
    if (cliente == null) c.close();
  }
}
