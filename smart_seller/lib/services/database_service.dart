import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';

class DatabaseService {
  static late Isar isar;
  
  // Inicializar la base de datos
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    
    isar = await Isar.open(
      [UserSchema],
      directory: dir.path,
    );
    
    // Crear usuario admin por defecto si no existe
    await _createDefaultUser();
  }
  
  // Crear usuario admin por defecto
  static Future<void> _createDefaultUser() async {
    final existingAdmin = await isar.users
        .filter()
        .usernameEqualTo('admin')
        .findFirst();
    
    if (existingAdmin == null) {
      final adminUser = User()
        ..username = 'admin'
        ..password = '123456'
        ..fullName = 'Administrador'
        ..role = UserRole.admin
        ..createdAt = DateTime.now()
        ..isActive = true;
      
      await isar.writeTxn(() async {
        await isar.users.put(adminUser);
      });
      
      print('✅ Usuario admin creado en la base de datos');
    } else {
      print('✅ Usuario admin ya existe en la base de datos');
    }
  }
  
  // Buscar usuario por username y password
  static Future<User?> findUser(String username, String password) async {
    return await isar.users
        .filter()
        .usernameEqualTo(username)
        .and()
        .passwordEqualTo(password)
        .and()
        .isActiveEqualTo(true)
        .findFirst();
  }
  
  // Verificar si un usuario existe por username
  static Future<bool> userExists(String username) async {
    final user = await isar.users
        .filter()
        .usernameEqualTo(username.trim())
        .findFirst();
    return user != null;
  }
  
  // Activar/Desactivar usuario
  static Future<bool> toggleUserStatus(int userId) async {
    try {
      final user = await isar.users.get(userId);
      if (user == null) return false;
      
      // No permitir desactivar al admin
      if (user.username == 'admin' && user.isActive) {
        return false;
      }
      
      // Cambiar el estado
      user.isActive = !user.isActive;
      
      await isar.writeTxn(() async {
        await isar.users.put(user);
      });
      
      return true;
    } catch (e) {
      print('Error al cambiar estado del usuario: $e');
      return false;
    }
  }
  
  // Obtener todos los usuarios
  static Future<List<User>> getAllUsers() async {
    return await isar.users.where().findAll();
  }
  
  // Eliminar usuario
  static Future<bool> deleteUser(int userId) async {
    try {
      final user = await isar.users.get(userId);
      if (user == null) return false;
      
      // No permitir eliminar al admin
      if (user.username == 'admin') {
        return false;
      }
      
      await isar.writeTxn(() async {
        await isar.users.delete(userId);
      });
      
      return true;
    } catch (e) {
      print('Error al eliminar usuario: $e');
      return false;
    }
  }
} 