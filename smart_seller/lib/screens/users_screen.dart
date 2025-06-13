import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../widgets/user_form_dialog.dart';
import '../widgets/user_edit_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final usersList = await DatabaseService.getAllUsers();
      setState(() {
        users = usersList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Get.snackbar(
        'Error',
        'Error al cargar usuarios: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _openCreateUserDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const UserFormDialog(),
    );

    // Si se creó un usuario, recargar la lista
    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _openEditUserDialog(User user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => UserEditDialog(user: user),
    );

    // Si se editó un usuario, recargar la lista
    if (result == true) {
      _loadUsers();
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    // Confirmar acción
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Confirmar acción'),
        content: Text(
          user.isActive 
            ? '¿Estás seguro de que quieres desactivar a ${user.fullName}?'
            : '¿Estás seguro de que quieres activar a ${user.fullName}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.red : Colors.green,
            ),
            child: Text(
              user.isActive ? 'Desactivar' : 'Activar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await DatabaseService.toggleUserStatus(user.id);
      
      if (success) {
        Get.snackbar(
          'Éxito',
          user.isActive 
            ? 'Usuario ${user.fullName} desactivado correctamente'
            : 'Usuario ${user.fullName} activado correctamente',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: Icon(Icons.check_circle, color: Colors.white),
        );
        
        // Recargar la lista
        _loadUsers();
      } else {
        Get.snackbar(
          'Error',
          user.username == 'admin' 
            ? 'No se puede desactivar al administrador principal'
            : 'No se pudo cambiar el estado del usuario',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al cambiar estado: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteUser(User user) async {
    // No permitir eliminar al admin
    if (user.username == 'admin') {
      Get.snackbar(
        'Error',
        'No se puede eliminar al administrador principal',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Confirmar eliminación con doble confirmación
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('¡Atención!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que quieres eliminar a ${user.fullName}?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Esta acción NO se puede deshacer.',
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 8),
            Text('Se eliminará:'),
            Text('• Usuario: ${user.username}'),
            Text('• Nombre: ${user.fullName}'),
            Text('• Rol: ${_getRoleText(user.role)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await DatabaseService.deleteUser(user.id);
      
      if (success) {
        Get.snackbar(
          'Éxito',
          'Usuario ${user.fullName} eliminado correctamente',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          icon: Icon(Icons.check_circle, color: Colors.white),
        );
        
        // Recargar la lista
        _loadUsers();
      } else {
        Get.snackbar(
          'Error',
          'No se pudo eliminar el usuario',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al eliminar usuario: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.manager:
        return 'Gerente';
      case UserRole.cashier:
        return 'Cajero';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          decoration: BoxDecoration(
            color: const Color(0xFF6C47FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestión de Usuarios',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Administra los usuarios del sistema y sus permisos',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _openCreateUserDialog,
                icon: const Icon(Icons.add, color: Color(0xFF6C47FF)),
                label: const Text(
                  'Nuevo Usuario',
                  style: TextStyle(
                    color: Color(0xFF6C47FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Lista de usuarios
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF6C47FF),
                  ),
                )
              : users.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay usuarios registrados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _UserCard(
                          user: user,
                          onEdit: () {
                            _openEditUserDialog(user);
                          },
                          onToggleStatus: () {
                            _toggleUserStatus(user);
                          },
                          onDelete: () {
                            _deleteUser(user);
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.manager:
        return 'Gerente';
      case UserRole.cashier:
        return 'Cajero';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.manager:
        return Colors.orange;
      case UserRole.cashier:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getRoleColor(user.role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person,
              color: _getRoleColor(user.role),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          
          // Información del usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF22315B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getRoleText(user.role),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getRoleColor(user.role),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.isActive ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: user.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Botones de acción
          Row(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Editar usuario',
              ),
              IconButton(
                onPressed: onToggleStatus,
                icon: Icon(
                  user.isActive ? Icons.block : Icons.check_circle,
                  color: user.isActive ? Colors.red : Colors.green,
                ),
                tooltip: user.isActive ? 'Desactivar usuario' : 'Activar usuario',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Eliminar usuario',
              ),
            ],
          ),
        ],
      ),
    );
  }
} 