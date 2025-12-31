import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _quantityController = TextEditingController();
  final _costController = TextEditingController(); // Nuevo: Para actualizar el precio de costo
  bool isSaving = false;
  
  List<dynamic> products = [];
  String? selectedProductId;
  
  // Variables para mostrar info del producto seleccionado
  double currentStock = 0;
  double currentCost = 0;

  @override
  void initState() {
    super.initState();
    loadProducts(); 
  }

  Future<void> loadProducts() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/Products'));
      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body);
        });
      }
    } catch (e) {
      print("Error cargando productos: $e");
    }
  }

  // Al seleccionar un producto, actualizamos los campos
  void onProductSelected(String? id) {
    if (id == null) return;
    
    final prod = products.firstWhere((p) => p['id'] == id);
    setState(() {
      selectedProductId = id;
      currentStock = (prod['stock'] ?? 0).toDouble();
      currentCost = (prod['costPrice'] ?? 0).toDouble();
      
      // Pre-llenamos el costo con el valor actual (por si no cambió)
      _costController.text = currentCost.toString();
    });
  }

  Future<void> saveEntry() async {
    if (selectedProductId == null || _quantityController.text.isEmpty || _costController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa todos los campos")));
      return;
    }

    setState(() => isSaving = true);

    // IDs DE EMPRESA (Hardcodeados por ahora)
    const String companyId = "3fa85f64-5717-4562-b3fc-2c963f66afa6"; 
    const String branchId = "9c9d8c46-970e-4647-83e9-8c084f771982"; 

    double quantity = double.tryParse(_quantityController.text) ?? 0;
    double newCost = double.tryParse(_costController.text) ?? 0;

    // Movimiento de COMPRA (PURCHASE)
    final movement = {
      "companyId": companyId,
      "branchId": branchId,
      "productId": selectedProductId,
      "projectId": null, // En una compra, no va a una obra específica todavía
      "movementType": "PURCHASE",
      "quantity": quantity, // Positivo porque entra
      "unitCost": newCost, 
      "date": DateTime.now().toIso8601String(),
      "reference": "Compra de Materiales"
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5064/api/StockMovements'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(movement),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Stock actualizado correctamente!")));
          Navigator.pop(context, true); 
        }
      } else {
        throw Exception("Error ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ingresar Mercadería"),
        backgroundColor: Colors.green[700], // Verde porque entra dinero/material
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- DROPDOWN PRODUCTOS ---
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Producto a Ingresar",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              items: products.map<DropdownMenuItem<String>>((prod) {
                return DropdownMenuItem<String>(
                  value: prod['id'],
                  child: Text(prod['name']),
                );
              }).toList(),
              onChanged: onProductSelected,
            ),
            const SizedBox(height: 10),
            
            // Info rápida del stock actual
            if (selectedProductId != null)
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 10),
                    Text("Stock actual: $currentStock unidades"),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            Row(
              children: [
                // --- CANTIDAD ---
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Cantidad Entrante",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.add_box),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // --- NUEVO COSTO ---
                Expanded(
                  child: TextField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Precio de Costo",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      helperText: "Actualiza el valor"
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- BOTÓN GUARDAR ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveEntry,
                icon: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
                  : const Icon(Icons.save_alt),
                label: const Text("REGISTRAR INGRESO"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700], 
                  foregroundColor: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}