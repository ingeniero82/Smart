import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/inventory_movement.dart';
import '../models/sale.dart';

class DatabaseService {
  static late Isar isar;
  
  // Inicializar la base de datos
  static Future<void> initialize() async {
    print('🚀 Inicializando base de datos...');
    final dir = await getApplicationDocumentsDirectory();
    
    isar = await Isar.open(
      [UserSchema, ProductSchema, InventoryMovementSchema, SaleSchema],
      directory: dir.path,
    );
    
    print('✅ Base de datos abierta en: ${dir.path}');
    
    // Crear usuario admin por defecto (forzado)
    await _createDefaultUser();
    
    // Listar todos los usuarios para depuración
    await debugListAllUsers();
  }
  
  // Crear usuario admin por defecto (solo si no existe)
  static Future<void> _createDefaultUser() async {
    print('🔧 Verificando si existe usuario admin...');
    
    // Verificar si ya existe el admin
    final existingAdmin = await isar.users
        .filter()
        .usernameEqualTo('admin')
        .findFirst();
    
    if (existingAdmin != null) {
      print('✅ Usuario admin ya existe, no se crea uno nuevo');
      return;
    }
    
    print('🔧 Creando usuario admin por defecto...');
    final adminUser = User()
      ..username = 'admin'
      ..password = '123456'
      ..fullName = 'Administrador'
      ..role = UserRole.admin
      ..createdAt = DateTime.now()
      ..isActive = true;

    await isar.writeTxn(() async {
      // Solo crear el admin, NO borrar usuarios existentes
      await isar.users.put(adminUser);
    });

    print('✅ Usuario admin creado: admin / 123456');
  }
  
  // Buscar usuario por username y password
  static Future<User?> findUser(String username, String password) async {
    print('🔍 Buscando usuario: username="$username", password="$password"');
    
    try {
      final user = await isar.users
          .filter()
          .usernameEqualTo(username)
          .and()
          .passwordEqualTo(password)
          .and()
          .isActiveEqualTo(true)
          .findFirst();
      
      if (user != null) {
        print('✅ Usuario encontrado: ${user.fullName} (${user.username})');
      } else {
        print('❌ Usuario no encontrado o credenciales incorrectas');
        
        // Verificar si el usuario existe pero con contraseña diferente
        final userExists = await isar.users
            .filter()
            .usernameEqualTo(username)
            .findFirst();
        
        if (userExists != null) {
          print('⚠️ Usuario existe pero contraseña incorrecta o usuario inactivo');
          print('   Usuario activo: ${userExists.isActive}');
        } else {
          print('⚠️ Usuario no existe en la base de datos');
        }
      }
      
      return user;
    } catch (e) {
      print('❌ Error en findUser: $e');
      return null;
    }
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
  
  // Función temporal para depuración - listar todos los usuarios
  static Future<void> debugListAllUsers() async {
    print('🔍 === LISTANDO TODOS LOS USUARIOS ===');
    try {
      final users = await isar.users.where().findAll();
      print('Total de usuarios en la base de datos: ${users.length}');
      
      for (final user in users) {
        print('   ID: ${user.id}');
        print('   Username: "${user.username}"');
        print('   Password: "${user.password}"');
        print('   FullName: "${user.fullName}"');
        print('   Role: ${user.role}');
        print('   Activo: ${user.isActive}');
        print('   Creado: ${user.createdAt}');
        print('   ---');
      }
    } catch (e) {
      print('❌ Error al listar usuarios: $e');
    }
    print('🔍 === FIN LISTA USUARIOS ===');
  }
  
  // ================== PRODUCTOS ==================
  static Future<List<Product>> getAllProducts() async {
    return await isar.products.where().findAll();
  }

  static Future<void> createProduct(Product product) async {
    await isar.writeTxn(() async {
      await isar.products.put(product);
    });
  }

  static Future<void> updateProduct(Product product) async {
    await isar.writeTxn(() async {
      await isar.products.put(product);
    });
  }

  static Future<void> deleteProduct(int id) async {
    await isar.writeTxn(() async {
      await isar.products.delete(id);
    });
  }
 
  static Future<bool> existsProductCode(String code, {int? excludeId}) async {
    final query = isar.products.filter().codeEqualTo(code.trim()).and().isActiveEqualTo(true);
    final result = await query.findAll();
    if (excludeId != null) {
      return result.any((p) => p.id != excludeId);
    }
    return result.isNotEmpty;
  }

  // Guardar un nuevo movimiento de inventario
  static Future<void> saveInventoryMovement(InventoryMovement movement) async {
    await isar.writeTxn(() async {
      await isar.inventoryMovements.put(movement);
    });
  }

  // Consultar todos los movimientos de inventario (con filtros opcionales)
  static Future<List<InventoryMovement>> getAllInventoryMovements({int? productId, MovementType? type, MovementReason? reason}) async {
    return await isar.inventoryMovements.filter()
      .optional(productId != null, (q) => q.productIdEqualTo(productId!))
      .optional(type != null, (q) => q.typeEqualTo(type!))
      .optional(reason != null, (q) => q.reasonEqualTo(reason!))
      .findAll();
  }

  // Guardar una venta
  static Future<void> saveSale(Sale sale) async {
    await isar.writeTxn(() async {
      await isar.sales.put(sale);
    });
  }

  // Obtener historial de ventas (todas o por fecha)
  static Future<List<Sale>> getSales({DateTime? date}) async {
    if (date == null) {
      return await isar.sales.where().sortByDateDesc().findAll();
    } else {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      return await isar.sales.filter().dateGreaterThan(start, include: true).and().dateLessThan(end).findAll();
    }
  }
} 