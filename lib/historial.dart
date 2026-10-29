import 'package:flutter/material.dart';

import 'catalogo.dart';
import 'modelos.dart';

/// Lista de compras anteriores; al tocar una se abre su detalle.
class PantallaHistorial extends StatelessWidget {
  const PantallaHistorial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      // FutureBuilder muestra un "cargando" mientras llegan los datos (async)
      body: FutureBuilder<List<Compra>>(
        future: Catalogo().historial(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final compras = snap.data!;
          if (compras.isEmpty) {
            return const Center(child: Text('Todavía no terminas ninguna compra'));
          }
          final gastoTotal = compras.fold(0, (suma, c) => suma + c.total);
          return ListView(
            children: [
              ListTile(
                title: const Text('Gastado en total'),
                trailing: Text(clp(gastoTotal), style: Theme.of(context).textTheme.titleLarge),
              ),
              const Divider(),
              for (final c in compras)
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text(fechaCorta(c.fecha)),
                  subtitle: Text('${c.unidades} productos'),
                  trailing: Text(clp(c.total)),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PantallaDetalleCompra(compra: c)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class PantallaDetalleCompra extends StatelessWidget {
  final Compra compra;

  const PantallaDetalleCompra({super.key, required this.compra});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(fechaCorta(compra.fecha))),
      body: ListView(
        children: [
          for (final p in compra.productos)
            ListTile(
              title: Text(p.nombre),
              subtitle: Text('${p.cantidad} x ${clp(p.precio)}'),
              trailing: Text(clp(p.subtotal)),
            ),
          const Divider(),
          ListTile(
            title: const Text('Total'),
            trailing: Text(clp(compra.total), style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
    );
  }
}
