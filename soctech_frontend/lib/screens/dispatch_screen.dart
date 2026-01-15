import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// IMPORT CORRECTO (Ruta relativa segura)
import '../utils/remito_generator.dart';

class DispatchScreen extends StatefulWidget {
  const DispatchScreen({super.key});

  @override
  State<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends State<DispatchScreen> {
  // CONFIGURACIÓN DE RED (IP Segura para emulador/windows)
  final String baseUrl = 'http://127.0.0.1:5064/api'; 

  List<dynamic> projects = [];
  List<dynamic> products = [];
  bool isLoading = true;
  String? errorMessage;

  String? selectedProjectId;
  String? selectedProductId;
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String get selectedProjectName {
    if (selectedProjectId == null) return "Obra General";
    final p = projects.firstWhere((e) => e['id'] == selectedProjectId, orElse: () => null);
    return p != null ? p['name'] : "Desconocido";
  }

  String get selectedProductName {
    if (selectedProductId == null) return "-";
    final p = products.firstWhere((e) => e['id'] == selectedProductId, orElse: () => null);
    return p != null ? p['name'] : "-";
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { isLoading = true; errorMessage = null; });
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/Projects')), 
        http.get(Uri.parse('$baseUrl/Products')), 
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        
        final List<dynamic> projectsRaw = json.decode(responses[0].body) as List<dynamic>;
        final List<dynamic> productsRaw = json.decode(responses[1].body) as List<dynamic>;

        if (mounted) {
          setState(() {
            // Solo mostramos proyectos activos
            projects = projectsRaw.where((dynamic p) => p['isActive'] == true).toList();
            // Solo mostramos productos con stock > 0
            products = productsRaw.where((dynamic p) {
               final stock = p['stock'];
               final num stockNum = (stock is num) ? stock : 0;
               return stockNum > 0;
            }).toList();
            
            isLoading = false;
          });
        }
      } else {
        throw Exception("Error ${responses[0].statusCode} al conectar con Backend");
      }
    } catch (e) {
      print("Error Data: $e");
      if (mounted) setState(() { isLoading = false; errorMessage = "No se pudieron cargar los datos.\nError: $e"; });
    }
  }

  Future<void> saveDispatch() async {
    // Validaciones
    if (selectedProjectId == null || selectedProductId == null || _qtyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Complete todos los campos obligatorios")));
      return;
    }

    final double qty = double.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La cantidad debe ser mayor a 0")));
      return;
    }

    // Validación de Stock local
    final product = products.firstWhere((p) => p['id'] == selectedProductId);
    final currentStock = (product['stock'] is num) ? product['stock'] : 0;
    if (qty > currentStock) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Stock insuficiente. Disponible: $currentStock")));
       return;
    }

    final dispatchItem = {
      "productId": selectedProductId,
      "quantity": qty,
      "productName": selectedProductName
    };

    final dispatchData = {
      "projectId": selectedProjectId,
      "note": _noteController.text,
      "items": [dispatchItem]
    };

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/StockMovements/dispatch'), // Asegúrate que tu backend tenga esta ruta o ajusta a /StockMovements
        headers: {"Content-Type": "application/json"},
        body: json.encode(dispatchData),
      );

      // Aceptamos 200 (OK) o 201 (Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        
        // Intentamos leer el número de remito del backend, o generamos uno temporal
        String dispatchNum = "BORRADOR";
        try {
            final respJson = json.decode(response.body);
            dispatchNum = respJson['dispatchNumber'] ?? "S/N";
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Salida registrada. Abriendo PDF..."), backgroundColor: Colors.green));

        // DATOS PARA EL PDF
        final pdfData = {
          'dispatchNumber': dispatchNum,
          'projectName': selectedProjectName,
          'note': _noteController.text,
        };
        
        // LLAMADA AL GENERADOR (Ahora sí funcionará el import)
        await RemitoGenerator.generateAndPrint(pdfData, [dispatchItem]);

        if (mounted) {
          setState(() {
            _qtyController.clear();
            _noteController.clear();
            selectedProductId = null;
            isLoading = false;
            _loadData(); // Recargamos para ver el stock actualizado
          });
        }
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al procesar: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salida de Materiales"), 
        backgroundColor: Colors.redAccent, 
        foregroundColor: Colors.white
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
            ? Center(child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // --- SELECTOR DE OBRA ---
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Destino (Obra)", 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city)
                      ),
                      value: selectedProjectId,
                      items: projects.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']))).toList(),
                      onChanged: (val) => setState(() => selectedProjectId = val),
                    ),
                    const SizedBox(height: 20),

                    // --- SELECTOR DE PRODUCTO ---
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Producto", 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2)
                      ),
                      value: selectedProductId,
                      items: products.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'], child: Text("${p['name']} (Stock: ${p['stock']})"))).toList(),
                      onChanged: (val) => setState(() => selectedProductId = val),
                    ),
                    const SizedBox(height: 20),

                    // --- CANTIDAD ---
                    TextField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Cantidad", 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers)
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- NOTA ---
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: "Nota (Opcional)", 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note)
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // --- BOTÓN CONFIRMAR ---
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: saveDispatch, 
                      icon: const Icon(Icons.print),
                      label: const Text("CONFIRMAR Y GENERAR REMITO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                    )),
                  ],
                ),
              ),
    );
  }
}