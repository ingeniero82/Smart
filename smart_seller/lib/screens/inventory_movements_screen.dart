import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/inventory_movement.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class InventoryMovementsScreen extends StatefulWidget {
  const InventoryMovementsScreen({Key? key}) : super(key: key);

  @override
  State<InventoryMovementsScreen> createState() => _InventoryMovementsScreenState();
}

class _InventoryMovementsScreenState extends State<InventoryMovementsScreen> {
  List<InventoryMovement> _movements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final movements = await DatabaseService.getAllInventoryMovements();
      setState(() {
        _movements = movements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar('Error', 'No se pudo cargar el historial: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Movimientos de Inventario'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _movements.isEmpty
              ? const Center(child: Text('No hay movimientos registrados.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _movements.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final m = _movements[index];
                    return ListTile(
                      leading: Icon(_iconForType(m.type), color: _colorForType(m.type)),
                      title: Text('Producto ID: ${m.productId}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tipo: ${m.type.name} | Motivo: ${m.reason.name}'),
                          Text('Cantidad: ${m.quantity}'),
                          Text('Fecha: ${m.date.toString()}'),
                          Text('Usuario ID: ${m.userId}'),
                          if (m.observations != null && m.observations!.isNotEmpty)
                            Text('Obs: ${m.observations!}'),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  IconData _iconForType(MovementType type) {
    switch (type) {
      case MovementType.entrada:
        return Icons.arrow_downward;
      case MovementType.salida:
        return Icons.arrow_upward;
      case MovementType.ajuste:
        return Icons.sync_alt;
    }
  }

  Color _colorForType(MovementType type) {
    switch (type) {
      case MovementType.entrada:
        return Colors.green;
      case MovementType.salida:
        return Colors.red;
      case MovementType.ajuste:
        return Colors.orange;
    }
  }
} 