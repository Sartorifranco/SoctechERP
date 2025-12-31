import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConsumeStockScreen extends StatefulWidget {
  const ConsumeStockScreen({super.key});

  @override
  State<ConsumeStockScreen> createState() => _ConsumeStockScreenState();
}

class _ConsumeStockScreenState extends State<ConsumeStockScreen> {
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController(); // Para aclarar "Para baño", "Pared sur", etc.
  bool isSaving = false;
  
  // Listas para los Dropdowns
  List<dynamic> products = [];
  List<dynamic> projects = [];

  // Selecciones
  String? selectedProductId;
  String? selectedProjectId;
  
  // Info auxiliar
  double currentStock = 0;

  @override
  void initState() {
    super.initState();
    loadData(); 
  }

  Future<void> loadData() async {
    try {
      // 1. Cargar Productos
      final resProd = await http.get(Uri.parse('http://localhost:5064/api/Products'));
      // 2. Cargar Obras (Proyectos)
      final resProj = await http.get(Uri.parse('http://localhost:5064/api/Projects'));

      if (resProd.statusCode == 200 && resProj.statusCode == 200) {
        setState(() {
          products = json.decode(resProd.body);
          
          // Filtramos solo las obras activas para no mandar material a obras terminadas
          var allProjects = json.decode(resProj.body);
          projects = allProjects.where((p) => p['isActive'] == true || p['status'] != 'Finished').toList();
        });
      }
    } catch (e) {
      print("Error cargando datos: $e");
    }
  }

  void onProductSelected(String? id) {
    if (id == null) return;
    final prod = products.firstWhere((p) => p['id'] == id);
    setState(() {
      selectedProductId = id;
      currentStock = (prod['stock'] ?? 0).toDouble();
    });
  }

  Future<void> saveExit() async {
    if (selectedProductId == null || selectedProjectId == null || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Producto, Obra y Cantidad son obligatorios")));
      return;
    }

    // Validar Stock negativo
    double quantity = double.tryParse(_quantityController.text) ?? 0;
    if (quantity > currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡No tienes suficiente stock!")));
      return;
    }

    setState(() => isSaving = true);

    // IDs FIJOS (Por ahora)
    const String companyId = "3fa85f64-5717-4562-b3fc-2c963f66afa6"; 
    const String branchId = "9c9d8c46-970e-4647-83e9-8c084f771982"; 

    // Obtenemos el costo actual del producto para registrar cuánto dinero se va
    final prod = products.firstWhere((p) => p['id'] == selectedProductId);
    double unitCost = (prod['costPrice'] ?? 0).toDouble();

    final movement = {
      "companyId": companyId,
      "branchId": branchId,
      "productId": selectedProductId,
      "projectId": selectedProjectId, // <--- AQUÍ VINCULAMOS LA OBRA
      "movementType": "CONSUMPTION",  // Tipo Salida
      "quantity": quantity * -1,      // Negativo porque sale
      "unitCost": unitCost,
      "date": DateTime.now().toIso8601String(),
      "reference": _descriptionController.text.isEmpty ? "Salida a Obra" : _descriptionController.text
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5064/api/StockMovements'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(movement),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Salida registrada correctamente")));
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
        title: const Text("Enviar a Obra"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Por si el teclado tapa los campos
          child: Column(
            children: [
              // --- 1. SELECCIONAR OBRA ---
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Destino (Obra)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.apartment),
                ),
                items: projects.map<DropdownMenuItem<String>>((proj) {
                  return DropdownMenuItem<String>(
                    value: proj['id'],
                    child: Text(proj['name']), // Muestra el nombre real de la obra
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedProjectId = val),
              ),
              const SizedBox(height: 16),

              // --- 2. SELECCIONAR PRODUCTO ---
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Producto a Enviar",
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
              
              if (selectedProductId != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.orange.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 10),
                      Text("Disponible: $currentStock unidades"),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // --- 3. CANTIDAD Y REFERENCIA ---
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Cantidad a Enviar",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.outbox),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Detalle (Opcional)",
                  hintText: "Ej: Para baño planta alta",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 24),

              // --- BOTÓN CONFIRMAR ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : saveExit,
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
      ),
    );
  }
}