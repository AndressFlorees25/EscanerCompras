class Producto {
  final String nombre;
  final int precio;
  int cantidad;

  Producto(this.nombre, this.precio, {this.cantidad = 1});

  int get subtotal => precio * cantidad;
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
