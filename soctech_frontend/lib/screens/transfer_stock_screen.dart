import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TransferStockScreen extends StatefulWidget {
  const TransferStockScreen({super.key});

  @override
  State<TransferStockScreen> createState() => _TransferStockScreenState();
}

class _TransferStockScreenState extends State<TransferStockScreen> {
  final String baseUrl = 'http://localhost:5064/api';

  bool isLoading = true;
  bool isSaving = false;

  List<dynamic> warehouses = [];
  List<dynamic> products = [];

  String? sourceWarehouseId;
  String? targetWarehouseId;
  String? selectedProductId;

  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  double availableStock = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _safeString(dynamic item, String key) {
    if (item == null) return "";
    return item[key] ?? item[key[0].toUpperCase() + key.substring(1)] ?? "";
  }

  bool _safeBool(dynamic item, String key) {
    if (item == null) return false;
    return (item[key] == true) || (item[key[0].toUpperCase() + key.substring(1)] == true);
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

          if (warehouses.isNotEmpty) {
            final central = warehouses.firstWhere((w) => _safeBool(w, 'isMain'), orElse: () => warehouses.first);
            sourceWarehouseId = _safeString(central, 'id');
          }
          isLoading = false;
        });
        if (sourceWarehouseId != null) _checkAvailability();
      }
    } catch (e) {
      print("Error carga inicial: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _checkAvailability() async {
    setState(() => availableStock = 0);
    if (sourceWarehouseId == null || selectedProductId == null) return;

    try {
      final response = await http.get(Uri.parse('$baseUrl/Logistics/warehouse-inventory/$sourceWarehouseId'));
      if (response.statusCode == 200) {
        List<dynamic> inventory = json.decode(response.body);
        final item = inventory.firstWhere((i) => _safeString(i, 'productId') == selectedProductId, orElse: () => null);
        if (mounted) setState(() => availableStock = (item != null) ? (item['quantity'] ?? 0).toDouble() : 0.0);
      }
    } catch (e) { print("Error stock: $e"); }
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
    if (qty > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⛔ Stock insuficiente"), backgroundColor: Colors.red));
      return;
    }

    setState(() => isSaving = true);

    final movement = {
      "productId": selectedProductId,
      "branchId": "00000000-0000-0000-0000-000000000000",
      "sourceWarehouseId": sourceWarehouseId,
      "targetWarehouseId": targetWarehouseId,
      // CAMBIO IMPORTANTE: Enviamos "Transfer" (coincide con Enum C#)
      "movementType": "Transfer",
      "quantity": qty,
      "unitCost": 0,
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transferir Mercadería"), backgroundColor: Colors.orange[800], foregroundColor: Colors.white),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Campos de selección simplificados para el ejemplo
          DropdownButtonFormField<String>(
            value: sourceWarehouseId,
            items: warehouses.map<DropdownMenuItem<String>>((w) => DropdownMenuItem(value: _safeString(w, 'id'), child: Text("DESDE: ${_safeString(w, 'name')}"))).toList(),
            onChanged: (val) { setState(() => sourceWarehouseId = val); _checkAvailability(); },
            decoration: const InputDecoration(border: OutlineInputBorder(), filled: true),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: targetWarehouseId,
            items: warehouses.map<DropdownMenuItem<String>>((w) => DropdownMenuItem(value: _safeString(w, 'id'), child: Text("HACIA: ${_safeString(w, 'name')}"))).toList(),
            onChanged: (val) => setState(() => targetWarehouseId = val),
            decoration: const InputDecoration(border: OutlineInputBorder(), filled: true),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: selectedProductId,
            items: products.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: _safeString(p, 'id'), child: Text(_safeString(p, 'name')))).toList(),
            onChanged: (val) { setState(() => selectedProductId = val); _checkAvailability(); },
            decoration: const InputDecoration(labelText: "Producto", border: OutlineInputBorder()),
          ),
          if (selectedProductId != null) Padding(padding: const EdgeInsets.all(8.0), child: Text("Stock Disponible: $availableStock", style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 15),
          TextField(controller: _quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Cantidad", border: OutlineInputBorder())),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: isSaving ? null : _submitTransfer, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white), child: const Text("TRANSFERIR")))
        ]),
      ),
    );
  }
}