import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  // Ajustado para Windows.
  final String baseUrl = 'http://localhost:5064/api';

  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _referenceController = TextEditingController();

  bool isSaving = false;
  bool isLoading = true;

  List<dynamic> products = [];
  List<dynamic> warehouses = [];

  String? selectedProductId;
  String? selectedWarehouseId;

  // Variables visuales
  double currentStock = 0;
  double currentCost = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Lectura segura de datos (evita errores nulos)
  String _safeString(dynamic item, String key) {
    if (item == null) return "";
    return item[key] ?? item[key[0].toUpperCase() + key.substring(1)] ?? "";
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/Products')),
        http.get(Uri.parse('$baseUrl/Logistics/warehouses')),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final List<dynamic> productsData = json.decode(responses[0].body);
        final List<dynamic> warehousesData = json.decode(responses[1].body);

        if (mounted) {
          setState(() {
            products = productsData;
            warehouses = warehousesData;

            // Auto-seleccionar el Depósito Principal
            try {
              if (warehouses.isNotEmpty) {
                final main = warehouses.firstWhere(
                  (w) => (w['isMain'] ?? w['IsMain'] ?? false) == true,
                  orElse: () => warehouses.first
                );
                selectedWarehouseId = _safeString(main, 'id');
              }
            } catch (e) {
              print("Error auto-seleccionando depósito: $e");
            }

            isLoading = false;
          });
        }
      } else {
        throw Exception("Error del servidor: ${responses[1].statusCode}");
      }
    } catch (e) {
      print("Error cargando datos: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void onProductSelected(String? id) {
    if (id == null) return;

    final prod = products.firstWhere((p) => _safeString(p, 'id') == id, orElse: () => null);

    if (prod != null) {
      setState(() {
        selectedProductId = id;
        currentStock = (prod['stock'] ?? prod['Stock'] ?? 0).toDouble();
        currentCost = (prod['costPrice'] ?? prod['CostPrice'] ?? 0).toDouble();
        _costController.text = currentCost.toString();
      });
    }
  }

  Future<void> saveEntry() async {
    if (selectedProductId == null || selectedWarehouseId == null || _quantityController.text.isEmpty || _costController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa todos los campos obligatorios")));
      return;
    }

    setState(() => isSaving = true);

    double quantity = double.tryParse(_quantityController.text) ?? 0;
    double newCost = double.tryParse(_costController.text) ?? 0;

    final movement = {
      "productId": selectedProductId,
      "branchId": "00000000-0000-0000-0000-000000000000",
      "targetWarehouseId": selectedWarehouseId,
      // CAMBIO IMPORTANTE: Enviamos "Purchase" (no "PURCHASE") para coincidir con C#
      "movementType": "Purchase", 
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Stock ingresado correctamente"), backgroundColor: Colors.green));
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
      appBar: AppBar(title: const Text("Ingresar Stock"), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Destino", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                  value: selectedWarehouseId,
                  items: warehouses.map<DropdownMenuItem<String>>((wh) {
                    final name = _safeString(wh, 'name').isEmpty ? 'Depósito sin nombre' : _safeString(wh, 'name');
                    final isMain = (wh['isMain'] ?? wh['IsMain'] ?? false) == true;
                    return DropdownMenuItem(value: _safeString(wh, 'id'), child: Text("$name${isMain ? ' (Principal)' : ''}"));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedWarehouseId = val),
                ),
                
                const SizedBox(height: 20),
                const Text("Producto", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 5),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                  value: selectedProductId,
                  items: products.map<DropdownMenuItem<String>>((prod) {
                    final name = _safeString(prod, 'name').isEmpty ? 'Producto sin nombre' : _safeString(prod, 'name');
                    return DropdownMenuItem(value: _safeString(prod, 'id'), child: Text(name));
                  }).toList(),
                  onChanged: onProductSelected,
                ),

                const SizedBox(height: 10),
                if (selectedProductId != null)
                  Text("Stock Actual: $currentStock | Costo Ref: \$$currentCost", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Cantidad", border: OutlineInputBorder()))),
                    const SizedBox(width: 15),
                    Expanded(child: TextField(controller: _costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Costo Unitario", border: OutlineInputBorder()))),
                  ],
                ),
                
                const SizedBox(height: 15),
                TextField(controller: _referenceController, decoration: const InputDecoration(labelText: "N° Factura / Remito", border: OutlineInputBorder())),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : saveEntry,
                    icon: const Icon(Icons.save),
                    label: const Text("GUARDAR ENTRADA"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                  ),
                )
              ],
            ),
          ),
    );
  }
}