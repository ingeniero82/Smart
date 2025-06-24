import 'package:get/get.dart';
import '../models/permissions.dart';
import '../models/user.dart';

class PermissionsService extends GetxService {
  static PermissionsService get to => Get.find();
  
  // Permisos actuales en memoria
  final RxMap<UserRole, Set<Permission>> _currentPermissions = <UserRole, Set<Permission>>{}.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadDefaultPermissions();
  }
  
  void _loadDefaultPermissions() {
    // Cargar permisos por defecto
    _currentPermissions.value = Map.from(RolePermissions.permissions);
  }
  
  // Obtener permisos actuales
  Map<UserRole, Set<Permission>> get currentPermissions => Map.from(_currentPermissions);
  
  // Verificar si un rol tiene un permiso específico
  bool hasPermission(UserRole role, Permission permission) {
    return _currentPermissions[role]?.contains(permission) ?? false;
  }
  
  // Obtener todos los permisos de un rol
  Set<Permission> getRolePermissions(UserRole role) {
    return Set<Permission>.from(_currentPermissions[role] ?? {});
  }
  
  // Actualizar permisos de un rol específico
  void updateRolePermissions(UserRole role, Set<Permission> permissions) {
    _currentPermissions[role] = Set<Permission>.from(permissions);
  }
  
  // Guardar todos los permisos
  Future<bool> saveAllPermissions(Map<UserRole, Set<Permission>> permissions) async {
    try {
      // Actualizar permisos en memoria
      for (final entry in permissions.entries) {
        _currentPermissions[entry.key] = Set<Permission>.from(entry.value);
      }
      
      // Aquí podrías guardar en SharedPreferences, base de datos local, etc.
      // Por ahora solo mantenemos en memoria
      
      return true;
    } catch (e) {
      print('Error al guardar permisos: $e');
      return false;
    }
  }
  
  // Restaurar permisos por defecto
  void restoreDefaultPermissions() {
    _loadDefaultPermissions();
  }
  
  // Verificar si un rol puede acceder a una sección específica
  bool canAccessSection(UserRole role, String section) {
    switch (section.toLowerCase()) {
      case 'usuarios':
        return hasPermission(role, Permission.viewUsers);
      case 'productos':
        return hasPermission(role, Permission.viewProducts);
      case 'pos':
        return hasPermission(role, Permission.accessPOS);
      case 'inventario':
        return hasPermission(role, Permission.viewInventory);
      case 'reportes':
        return hasPermission(role, Permission.viewReports);
      case 'configuracion':
        return hasPermission(role, Permission.accessSettings);
      case 'clientes':
        return hasPermission(role, Permission.viewClients);
      case 'movimientos':
        return hasPermission(role, Permission.viewMovements);
      case 'ventas':
        return hasPermission(role, Permission.viewSalesHistory);
      default:
        return false;
    }
  }
} 