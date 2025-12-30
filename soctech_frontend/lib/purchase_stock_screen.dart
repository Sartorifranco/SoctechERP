import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PurchaseStockScreen extends StatefulWidget {
  const PurchaseStockScreen({super.key});

  @override
  State<PurchaseStockScreen> createState() => _PurchaseStockScreenState();
}

class _PurchaseStockScreenState extends State<PurchaseStockScreen> {
  // Controladores
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  
  bool isSaving = false;
  
  // Listas de datos
  List<dynamic> products = [];
  List<dynamic> providers = []; // <--- Lista de Proveedores

  // Selecciones
  String? selectedProductId;
  String? selectedProviderName; // Guardamos el nombre para la referencia

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // 1. Cargar Productos y Proveedores
  Future<void> loadData() async {
    try {
      final prodResp = await http.get(Uri.parse('http://localhost:5064/api/Products'));
      final provResp = await http.get(Uri.parse('http://localhost:5064/api/Providers')); // <--- Endpoint Nuevo

      if (prodResp.statusCode == 200 && provResp.statusCode == 200) {
        setState(() {
          products = json.decode(prodResp.body);
          providers = json.decode(provResp.body);
        });
      }
    } catch (e) {
      print("Error cargando datos: $e");
    }
  }

  // 2. Guardar la Compra
  Future<void> savePurchase() async {
    if (selectedProductId == null || selectedProviderName == null || 
        _quantityController.text.isEmpty || _costController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    setState(() => isSaving = true);

    // IDs FIJOS (Reemplaza con los tuyos si son distintos)
    const String companyId = "3fa85f64-5717-4562-b3fc-2c963f66afa6"; 
    const String branchId = "9c9d8c46-970e-4647-83e9-8c084f771982"; 

    // Cantidad POSITIVA (Es un ingreso)
    double quantity = double.parse(_quantityController.text);
    double cost = double.parse(_costController.text);

    final movement = {
      "companyId": companyId,
      "branchId": branchId,
      "productId": selectedProductId,
      "projectId": null, // Es compra para stock general, no para una obra específica aún
      "movementType": "PURCHASE", // Tipo de movimiento
      "quantity": quantity,
      "unitCost": cost,
      "date": DateTime.now().toIso8601String(),
      "reference": "Compra a: $selectedProviderName" // <--- Aquí guardamos el proveedor
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5064/api/StockMovements'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(movement),
      );

      if (response.statusCode == 201) {
        if (mounted) Navigator.pop(context, true); // Éxito
      } else {
        setState(() => isSaving = false);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error ${response.statusCode}: No se pudo guardar")),
          );
        }
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ingreso de Mercadería")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Por si el teclado tapa los campos
          child: Column(
            children: [
              // --- DROPDOWN PRODUCTOS ---
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Producto",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                items: products.map<DropdownMenuItem<String>>((prod) {
                  return DropdownMenuItem<String>(
                    value: prod['id'],
                    child: Text(prod['name']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedProductId = value),
              ),
              const SizedBox(height: 16),

              // --- DROPDOWN PROVEEDORES ---
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Proveedor",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                items: providers.map<DropdownMenuItem<String>>((prov) {
                  return DropdownMenuItem<String>(
                    value: prov['name'], // Usamos el nombre como valor para guardarlo en referencia
                    child: Text(prov['name']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedProviderName = value),
              ),
              const SizedBox(height: 16),

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
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Costo Unit.",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
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
                  onPressed: isSaving ? null : savePurchase,
                  icon: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
                    : const Icon(Icons.save_alt),
                  label: const Text("REGISTRAR COMPRA"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Verde para Ingresos
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}