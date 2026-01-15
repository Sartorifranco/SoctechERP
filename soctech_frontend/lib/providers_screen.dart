import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({super.key});

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  // CONFIGURACIÓN BLINDADA
  final String baseUrl = 'http://127.0.0.1:5064/api';
  
  List<dynamic> providers = [];
  bool isLoading = true;

  // Controladores para agregar proveedor (Formulario Integrado)
  final _nameController = TextEditingController();
  final _cuitController = TextEditingController(); // Mapea a TaxId
  final _phoneController = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchProviders();
  }

  Future<void> fetchProviders() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/Providers'));
      if (response.statusCode == 200) {
        // Casteo seguro para evitar error "subtype of type"
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        if (mounted) {
          setState(() {
            providers = data;
            isLoading = false;
          });
        }
      } else {
        // Si falla, dejamos lista vacía pero no rompemos la app
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error providers: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> addProvider() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El nombre es obligatorio")));
      return;
    }

    setState(() => isSaving = true);

    // CORRECCIÓN AQUÍ: Usamos los nombres exactos de tu Backend
    final newProvider = {
      "name": _nameController.text,
      "cuit": _cuitController.text,          // Antes decía 'taxId' -> Ahora 'cuit'
      "phoneNumber": _phoneController.text,  // Antes decía 'phone' -> Ahora 'phoneNumber'
      "contactName": "",                     // Agregamos campos vacíos por seguridad
      "email": "",
      "address": "",
      "isActive": true
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Providers'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(newProvider),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Proveedor agregado"), backgroundColor: Colors.green));
          
          _nameController.clear();
          _cuitController.clear();
          _phoneController.clear();
          fetchProviders();
        }
      } else {
        // Muestra el error real del servidor para saber qué falta
        throw Exception("Error del servidor (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuevo Proveedor"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Razón Social / Nombre", icon: Icon(Icons.business)),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cuitController,
                decoration: const InputDecoration(labelText: "CUIT / DNI", icon: Icon(Icons.badge)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Teléfono", icon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: isSaving ? null : addProvider,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Directorio de Proveedores"), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : providers.isEmpty
              ? const Center(child: Text("No hay proveedores registrados."))
              : ListView.builder(
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final p = providers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: const Icon(Icons.business, color: Colors.deepOrange),
                        ),
                        title: Text(p['name'] ?? 'Sin Nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("CUIT: ${p['taxId'] ?? p['cuit'] ?? '-'}"), // Probamos ambas llaves por las dudas
                            if (p['phone'] != null) Text("Tel: ${p['phone']}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}