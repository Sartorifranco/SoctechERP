import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConsumeStockScreen extends StatefulWidget {
  const ConsumeStockScreen({super.key});

  @override
  State<ConsumeStockScreen> createState() => _ConsumeStockScreenState();
}

class _ConsumeStockScreenState extends State<ConsumeStockScreen> {
  // Ajusta a tu IP si usas Android Emulator (10.0.2.2) o dispositivo real
  final String baseUrl = 'http://localhost:5064/api'; 

  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool isSaving = false;
  
  List<dynamic> products = [];
  List<dynamic> projects = [];
  List<dynamic> warehouses = []; // Necesitamos saber de qué depósito sale (pañol de obra)

  String? selectedProductId;
  String? selectedProjectId;
  String? selectedWarehouseId; // El ID del depósito asociado a la obra
  
  double currentStock = 0;

  @override
  void initState() {
    super.initState();
    loadInitialData(); 
  }

  Future<void> loadInitialData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/Products')),
        http.get(Uri.parse('$baseUrl/Projects')),
        http.get(Uri.parse('$baseUrl/Logistics/warehouses')),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200 && responses[2].statusCode == 200) {
        setState(() {
          products = json.decode(responses[0].body);
          projects = json.decode(responses[1].body);
          warehouses = json.decode(responses[2].body);
        });
      }
    } catch (e) {
      print("Error cargando datos: $e");
    }
  }

  // Al elegir obra, intentamos buscar si tiene un depósito asignado
  void onProjectSelected(String? projectId) {
    if (projectId == null) return;
    setState(() => selectedProjectId = projectId);
    
    // Lógica inteligente: Buscar un depósito que se llame igual a la obra o sea de tipo "Obra"
    // Para este ejemplo, tomamos el primer depósito que NO sea "Principal" como simulación de Obra
    // En producción, Project tendría un campo "WarehouseId"
    final projectWarehouse = warehouses.firstWhere(
      (w) => (w['isMain'] == false), 
      orElse: () => null
    );

    if (projectWarehouse != null) {
      setState(() => selectedWarehouseId = projectWarehouse['id']);
      checkStock(); // Ver stock en ESA obra
    }
  }

  void onProductSelected(String? id) {
    setState(() => selectedProductId = id);
    checkStock();
  }

  Future<void> checkStock() async {
    if (selectedProductId == null || selectedWarehouseId == null) return;
    
    // Consultamos el stock real en ese depósito específico
    try {
      final res = await http.get(Uri.parse('$baseUrl/Logistics/warehouse-inventory/$selectedWarehouseId'));
      if (res.statusCode == 200) {
        List<dynamic> inventory = json.decode(res.body);
        final item = inventory.firstWhere(
          (i) => i['productId'] == selectedProductId, 
          orElse: () => null
        );
        setState(() => currentStock = (item != null) ? (item['quantity'] ?? 0).toDouble() : 0.0);
      }
    } catch(e) { print(e); }
  }

  Future<void> saveConsumption() async {
    if (selectedProductId == null || selectedProjectId == null || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa los campos obligatorios")));
      return;
    }

    if (selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: No se encontró el depósito de esta obra")));
      return;
    }

    double qty = double.tryParse(_quantityController.text) ?? 0;
    if (qty > currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⛔ Stock insuficiente en la obra")));
      return;
    }

    setState(() => isSaving = true);

    // ESTRUCTURA PLANA (Coincide con StockMovementDto del backend)
    final movement = {
      "productId": selectedProductId,
      "branchId": "00000000-0000-0000-0000-000000000000",
      "sourceWarehouseId": selectedWarehouseId, // Sale de la obra
      "projectId": selectedProjectId,           // Imputa costo a la obra
      "movementType": "ProjectConsumption",     // Backend lo convierte a Enum
      "quantity": qty,
      "unitCost": 0, 
      "date": DateTime.now().toIso8601String(),
      "description": _descriptionController.text.isEmpty ? "Consumo Reportado" : _descriptionController.text,
      "reference": "APP-CONSUMO"
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/StockMovements'), // Endpoint correcto
        headers: {"Content-Type": "application/json"},
        body: json.encode(movement),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Consumo registrado con éxito"), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Registrar Consumo"),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // TARJETA DE OBRA
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.business, color: Colors.red[800]), const SizedBox(width: 10), const Text("Ubicación de Trabajo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                    const Divider(),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Seleccionar Obra", border: OutlineInputBorder()),
                      value: selectedProjectId,
                      items: projects.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']))).toList(),
                      onChanged: onProjectSelected,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // TARJETA DE MATERIAL
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.handyman, color: Colors.orange[800]), const SizedBox(width: 10), const Text("Material a Utilizar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                    const Divider(),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Producto", border: OutlineInputBorder()),
                      items: products.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']))).toList(),
                      onChanged: onProductSelected,
                    ),
                    
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Stock en Obra:"),
                          Text("$currentStock u.", style: TextStyle(fontWeight: FontWeight.bold, color: currentStock > 0 ? Colors.green[700] : Colors.red, fontSize: 16)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(labelText: "Cantidad a Consumir", border: OutlineInputBorder(), prefixIcon: Icon(Icons.exposure_minus_1)),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: "Notas (Ej: Pared Norte)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.note)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveConsumption,
                icon: const Icon(Icons.check_circle, size: 28),
                label: const Text("CONFIRMAR CONSUMO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[800], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            )
          ],
        ),
      ),
    );
  }
}