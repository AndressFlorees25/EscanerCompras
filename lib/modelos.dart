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
