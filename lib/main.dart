import 'package:flutter/material.dart';

import 'api_productos.dart';
import 'catalogo.dart';
import 'escaner.dart';
import 'historial.dart';
import 'modelos.dart';

void main() => runApp(const EscanerComprasApp());

class EscanerComprasApp extends StatelessWidget {
  const EscanerComprasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Escáner de Compras',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      home: const PantallaCarrito(),
    );
  }
}

class PantallaCarrito extends StatefulWidget {
  const PantallaCarrito({super.key});

  @override
  State<PantallaCarrito> createState() => _PantallaCarritoState();
}

class _PantallaCarritoState extends State<PantallaCarrito> {
  final List<Producto> _productos = [];
  int _presupuesto = 20000;
  final _catalogo = Catalogo();

  int get _total => _productos.fold(0, (suma, p) => suma + p.subtotal);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final guardado = await _catalogo.cargarCarrito();
    if (!mounted) return;
    setState(() {
      _productos.addAll(guardado.productos);
      _presupuesto = guardado.presupuesto ?? _presupuesto;
    });
  }

  /// Aplica un cambio en pantalla y guarda el carrito en el teléfono,
  /// así no se pierde la lista si se cierra la app.
  void _cambiar(VoidCallback cambio) {
    setState(cambio);
    _catalogo.guardarCarrito(_productos, _presupuesto);
  }

  Future<void> _vaciar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Vaciar el carrito?'),
        content: const Text('Se borran todos los productos de esta compra.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vaciar')),
        ],
      ),
    );
    if (ok == true) _cambiar(_productos.clear);
  }

  Future<void> _terminarCompra() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Terminar la compra?'),
        content: Text('Se guarda en el historial por ${clp(_total)} y el carrito queda vacío.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Terminar')),
        ],
      ),
    );
    if (ok != true) return;
    await _catalogo.agregarAlHistorial(Compra(DateTime.now(), List.of(_productos)));
    _cambiar(_productos.clear);
    if (mounted) _avisar('Compra guardada en el historial');
  }

  Future<void> _escanear() async {
    final codigo = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PantallaEscaner()),
    );
    if (codigo == null || !mounted) return;

    // Si ya está en el carrito, solo sumamos uno más
    final enCarrito = _productos.where((p) => p.codigo == codigo).firstOrNull;
    if (enCarrito != null) {
      _cambiar(() => enCarrito.cantidad++);
      _avisar('${enCarrito.nombre}: ahora llevas ${enCarrito.cantidad}');
      return;
    }

    // Si ya lo escaneaste antes, lo agregamos con el nombre y precio guardados
    final conocido = await _catalogo.buscar(codigo);
    if (conocido != null) {
      _cambiar(() => _productos.add(
          Producto(conocido['nombre'] as String, conocido['precio'] as int, codigo: codigo)));
      _avisar('${conocido['nombre']} agregado');
      return;
    }

    // Producto nuevo: buscamos el nombre en internet y pedimos el precio
    if (!mounted) return;
    _avisar('Buscando el producto en internet...');
    final nombreSugerido = await buscarNombreEnInternet(codigo);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final nuevo = await showDialog<Producto>(
      context: context,
      builder: (_) => DialogoProducto(codigo: codigo, nombreInicial: nombreSugerido),
    );
    if (nuevo == null) return;
    await _catalogo.guardar(codigo, nuevo.nombre, nuevo.precio);
    _cambiar(() => _productos.add(nuevo));
  }

  void _avisar(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _agregarProducto() async {
    final nuevo = await showDialog<Producto>(
      context: context,
      builder: (_) => const DialogoProducto(),
    );
    if (nuevo != null) _cambiar(() => _productos.add(nuevo));
  }

  Future<void> _editarPresupuesto() async {
    final ctrl = TextEditingController(text: '$_presupuesto');
    final valor = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Presupuesto'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(prefixText: '\$ '),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (valor != null) _cambiar(() => _presupuesto = valor);
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final uso = _presupuesto == 0 ? 0.0 : _total / _presupuesto;
    final excedido = _total > _presupuesto;
    final cerca = !excedido && uso >= 0.8;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi compra'),
        actions: [
          if (_productos.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Vaciar carrito',
              onPressed: _vaciar,
            ),
            IconButton(
              icon: const Icon(Icons.check_circle),
              tooltip: 'Terminar compra',
              onPressed: _terminarCompra,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PantallaHistorial()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Resumen: total y presupuesto
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.labelLarge),
                  Text(clp(_total), style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: uso.clamp(0, 1),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                    color: excedido ? colores.error : (cerca ? Colors.orange : colores.primary),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _editarPresupuesto,
                    child: Text(
                      excedido
                          ? 'Te pasaste por ${clp(_total - _presupuesto)} del presupuesto (${clp(_presupuesto)})'
                          : 'Te quedan ${clp(_presupuesto - _total)} de ${clp(_presupuesto)}  ✏️',
                      style: TextStyle(color: excedido ? colores.error : null),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Lista de productos
          Expanded(
            child: _productos.isEmpty
                ? const Center(child: Text('Escanea o agrega tu primer producto'))
                : ListView.builder(
                    itemCount: _productos.length,
                    itemBuilder: (_, i) {
                      final p = _productos[i];
                      return Dismissible(
                        key: ObjectKey(p),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: colores.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete),
                        ),
                        onDismissed: (_) => _cambiar(() => _productos.removeAt(i)),
                        child: ListTile(
                          title: Text(p.nombre),
                          subtitle: Text('${clp(p.precio)} c/u'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: p.cantidad > 1 ? () => _cambiar(() => p.cantidad--) : null,
                              ),
                              Text('${p.cantidad}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => _cambiar(() => p.cantidad++),
                              ),
                              SizedBox(
                                width: 72,
                                child: Text(clp(p.subtotal), textAlign: TextAlign.right),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'agregar',
            onPressed: _agregarProducto,
            tooltip: 'Agregar a mano',
            child: const Icon(Icons.edit),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'escanear',
            onPressed: _escanear,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Escanear'),
          ),
        ],
      ),
    );
  }
}

class DialogoProducto extends StatefulWidget {
  final String? codigo;
  final String? nombreInicial; // sugerido desde internet

  const DialogoProducto({super.key, this.codigo, this.nombreInicial});

  @override
  State<DialogoProducto> createState() => _DialogoProductoState();
}

class _DialogoProductoState extends State<DialogoProducto> {
  late final _nombre = TextEditingController(text: widget.nombreInicial);
  final _precio = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo producto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.codigo != null)
            Text('Código: ${widget.codigo}', style: Theme.of(context).textTheme.bodySmall),
          if (widget.nombreInicial != null)
            Text('✨ Nombre encontrado en internet',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
          TextField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Nombre'),
            autofocus: widget.nombreInicial == null,
          ),
          TextField(
            controller: _precio,
            decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$ '),
            keyboardType: TextInputType.number,
            autofocus: widget.nombreInicial != null, // si ya hay nombre, vamos directo al precio
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final precio = int.tryParse(_precio.text);
            if (_nombre.text.trim().isEmpty || precio == null) return;
            Navigator.pop(context, Producto(_nombre.text.trim(), precio, codigo: widget.codigo));
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
