import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/inventory_movement.dart';
import '../models/sale.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class SQLiteDatabaseService {
  static Database? _database;
  
  // Inicializar la base de datos
  static Future<void> initialize() async {
    print('🚀 Inicializando base de datos SQLite...');
    // Inicialización para escritorio (Windows, Linux, Mac)
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'smart_seller.db');
    
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    
    print('✅ Base de datos SQLite abierta en: $path');
    
    // Crear usuario admin por defecto
    await _createDefaultUser();
    
    // Listar todos los usuarios para depuración
    await debugListAllUsers();
  }
  
  // Crear las tablas
  static Future<void> _onCreate(Database db, int version) async {
    print('🔧 Creando tablas de la base de datos...');
    
    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        fullName TEXT NOT NULL,
        role TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
    
    // Tabla de productos
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE NOT NULL,
        shortCode TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        cost REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        minStock INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL,
        unit TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        imageUrl TEXT
      )
    ''');
    
    // Tabla de movimientos de inventario
    await db.execute('''
      CREATE TABLE inventory_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        userId INTEGER NOT NULL,
        FOREIGN KEY (productId) REFERENCES products (id),
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');
    
    // Tabla de ventas
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total REAL NOT NULL,
        user TEXT NOT NULL,
        paymentMethod TEXT,
        items TEXT NOT NULL
      )
    ''');
    
    print('✅ Tablas creadas exitosamente');
  }
  
  // Actualizar base de datos
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 Actualizando base de datos de v$oldVersion a v$newVersion');
    // Aquí irían las migraciones futuras
  }
  
  // Crear usuario admin por defecto
  static Future<void> _createDefaultUser() async {
    print('🔧 Verificando si existe usuario admin...');
    
    final adminExists = await _database!.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
    );
    
    if (adminExists.isNotEmpty) {
      print('✅ Usuario admin ya existe, no se crea uno nuevo');
      return;
    }
    
    print('🔧 Creando usuario admin por defecto...');
    await _database!.insert('users', {
      'username': 'admin',
      'password': '123456',
      'fullName': 'Administrador',
      'role': 'admin',
      'createdAt': DateTime.now().toIso8601String(),
      'isActive': 1,
    });
    
    print('✅ Usuario admin creado: admin / 123456');
  }
  
  // ================== USUARIOS ==================
  
  // Buscar usuario por username y password
  static Future<User?> findUser(String username, String password) async {
    print('🔍 Buscando usuario: username="$username", password="$password"');
    
    try {
      final results = await _database!.query(
        'users',
        where: 'username = ? AND password = ? AND isActive = ?',
        whereArgs: [username, password, 1],
      );
      
      if (results.isNotEmpty) {
        final userData = results.first;
        final user = User()
          ..id = userData['id'] as int
          ..username = userData['username'] as String
          ..password = userData['password'] as String
          ..fullName = userData['fullName'] as String
                  ..role = UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == userData['role'],
          orElse: () => UserRole.cashier,
        )
          ..createdAt = DateTime.parse(userData['createdAt'] as String)
          ..isActive = userData['isActive'] == 1;
        
        print('✅ Usuario encontrado: ${user.fullName} (${user.username})');
        return user;
      } else {
        print('❌ Usuario no encontrado o credenciales incorrectas');
        return null;
      }
    } catch (e) {
      print('❌ Error en findUser: $e');
      return null;
    }
  }
  
  // Verificar si un usuario existe por username
  static Future<bool> userExists(String username) async {
    final results = await _database!.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.trim()],
    );
    return results.isNotEmpty;
  }
  
  // Obtener todos los usuarios
  static Future<List<User>> getAllUsers() async {
    final results = await _database!.query('users');
    return results.map((userData) {
      final user = User()
        ..id = userData['id'] as int
        ..username = userData['username'] as String
        ..password = userData['password'] as String
        ..fullName = userData['fullName'] as String
        ..role = UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == userData['role'],
          orElse: () => UserRole.cashier,
        )
        ..createdAt = DateTime.parse(userData['createdAt'] as String)
        ..isActive = userData['isActive'] == 1;
      return user;
    }).toList();
  }
  
  // Crear usuario
  static Future<void> createUser(User user) async {
    await _database!.insert('users', {
      'username': user.username,
      'password': user.password,
      'fullName': user.fullName,
      'role': user.role.toString().split('.').last,
      'createdAt': user.createdAt.toIso8601String(),
      'isActive': user.isActive ? 1 : 0,
    });
  }
  
  // Actualizar usuario
  static Future<void> updateUser(User user) async {
    await _database!.update(
      'users',
      {
        'username': user.username,
        'password': user.password,
        'fullName': user.fullName,
        'role': user.role.toString().split('.').last,
        'isActive': user.isActive ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
  
  // Activar/Desactivar usuario
  static Future<bool> toggleUserStatus(int userId) async {
    try {
      final results = await _database!.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      if (results.isEmpty) return false;
      
      final userData = results.first;
      final isAdmin = userData['username'] == 'admin';
      final isActive = userData['isActive'] == 1;
      
      // No permitir desactivar al admin
      if (isAdmin && isActive) {
        return false;
      }
      
      await _database!.update(
        'users',
        {'isActive': isActive ? 0 : 1},
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      return true;
    } catch (e) {
      print('Error al cambiar estado del usuario: $e');
      return false;
    }
  }
  
  // Eliminar usuario
  static Future<bool> deleteUser(int userId) async {
    try {
      final results = await _database!.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      if (results.isEmpty) return false;
      
      final userData = results.first;
      if (userData['username'] == 'admin') {
        return false;
      }
      
      await _database!.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      
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
      final results = await _database!.query('users');
      print('Total de usuarios en la base de datos: ${results.length}');
      
      for (final userData in results) {
        print('   ID: ${userData['id']}');
        print('   Username: "${userData['username']}"');
        print('   Password: "${userData['password']}"');
        print('   FullName: "${userData['fullName']}"');
        print('   Role: ${userData['role']}');
        print('   Activo: ${userData['isActive']}');
        print('   Creado: ${userData['createdAt']}');
        print('   ---');
      }
    } catch (e) {
      print('❌ Error al listar usuarios: $e');
    }
    print('🔍 === FIN LISTA USUARIOS ===');
  }
  
  // ================== PRODUCTOS ==================
  
  // Obtener todos los productos
  static Future<List<Product>> getAllProducts() async {
    final results = await _database!.query('products', where: 'isActive = ?', whereArgs: [1]);
    return results.map((productData) {
      final product = Product()
        ..id = productData['id'] as int
        ..code = productData['code'] as String
        ..shortCode = productData['shortCode'] as String
        ..name = productData['name'] as String
        ..description = (productData['description'] ?? '') as String
        ..price = productData['price'] as double
        ..cost = productData['cost'] as double
        ..stock = productData['stock'] as int
        ..minStock = productData['minStock'] as int
        ..category = ProductCategory.values.firstWhere(
          (e) => e.toString().split('.').last == productData['category'],
          orElse: () => ProductCategory.otros,
        )
        ..unit = productData['unit'] as String
        ..createdAt = DateTime.parse(productData['createdAt'] as String)
        ..updatedAt = DateTime.parse(productData['updatedAt'] as String)
        ..isActive = productData['isActive'] == 1
        ..imageUrl = productData['imageUrl'] as String?;
      return product;
    }).toList();
  }
  
  // Crear producto
  static Future<void> createProduct(Product product) async {
    await _database!.insert('products', {
      'code': product.code,
      'shortCode': product.shortCode,
      'name': product.name,
      'description': product.description,
      'price': product.price,
      'cost': product.cost,
      'stock': product.stock,
      'minStock': product.minStock,
      'category': product.category.toString().split('.').last,
      'unit': product.unit,
      'createdAt': product.createdAt.toIso8601String(),
      'updatedAt': product.updatedAt.toIso8601String(),
      'isActive': product.isActive ? 1 : 0,
      'imageUrl': product.imageUrl,
    });
  }
  
  // Actualizar producto
  static Future<void> updateProduct(Product product) async {
    await _database!.update(
      'products',
      {
        'code': product.code,
        'shortCode': product.shortCode,
        'name': product.name,
        'description': product.description,
        'price': product.price,
        'cost': product.cost,
        'stock': product.stock,
        'minStock': product.minStock,
        'category': product.category.toString().split('.').last,
        'unit': product.unit,
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': product.isActive ? 1 : 0,
        'imageUrl': product.imageUrl,
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }
  
  // Eliminar producto
  static Future<void> deleteProduct(int id) async {
    await _database!.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // Verificar si existe código de producto
  static Future<bool> existsProductCode(String code, {int? excludeId}) async {
    String whereClause = 'code = ? AND isActive = ?';
    List<dynamic> whereArgs = [code.trim(), 1];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final results = await _database!.query('products', where: whereClause, whereArgs: whereArgs);
    return results.isNotEmpty;
  }
  
  // ================== VENTAS ==================
  
  // Guardar venta
  static Future<void> saveSale(Sale sale) async {
    await _database!.insert('sales', {
      'date': sale.date.toIso8601String(),
      'total': sale.total,
      'user': sale.user,
      'paymentMethod': sale.paymentMethod,
      'items': sale.items.map((item) => {
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'unit': item.unit,
      }).toList().toString(), // Convertir a JSON string
    });

    // Descontar stock de cada producto vendido
    for (final item in sale.items) {
      // Buscar producto por nombre y unidad (ajustar si tienes código único)
      final results = await _database!.query(
        'products',
        where: 'name = ? AND unit = ? AND isActive = 1',
        whereArgs: [item.name, item.unit],
      );
      if (results.isNotEmpty) {
        final productData = results.first;
        int currentStock = productData['stock'] as int;
        int newStock = currentStock - (item.quantity as int);
        if (newStock < 0) newStock = 0;
        await _database!.update(
          'products',
          {'stock': newStock, 'updatedAt': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [productData['id']],
        );
      }
    }
  }
  
  // Obtener historial de ventas
  static Future<List<Sale>> getSales({DateTime? date}) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      whereClause = 'date >= ? AND date < ?';
      whereArgs = [start.toIso8601String(), end.toIso8601String()];
    }
    
    final results = await _database!.query(
      'sales',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );
    
    return results.map((saleData) {
      final sale = Sale()
        ..id = saleData['id'] as int
        ..date = DateTime.parse(saleData['date'] as String)
        ..total = saleData['total'] as double
        ..user = saleData['user'] as String
        ..paymentMethod = saleData['paymentMethod'] as String?
        ..items = []; // TODO: Parsear items desde JSON string
      return sale;
    }).toList();
  }
  
  // ================== MOVIMIENTOS DE INVENTARIO ==================
  
  // Guardar movimiento de inventario
  static Future<void> saveInventoryMovement(InventoryMovement movement) async {
    await _database!.insert('inventory_movements', {
      'productId': movement.productId,
      'type': movement.type.toString().split('.').last,
      'quantity': movement.quantity,
      'reason': movement.reason.toString().split('.').last,
      'observations': movement.observations,
      'date': movement.date.toIso8601String(),
      'userId': movement.userId,
    });
  }
  
  // Obtener movimientos de inventario
  static Future<List<InventoryMovement>> getAllInventoryMovements({
    int? productId,
    MovementType? type,
    MovementReason? reason,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (productId != null) {
      whereClause += 'productId = ?';
      whereArgs.add(productId);
    }
    
    if (type != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'type = ?';
      whereArgs.add(type.toString().split('.').last);
    }
    
    if (reason != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'reason = ?';
      whereArgs.add(reason.toString().split('.').last);
    }
    
    final results = await _database!.query(
      'inventory_movements',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );
    
    return results.map((movementData) {
      final movement = InventoryMovement(
        productId: movementData['productId'] as int,
        type: MovementType.values.firstWhere(
          (e) => e.toString().split('.').last == movementData['type'],
          orElse: () => MovementType.entrada,
        ),
        quantity: movementData['quantity'] as int,
        reason: MovementReason.values.firstWhere(
          (e) => e.toString().split('.').last == movementData['reason'],
          orElse: () => MovementReason.venta,
        ),
        date: DateTime.parse(movementData['date'] as String),
        userId: movementData['userId'] as int,
        observations: movementData['observations'] as String?,
      );
      movement.id = movementData['id'] as int;
      return movement;
    }).toList();
  }
  
  // Cerrar base de datos
  static Future<void> close() async {
    await _database?.close();
  }
} 