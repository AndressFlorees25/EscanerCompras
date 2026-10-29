import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda en el teléfono el nombre y el precio de cada código escaneado,
/// para que la segunda vez que escanees un producto se agregue solo.
class Catalogo {
  static const _clave = 'catalogo';

  Future<Map<String, dynamic>?> buscar(String codigo) async {
    final todos = await _leer();
    return todos[codigo] as Map<String, dynamic>?;
  }

  Future<void> guardar(String codigo, String nombre, int precio) async {
    final todos = await _leer();
    todos[codigo] = {'nombre': nombre, 'precio': precio};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, jsonEncode(todos));
  }

  Future<Map<String, dynamic>> _leer() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(_clave);
    return texto == null ? {} : jsonDecode(texto) as Map<String, dynamic>;
  }
}
