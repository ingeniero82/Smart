import 'package:isar/isar.dart';

part 'product.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement; // ID auto-incremental
  
  @Index(unique: true)
  late String code; // Código de barras único
  
  @Index(unique: true)
  late String shortCode; // Código corto único y obligatorio
  
  late String name; // Nombre del producto
  
  late String description; // Descripción del producto
  
  late double price; // Precio de venta
  
  late double cost; // Costo del producto
  
  late int stock; // Cantidad en inventario
  
  late int minStock; // Stock mínimo (para alertas)
  
  @enumerated
  late ProductCategory category; // Categoría del producto
  
  late String unit; // Unidad de medida (kg, litro, unidad, etc.)
  
  late DateTime createdAt; // Fecha de creación
  
  late DateTime updatedAt; // Fecha de última actualización
  
  bool isActive = true; // Producto activo/inactivo
  
  String? imageUrl; // URL de imagen del producto (opcional)
  
  // Campos calculados
  double get profit => price - cost; // Ganancia por unidad
  double get profitMargin => cost > 0 ? ((price - cost) / cost) * 100 : 0; // Margen de ganancia %
  bool get isLowStock => stock <= minStock; // Alerta de stock bajo
}

enum ProductCategory {
  frutasVerduras,    // Frutas y Verduras
  lacteos,           // Lácteos
  panaderia,         // Panadería
  carnes,            // Carnes
  bebidas,           // Bebidas
  abarrotes,         // Abarrotes
  limpieza,          // Productos de limpieza
  cuidadoPersonal,   // Cuidado personal
  otros,             // Otros
} 