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
  
  // Obtener todos los usuarios
  static Future<List<User>> getAllUsers() async {
    return await isar.users.where().findAll();
  }
} 