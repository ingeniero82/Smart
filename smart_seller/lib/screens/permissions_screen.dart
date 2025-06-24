import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/permissions.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C47FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Permisos',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22315B),
                      ),
                    ),
                    Text(
                      'Configuración de roles y permisos del sistema',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Información del usuario actual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Usuario Actual',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF22315B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF6C47FF).withOpacity(0.1),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF6C47FF),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(() => Text(
                              AuthService.to.currentUserName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                            Obx(() => Text(
                              AuthService.to.currentUserRole,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Tabla de permisos por rol
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Permisos por Rol',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22315B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _PermissionsTable(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionsTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.withOpacity(0.2),
        width: 1,
      ),
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
      },
      children: [
        // Header de la tabla
        TableRow(
          decoration: BoxDecoration(
            color: const Color(0xFF6C47FF).withOpacity(0.1),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Permiso',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22315B),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Admin',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22315B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Gerente',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22315B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Cajero',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22315B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        
        // Filas de permisos
        ...Permission.values.map((permission) => TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                RolePermissions.getPermissionDescription(permission),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            _PermissionCell(
              hasPermission: RolePermissions.hasPermission(UserRole.admin, permission),
            ),
            _PermissionCell(
              hasPermission: RolePermissions.hasPermission(UserRole.manager, permission),
            ),
            _PermissionCell(
              hasPermission: RolePermissions.hasPermission(UserRole.cashier, permission),
            ),
          ],
        )).toList(),
      ],
    );
  }
}

class _PermissionCell extends StatelessWidget {
  final bool hasPermission;

  const _PermissionCell({required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Icon(
          hasPermission ? Icons.check_circle : Icons.cancel,
          color: hasPermission ? Colors.green : Colors.red,
          size: 20,
        ),
      ),
    );
  }
} 