import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  // 1. CONFIGURACIÓN DE RED SEGURA
  final String baseUrl = 'http://127.0.0.1:5064/api';

  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _referenceController = TextEditingController(); // Para N° de Factura/Remito

  bool isSaving = false;
  bool isLoading = true;
  
  List<dynamic> products = [];
  String? selectedProductId;
  
  // Variables visuales
  double currentStock = 0;
  double currentCost = 0;

  @override
  void initState() {
    super.initState();
    loadProducts(); 
  }

  Future<void> loadProducts() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/Products'));
      
      if (response.statusCode == 200) {
        // 2. DECODIFICACIÓN SEGURA
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        
        if (mounted) {
          setState(() {
            products = data;
            isLoading = false;
          });
        }
      } else {
        throw Exception("Error ${response.statusCode}");
      }
    } catch (e) {
      print("Error cargando productos: $e");
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
      currentStock = (prod['stock'] ?? 0).toDouble();
      currentCost = (prod['costPrice'] ?? 0).toDouble();
      
      // Pre-llenamos el costo
      _costController.text = currentCost.toString();
    });
  }

  Future<void> saveEntry() async {
    if (selectedProductId == null || _quantityController.text.isEmpty || _costController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa todos los campos obligatorios")));
      return;
    }

    setState(() => isSaving = true);

    double quantity = double.tryParse(_quantityController.text) ?? 0;
    double newCost = double.tryParse(_costController.text) ?? 0;

    // 3. OBJETO DE MOVIMIENTO LIMPIO (Sin IDs de empresa conflictivos)
    final movement = {
      "productId": selectedProductId,
      "projectId": null, 
      "movementType": "PURCHASE",
      "quantity": quantity, 
      "unitCost": newCost, 
      "date": DateTime.now().toIso8601String(),
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ ¡Stock ingresado correctamente!"), backgroundColor: Colors.green));
          Navigator.pop(context, true); // Vuelve atrás y avisa que actualice
        }
      } else {
        // Si falla, mostramos el mensaje exacto del servidor para debuguear
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
        title: const Text("Ingresar Mercadería"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // --- PRODUCTO ---
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Producto a Ingresar",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  value: selectedProductId, // Mantiene la selección si recarga
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
                        Text("Stock actual: $currentStock | Costo actual: \$$currentCost", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
                    label: const Text("REGISTRAR INGRESO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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