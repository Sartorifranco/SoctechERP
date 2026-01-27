import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  // CONFIGURACIÓN DE RED SEGURA
  final String baseUrl = 'http://127.0.0.1:5064/api';

  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _referenceController = TextEditingController(); // Para N° de Factura/Remito

  bool isSaving = false;
  bool isLoading = true;
  
  List<dynamic> products = [];
  List<dynamic> warehouses = []; // <--- NUEVA LISTA DE DEPÓSITOS
  
  String? selectedProductId;
  String? selectedWarehouseId; // <--- NUEVA SELECCIÓN
  
  // Variables visuales
  double currentStock = 0;
  double currentCost = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); 
  }

  // --- 1. CARGA DE DATOS (Productos + Depósitos) ---
  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/Products')),
        http.get(Uri.parse('$baseUrl/Logistics/warehouses')), // Endpoint Nuevo
      ]);
      
      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final List<dynamic> productsData = json.decode(responses[0].body);
        final List<dynamic> warehousesData = json.decode(responses[1].body);
        
        if (mounted) {
          setState(() {
            products = productsData;
            warehouses = warehousesData;
            
            // Auto-seleccionar el Depósito Principal si existe
            try {
              final mainWarehouse = warehouses.firstWhere((w) => w['isMain'] == true, orElse: () => null);
              if (mainWarehouse != null) {
                selectedWarehouseId = mainWarehouse['id'];
              } else if (warehouses.isNotEmpty) {
                selectedWarehouseId = warehouses.first['id'];
              }
            } catch (_) {}
            
            isLoading = false;
          });
        }
      } else {
        throw Exception("Error cargando datos del servidor");
      }
    } catch (e) {
      print("Error cargando datos: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error de conexión: $e")));
      }
    }
  }

  void onProductSelected(String? id) {
    if (id == null) return;
    
    final prod = products.firstWhere((p) => p['id'] == id);
    setState(() {
      selectedProductId = id;
      // OJO: Este stock es el "Global", después haremos que muestre el stock por depósito si quieres hilar fino
      currentStock = (prod['stock'] ?? 0).toDouble();
      currentCost = (prod['costPrice'] ?? 0).toDouble();
      
      // Pre-llenamos el costo
      _costController.text = currentCost.toString();
    });
  }

  Future<void> saveEntry() async {
    if (selectedProductId == null || selectedWarehouseId == null || _quantityController.text.isEmpty || _costController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa todos los campos obligatorios (Producto, Depósito, Cantidad)")));
      return;
    }

    setState(() => isSaving = true);

    double quantity = double.tryParse(_quantityController.text) ?? 0;
    double newCost = double.tryParse(_costController.text) ?? 0;

    // 3. OBJETO DE MOVIMIENTO ENTERPRISE (Con Depósito de Destino)
    final movement = {
      "productId": selectedProductId,
      "branchId": "00000000-0000-0000-0000-000000000000", // Branch Dummy si se requiere
      "projectId": null, 
      "projectPhaseId": null,
      
      // --- NUEVO: INFORMACIÓN LOGÍSTICA ---
      "sourceWarehouseId": null, // Viene de afuera (Proveedor)
      "targetWarehouseId": selectedWarehouseId, // Va a este depósito
      // ------------------------------------

      "movementType": "PURCHASE",
      "quantity": quantity, 
      "unitCost": newCost, 
      "date": DateTime.now().toIso8601String(),
      "description": "Ingreso de Mercadería",
      "reference": _referenceController.text.isEmpty ? "Ingreso Manual" : _referenceController.text
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/StockMovements'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(movement),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ ¡Stock ingresado al Depósito correctamente!"), backgroundColor: Colors.green));
          Navigator.pop(context, true); // Vuelve atrás y avisa que actualice
        }
      } else {
        throw Exception("Error del servidor (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ingresar Mercadería (Multi-Depósito)"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SECCIÓN 1: UBICACIÓN DE DESTINO (NUEVO) ---
                const Text("Ubicación de Destino", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Seleccionar Depósito / Obra",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.warehouse),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  value: selectedWarehouseId,
                  items: warehouses.map<DropdownMenuItem<String>>((wh) {
                    return DropdownMenuItem<String>(
                      value: wh['id'],
                      child: Text(wh['name'] + (wh['isMain'] ? " (Principal)" : "")),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedWarehouseId = val),
                ),
                
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // --- SECCIÓN 2: PRODUCTO ---
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Producto a Ingresar",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  value: selectedProductId, 
                  items: products.map<DropdownMenuItem<String>>((prod) {
                    return DropdownMenuItem<String>(
                      value: prod['id'],
                      child: Text(prod['name']),
                    );
                  }).toList(),
                  onChanged: onProductSelected,
                ),
                const SizedBox(height: 10),
                
                // --- INFO STOCK ---
                if (selectedProductId != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200)
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 10),
                        // Nota visual para el usuario
                        Expanded(child: Text("Stock Global: $currentStock | Costo PPP: \$$currentCost", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // --- FILA DE DATOS ---
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Cantidad",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.add_box),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _costController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: "Costo Unitario",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                          helperText: "Actualiza el PPP"
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- REFERENCIA ---
                TextField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: "Referencia / Factura N°",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.receipt_long),
                  ),
                ),
                const SizedBox(height: 30),

                // --- BOTÓN ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : saveEntry,
                    icon: isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Icon(Icons.save_alt),
                    label: const Text("REGISTRAR ENTRADA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700], 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                  ),
                )
              ],
            ),
          ),
    );
  }
}