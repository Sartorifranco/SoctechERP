import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConsumeStockScreen extends StatefulWidget {
  const ConsumeStockScreen({super.key});

  @override
  State<ConsumeStockScreen> createState() => _ConsumeStockScreenState();
}

class _ConsumeStockScreenState extends State<ConsumeStockScreen> {
  // Controladores y Variables
  final _quantityController = TextEditingController();
  bool isSaving = false;
  
  // Listas para los menús desplegables
  List<dynamic> products = [];
  List<dynamic> projects = [];

  // Selecciones del usuario
  String? selectedProductId;
  String? selectedProjectId;
  double? selectedProductCost; 

  @override
  void initState() {
    super.initState();
    loadData(); 
  }

  Future<void> loadData() async {
    try {
      final prodResp = await http.get(Uri.parse('http://localhost:5064/api/Products'));
      final projResp = await http.get(Uri.parse('http://localhost:5064/api/Projects'));

      if (prodResp.statusCode == 200 && projResp.statusCode == 200) {
        setState(() {
          products = json.decode(prodResp.body);
          projects = json.decode(projResp.body);
        });
      }
    } catch (e) {
      print("Error cargando datos: $e");
    }
  }

  Future<void> saveMovement() async {
    if (selectedProductId == null || selectedProjectId == null || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    setState(() => isSaving = true);

    // IDs DE EMPRESA
    const String companyId = "3fa85f64-5717-4562-b3fc-2c963f66afa6"; 
    const String branchId = "9c9d8c46-970e-4647-83e9-8c084f771982"; 

    // Convertir cantidad a negativo
    double quantity = double.tryParse(_quantityController.text) ?? 0;
    if (quantity > 0) quantity = quantity * -1;

    final movement = {
      "companyId": companyId,
      "branchId": branchId,
      "productId": selectedProductId,
      "projectId": selectedProjectId,
      "movementType": "CONSUMPTION",
      "quantity": quantity,
      "unitCost": selectedProductCost ?? 0, 
      "date": DateTime.now().toIso8601String(),
      "reference": "Consumo desde App Móvil"
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5064/api/StockMovements'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(movement),
      );

      if (response.statusCode == 201) {
        if (mounted) Navigator.pop(context, true); 
      } else {
        setState(() => isSaving = false);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error ${response.statusCode}: ${response.body}")),
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
      appBar: AppBar(title: const Text("Registrar Salida a Obra")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- DROPDOWN PRODUCTOS ---
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Seleccionar Producto",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              items: products.map<DropdownMenuItem<String>>((prod) {
                return DropdownMenuItem<String>(
                  value: prod['id'],
                  // --- AQUÍ ESTÁ EL FIX ROBUSTO ---
                  onTap: () {
                    // 1. Obtenemos el valor crudo (puede ser int o double)
                    final dynamic rawPrice = prod['costPrice'];
                    
                    // 2. Lo convertimos a num (que acepta ambos) y luego a double
                    if (rawPrice != null) {
                      selectedProductCost = (rawPrice as num).toDouble();
                    } else {
                      selectedProductCost = 0.0;
                    }
                  },
                  // --------------------------------
                  child: Text(prod['name']),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedProductId = value),
            ),
            const SizedBox(height: 16),

            // --- DROPDOWN OBRAS ---
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Destino (Obra)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.apartment),
              ),
              items: projects.map<DropdownMenuItem<String>>((proj) {
                return DropdownMenuItem<String>(
                  value: proj['id'],
                  child: Text(proj['name']),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedProjectId = value),
            ),
            const SizedBox(height: 16),

            // --- CANTIDAD ---
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Cantidad a sacar",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.onetwothree),
                suffixText: "unidades"
              ),
            ),
            const SizedBox(height: 24),

            // --- BOTÓN GUARDAR ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveMovement,
                icon: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
                  : const Icon(Icons.send),
                label: const Text("REGISTRAR SALIDA"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, 
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