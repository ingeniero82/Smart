import 'package:isar/isar.dart';
import 'product.dart';
import 'user.dart';

part 'inventory_movement.g.dart';

@collection
class InventoryMovement {
  Id id = Isar.autoIncrement;

  // Referencia al producto (en Isar, se usa un link o un Id)
  late int productId;

  // Tipo de movimiento (entrada, salida, ajuste)
  @enumerated
  late MovementType type;

  // Cantidad movida (positiva para entrada, negativa para salida)
  late int quantity;

  // Motivo del movimiento (compra, venta, ajuste manual, etc.)
  @enumerated
  late MovementReason reason;

  // Fecha del movimiento
  late DateTime date;

  // Referencia al usuario (en Isar, se usa un link o un Id)
  late int userId;

  // Observaciones (opcional)
  String? observations;

  // Constructor (opcional, pero útil para crear movimientos rápidamente)
  InventoryMovement({
    required this.productId,
    required this.type,
    required this.quantity,
    required this.reason,
    required this.date,
    required this.userId,
    this.observations,
  });
}

enum MovementType {
  entrada, // (por ejemplo, compra)
  salida,  // (por ejemplo, venta)
  ajuste,  // (ajuste manual, pérdida, etc.)
}

enum MovementReason {
  compra,       // (entrada por compra)
  venta,        // (salida por venta)
  ajusteManual, // (ajuste manual, por ejemplo, inventario físico)
  perdida,      // (ajuste por pérdida o daño)
  devolucion,   // (entrada por devolución de cliente)
  otro,         // (otro motivo)
} 