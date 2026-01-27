import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TransferStockScreen extends StatefulWidget {
  const TransferStockScreen({super.key});

  @override
  State<TransferStockScreen> createState() => _TransferStockScreenState();
}

class _TransferStockScreenState extends State<TransferStockScreen> {
  final String baseUrl = 'http://127.0.0.1:5064/api';

  bool isLoading = true;
  bool isSaving = false;

  List<dynamic> warehouses = [];
  List<dynamic> products = [];

  String? sourceWarehouseId;
  String? targetWarehouseId;
  String? selectedProductId;
  
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  // Info visual
  double availableStock = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/Logistics/warehouses')),
        http.get(Uri.parse('$baseUrl/Products')),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        setState(() {
          warehouses = json.decode(responses[0].body);
          products = json.decode(responses[1].body);
          
          // Auto-seleccionar Central como Origen por defecto
          final central = warehouses.firstWhere((w) => w['isMain'] == true, orElse: () => null);
          if (central != null) sourceWarehouseId = central['id'];
          
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Verificar stock cuando cambia el Origen o el Producto
  Future<void> _checkAvailability() async {
    if (sourceWarehouseId == null || selectedProductId == null) return;

    try {
      final response = await http.get(Uri.parse('$baseUrl/Logistics/warehouse-inventory/$sourceWarehouseId'));
      if (response.statusCode == 200) {
        List<dynamic> inventory = json.decode(response.body);
        final selectedProd = products.firstWhere((p) => p['id'] == selectedProductId, orElse: () => {'sku': ''});
        final String targetSku = selectedProd['sku'] ?? '';

        // Buscamos por SKU o ID si tuviéramos
        final item = inventory.firstWhere((i) => i['sku'] == targetSku, orElse: () => null);
        
        setState(() {
          availableStock = (item != null) ? (item['quantity'] ?? 0).toDouble() : 0.0;
        });
      }
    } catch (e) {
      print("Error verificando stock: $e");
    }
  }

  Future<void> _submitTransfer() async {
    if (sourceWarehouseId == null || targetWarehouseId == null || selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona origen, destino y producto")));
      return;
    }
    if (sourceWarehouseId == targetWarehouseId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El origen y destino no pueden ser iguales")));
      return;
    }

    double qty = double.tryParse(_quantityController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cantidad inválida")));
      return;
    }
    // Validación preventiva en frontend
    if (qty > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⛔ No hay suficiente stock en el origen"), backgroundColor: Colors.red));
      return;
    }

    setState(() => isSaving = true);

    final movement = {
      "productId": selectedProductId,
      "branchId": "00000000-0000-0000-0000-000000000000",
      "sourceWarehouseId": sourceWarehouseId, // SALE DE ACÁ
      "targetWarehouseId": targetWarehouseId, // ENTRA ACÁ
      "movementType": "TRANSFER",
      "quantity": qty,
      "unitCost": 0, // En transferencia el costo se mantiene
      "date": DateTime.now().toIso8601String(),
      "description": _reasonController.text.isEmpty ? "Transferencia Interna" : _reasonController.text,
      "reference": "TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}"
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/StockMovements'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(movement),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Transferencia Exitosa"), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transferir Mercadería"), backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TARJETA DE ORIGEN (ROJO)
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [Icon(Icons.outbound, color: Colors.red), SizedBox(width: 10), Text("DESDE (Origen)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))]),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: sourceWarehouseId,
                          isExpanded: true,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                          items: warehouses.map<DropdownMenuItem<String>>((w) => DropdownMenuItem(value: w['id'], child: Text(w['name']))).toList(),
                          onChanged: (val) {
                            setState(() => sourceWarehouseId = val);
                            _checkAvailability();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Center(child: Icon(Icons.arrow_downward, size: 30, color: Colors.grey)),

                // TARJETA DE DESTINO (VERDE)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [Icon(Icons.input, color: Colors.green), SizedBox(width: 10), Text("HACIA (Destino)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))]),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: targetWarehouseId,
                          isExpanded: true,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                          items: warehouses.map<DropdownMenuItem<String>>((w) => DropdownMenuItem(value: w['id'], child: Text(w['name']))).toList(),
                          onChanged: (val) => setState(() => targetWarehouseId = val),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // SELECCIÓN DE PRODUCTO
                const Text("Detalle del Envío", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedProductId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: "Producto", border: OutlineInputBorder(), prefixIcon: Icon(Icons.inventory)),
                  items: products.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']))).toList(),
                  onChanged: (val) {
                    setState(() => selectedProductId = val);
                    _checkAvailability();
                  },
                ),
                
                // DISPONIBILIDAD
                if (selectedProductId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("Disponible en origen: ", style: TextStyle(color: Colors.grey[700])),
                        Text("$availableStock u.", style: TextStyle(fontWeight: FontWeight.bold, color: availableStock > 0 ? Colors.green : Colors.red, fontSize: 16)),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Cantidad a Mover", border: OutlineInputBorder(), prefixIcon: Icon(Icons.onetwothree)),
                ),

                const SizedBox(height: 15),
                 TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(labelText: "Motivo / Chofer", border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : _submitTransfer,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text("CONFIRMAR TRANSFERENCIA", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
                  ),
                )
              ],
            ),
          ),
    );
  }
}