import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({super.key});

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> {
  final String baseUrl = 'http://127.0.0.1:5064/api/Logistics'; 
  
  List<dynamic> warehouses = [];
  // Cache para guardar el inventario de cada depósito y no recargar siempre
  Map<String, List<dynamic>> inventoryCache = {}; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/warehouses'));
      if (response.statusCode == 200) {
        setState(() {
          warehouses = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- NUEVA FUNCIÓN: CARGAR INVENTARIO DE UN DEPÓSITO ---
  Future<void> _loadInventory(String warehouseId) async {
    // Si ya lo tenemos en memoria, no lo cargamos de nuevo (opcional)
    // if (inventoryCache.containsKey(warehouseId)) return; 

    try {
      final response = await http.get(Uri.parse('$baseUrl/warehouse-inventory/$warehouseId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          inventoryCache[warehouseId] = data;
        });
      }
    } catch (e) {
      print("Error cargando inventario: $e");
    }
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final locCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuevo Depósito / Ubicación"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre (Ej: Obra Torre A)", prefixIcon: Icon(Icons.store)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: locCtrl,
              decoration: const InputDecoration(labelText: "Dirección / Ubicación", prefixIcon: Icon(Icons.map)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty) {
                Navigator.pop(context);
                await _createWarehouse(nameCtrl.text, locCtrl.text);
              }
            },
            child: const Text("Crear"),
          )
        ],
      ),
    );
  }

  Future<void> _createWarehouse(String name, String location) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/warehouses'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "name": name,
          "location": location,
          "isMain": false,
          "isActive": true
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Depósito creado"), backgroundColor: Colors.green));
        _loadWarehouses(); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Depósitos y Existencias"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : warehouses.isEmpty
              ? const Center(child: Text("No hay depósitos registrados"))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: warehouses.length,
                  itemBuilder: (context, index) {
                    final w = warehouses[index];
                    final String wId = w['id'];
                    final List<dynamic>? inventory = inventoryCache[wId];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ExpansionTile(
                        // Al expandir, cargamos los datos
                        onExpansionChanged: (isOpen) {
                          if (isOpen) _loadInventory(wId);
                        },
                        leading: CircleAvatar(
                          backgroundColor: w['isMain'] ? Colors.green : Colors.blue.shade100,
                          child: Icon(Icons.warehouse, color: w['isMain'] ? Colors.white : Colors.indigo),
                        ),
                        title: Text(w['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(w['location'] ?? "Sin ubicación"),
                        children: [
                          const Divider(),
                          // LISTA DE MATERIALES DENTRO DEL DEPÓSITO
                          if (inventory == null)
                            const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          else if (inventory.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text("Depósito Vacío", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                            )
                          else
                            Container(
                              height: 200, // Limitamos altura para scroll interno
                              color: Colors.grey.shade50,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(10),
                                itemCount: inventory.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final item = inventory[i];
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey),
                                    title: Text(item['product'], style: const TextStyle(fontWeight: FontWeight.w500)),
                                    subtitle: Text("SKU: ${item['sku']}"),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(10)
                                      ),
                                      child: Text(
                                        "${item['quantity']}", // Cantidad
                                        style: TextStyle(color: Colors.indigo.shade900, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          // BOTÓN DE ACCIÓN RÁPIDA (Opcional)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.list_alt, size: 16),
                                  label: const Text("Ver Auditoría Completa"),
                                  onPressed: () {
                                    // A futuro: Navegar a historial filtrado por este depósito
                                  },
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}