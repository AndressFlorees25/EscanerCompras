class Producto {
  final String nombre;
  final int precio;
  int cantidad;
  final String? codigo; // código de barras, si se escaneó

  Producto(this.nombre, this.precio, {this.cantidad = 1, this.codigo});

  int get subtotal => precio * cantidad;

  Map<String, dynamic> toJson() =>
      {'nombre': nombre, 'precio': precio, 'cantidad': cantidad, 'codigo': codigo};

  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
        j['nombre'] as String,
        j['precio'] as int,
        cantidad: j['cantidad'] as int? ?? 1,
        codigo: j['codigo'] as String?,
      );
}

/// Una compra terminada, para el historial.
class Compra {
  final DateTime fecha;
  final List<Producto> productos;

  Compra(this.fecha, this.productos);

  int get total => productos.fold(0, (suma, p) => suma + p.subtotal);
  int get unidades => productos.fold(0, (suma, p) => suma + p.cantidad);

  Map<String, dynamic> toJson() => {
        'fecha': fecha.toIso8601String(),
        'productos': productos.map((p) => p.toJson()).toList(),
      };

  factory Compra.fromJson(Map<String, dynamic> j) => Compra(
        DateTime.parse(j['fecha'] as String),
        (j['productos'] as List)
            .map((p) => Producto.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

/// 29/10/2026 14:05
String fechaCorta(DateTime f) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(f.day)}/${dos(f.month)}/${f.year} ${dos(f.hour)}:${dos(f.minute)}';
}

/// Formatea un monto en pesos chilenos: 12990 -> $12.990
String clp(int monto) {
  final s = monto.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${monto < 0 ? '-' : ''}\$$buf';
}
