import 'package:flutter/material.dart';

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
  final List<Producto> _productos = [
    Producto('Pan', 1500),
    Producto('Leche', 1100, cantidad: 2),
  ];
  int _presupuesto = 20000;

  int get _total => _productos.fold(0, (suma, p) => suma + p.subtotal);

  Future<void> _agregarProducto() async {
    final nuevo = await showDialog<Producto>(
      context: context,
      builder: (_) => const DialogoProducto(),
    );
    if (nuevo != null) setState(() => _productos.add(nuevo));
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
    if (valor != null) setState(() => _presupuesto = valor);
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final uso = _presupuesto == 0 ? 0.0 : _total / _presupuesto;
    final excedido = _total > _presupuesto;
    final cerca = !excedido && uso >= 0.8;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi compra')),
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
                        onDismissed: (_) => setState(() => _productos.removeAt(i)),
                        child: ListTile(
                          title: Text(p.nombre),
                          subtitle: Text('${clp(p.precio)} c/u'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: p.cantidad > 1 ? () => setState(() => p.cantidad--) : null,
                              ),
                              Text('${p.cantidad}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => setState(() => p.cantidad++),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarProducto,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }
}

class DialogoProducto extends StatefulWidget {
  const DialogoProducto({super.key});

  @override
  State<DialogoProducto> createState() => _DialogoProductoState();
}

class _DialogoProductoState extends State<DialogoProducto> {
  final _nombre = TextEditingController();
  final _precio = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo producto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Nombre'),
            autofocus: true,
          ),
          TextField(
            controller: _precio,
            decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$ '),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final precio = int.tryParse(_precio.text);
            if (_nombre.text.trim().isEmpty || precio == null) return;
            Navigator.pop(context, Producto(_nombre.text.trim(), precio));
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
