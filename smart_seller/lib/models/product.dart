// Modelo de producto sin Isar

class Product {
  int? id;
  late String code;
  late String shortCode;
  late String name;
  late String description;
  late double price;
  late double cost;
  late int stock;
  late int minStock;
  late ProductCategory category;
  late String unit;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool isActive = true;
  String? imageUrl;

  // Campos calculados
  double get profit => price - cost;
  double get profitMargin => cost > 0 ? ((price - cost) / cost) * 100 : 0;
  bool get isLowStock => stock <= minStock;
}

enum ProductCategory {
  frutasVerduras,
  lacteos,
  panaderia,
  carnes,
  bebidas,
  abarrotes,
  limpieza,
  cuidadoPersonal,
  otros,
} 