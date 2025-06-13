import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class UserEditDialog extends StatefulWidget {
  final User user;
  
  const UserEditDialog({
    super.key,
    required this.user,
  });

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  
  late UserRole _selectedRole;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    // Pre-llenar los campos con los datos existentes
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _usernameController = TextEditingController(text: widget.user.username);
    _passwordController = TextEditingController();
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final username = _usernameController.text.trim();
      
      // Verificar si el usuario cambió y si ya existe
      if (username != widget.user.username) {
        final userExists = await DatabaseService.userExists(username);
        if (userExists) {
          Get.snackbar(
            'Error',
            'El nombre de usuario "$username" ya existe',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Actualizar los datos del usuario
      widget.user.username = username;
      widget.user.fullName = _fullNameController.text.trim();
      widget.user.role = _selectedRole;
      
      // Solo cambiar contraseña si se especificó
      if (_changePassword && _passwordController.text.trim().isNotEmpty) {
        widget.user.password = _passwordController.text.trim();
      }

      // Guardar en la base de datos
      await DatabaseService.isar.writeTxn(() async {
        await DatabaseService.isar.users.put(widget.user);
      });

      Get.snackbar(
        'Éxito',
        'Usuario actualizado correctamente',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Cerrar diálogo y retornar true para indicar que se actualizó
      Get.back(result: true);

    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al actualizar usuario: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Editar Usuario',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF22315B),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Editando: ${widget.user.fullName}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Formulario
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Nombre completo
                  TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre Completo',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF6F8FA),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre completo es obligatorio';
                      }
                      if (value.trim().length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nombre de usuario
                  TextFormField(
                    controller: _usernameController,
                    enabled: widget.user.username != 'admin',
                    decoration: InputDecoration(
                      labelText: 'Nombre de Usuario',
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: widget.user.username == 'admin' 
                          ? Colors.grey[200] 
                          : const Color(0xFFF6F8FA),
                      helperText: widget.user.username == 'admin' 
                          ? 'No se puede cambiar el usuario admin'
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre de usuario es obligatorio';
                      }
                      if (value.trim().length < 3) {
                        return 'El usuario debe tener al menos 3 caracteres';
                      }
                      if (value.contains(' ')) {
                        return 'El usuario no puede contener espacios';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Checkbox para cambiar contraseña
                  CheckboxListTile(
                    title: Text('Cambiar contraseña'),
                    value: _changePassword,
                    onChanged: (value) {
                      setState(() {
                        _changePassword = value ?? false;
                        if (!_changePassword) {
                          _passwordController.clear();
                        }
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  // Campo de contraseña (solo si se quiere cambiar)
                  if (_changePassword) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF6F8FA),
                      ),
                      validator: _changePassword ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La nueva contraseña es obligatoria';
                        }
                        if (value.trim().length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      } : null,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Rol
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Rol del Usuario',
                      prefixIcon: const Icon(Icons.admin_panel_settings),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF6F8FA),
                    ),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(_getRoleText(role)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Get.back(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C47FF),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Actualizar Usuario',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 