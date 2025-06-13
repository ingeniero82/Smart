import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement; // ID auto-incremental
  
  @Index(unique: true)
  late String username; // Usuario único
  
  late String password; // Contraseña (en producción se encriptaría)
  
  late String fullName; // Nombre completo
  
  @enumerated
  late UserRole role; // Rol del usuario
  
  late DateTime createdAt; // Fecha de creación
  
  bool isActive = true; // Usuario activo
}

enum UserRole {
  admin,
  cashier,
  manager,
} 