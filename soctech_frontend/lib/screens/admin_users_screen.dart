import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  // Ajusta la IP si es necesario
  final String baseUrl = 'http://127.0.0.1:5064/api/Auth';
  
  List<dynamic> users = [];
  List<dynamic> allModules = []; 
  String? selectedUserId;
  List<String> userEnabledModuleIds = []; 
  
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/users')),
        http.get(Uri.parse('$baseUrl/modules')),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        setState(() {
          users = json.decode(responses[0].body);
          allModules = json.decode(responses[1].body);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error cargando datos: $e")));
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadUserPermissions(String userId) async {
    // No ponemos isLoading global para no bloquear la UI entera, solo el panel derecho si quisiéramos
    try {
      final res = await http.get(Uri.parse('$baseUrl/permissions/$userId'));
      if (res.statusCode == 200) {
        List<dynamic> data = json.decode(res.body);
        setState(() {
          userEnabledModuleIds = data.map((e) => e.toString()).toList();
        });
      }
    } catch (e) {
      print("Error cargando permisos: $e");
    }
  }

  Future<void> _savePermissions() async {
    if (selectedUserId == null) return;
    setState(() => isSaving = true);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/permissions/$selectedUserId'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(userEnabledModuleIds),
      );

      if (res.statusCode == 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Permisos actualizados"), backgroundColor: Colors.green));
      } else {
        throw Exception("Error al guardar");
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => isSaving = false);
    }
  }

  // --- LÓGICA PARA CREAR USUARIO ---
  Future<void> _showCreateUserDialog() async {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = "User"; // Por defecto

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Necesario para actualizar el dropdown dentro del diálogo
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Nuevo Usuario"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: userCtrl, decoration: const InputDecoration(labelText: "Nombre de Usuario", prefixIcon: Icon(Icons.person))),
                  const SizedBox(height: 10),
                  TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Contraseña", prefixIcon: Icon(Icons.lock))),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: "Rol", border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: "User", child: Text("Usuario Estándar")),
                      DropdownMenuItem(value: "Admin", child: Text("Administrador")),
                      DropdownMenuItem(value: "SuperAdmin", child: Text("Super Usuario (Gerente)")),
                    ],
                    onChanged: (val) => setStateDialog(() => selectedRole = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () async {
                    if (userCtrl.text.isEmpty || passCtrl.text.isEmpty) return;
                    Navigator.pop(context); // Cerrar diálogo
                    await _registerUser(userCtrl.text, passCtrl.text, selectedRole);
                  },
                  child: const Text("Crear Usuario"),
                )
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _registerUser(String username, String password, String role) async {
    setState(() => isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "username": username,
          "password": password,
          "role": role
        }),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Usuario creado exitosamente"), backgroundColor: Colors.green));
        _loadInitialData(); // Recargar la lista
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${res.body}"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error de conexión: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _togglePermission(String moduleId, bool? value) {
    setState(() {
      if (value == true) {
        userEnabledModuleIds.add(moduleId);
      } else {
        userEnabledModuleIds.remove(moduleId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Usuarios"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      
      // BOTÓN FLOTANTE PARA CREAR
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: isLoading && users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // --- PANEL IZQUIERDO: LISTA DE USUARIOS ---
                Container(
                  width: 300,
                  color: Colors.grey.shade100,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        color: Colors.grey.shade200,
                        width: double.infinity,
                        child: Text("Usuarios Registrados (${users.length})", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final u = users[index];
                            final isSelected = u['id'] == selectedUserId;
                            return ListTile(
                              title: Text(u['username'], style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              subtitle: Text(u['role'], style: TextStyle(color: u['role'] == 'SuperAdmin' ? Colors.red : Colors.grey)),
                              leading: CircleAvatar(
                                backgroundColor: isSelected ? Colors.indigo : (u['role'] == 'SuperAdmin' ? Colors.redAccent : Colors.grey),
                                child: const Icon(Icons.person, color: Colors.white),
                              ),
                              selected: isSelected,
                              selectedTileColor: Colors.indigo.withOpacity(0.1),
                              onTap: () {
                                setState(() => selectedUserId = u['id']);
                                _loadUserPermissions(u['id']);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                
                // --- PANEL DERECHO: PERMISOS (CHECKS) ---
                Expanded(
                  child: selectedUserId == null
                      ? const Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app, size: 50, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("Seleccione un usuario para editar sus permisos", style: TextStyle(color: Colors.grey)),
                          ],
                        ))
                      : Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(15),
                              color: Colors.indigo.shade50,
                              child: Row(
                                children: [
                                  const Icon(Icons.security, color: Colors.indigo),
                                  const SizedBox(width: 10),
                                  Text("Permisos de Acceso", style: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: isSaving ? null : _savePermissions,
                                    icon: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                                    label: const Text("GUARDAR CAMBIOS"),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  )
                                ],
                              ),
                            ),
                            isLoading 
                              ? const LinearProgressIndicator() 
                              : Expanded(
                                  child: ListView(
                                    padding: const EdgeInsets.all(20),
                                    children: allModules.map((mod) {
                                      final isEnabled = userEnabledModuleIds.contains(mod['id']);
                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.only(bottom: 10),
                                        child: CheckboxListTile(
                                          title: Text(mod['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text("Código interno: ${mod['code']}"),
                                          value: isEnabled,
                                          activeColor: Colors.indigo,
                                          secondary: Icon(Icons.check_circle_outline, color: isEnabled ? Colors.indigo : Colors.grey),
                                          onChanged: (val) => _togglePermission(mod['id'], val),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}