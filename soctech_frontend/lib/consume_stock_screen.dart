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
  final _descriptionController = TextEditingController();
  bool isSaving = false;
  
  // Listas de Datos
  List<dynamic> products = [];
  List<dynamic> projects = [];
  List<dynamic> projectPhases = [];

  // Selecciones
  String? selectedProductId;
  String? selectedProjectId;
  String? selectedPhaseId;
  
  // Info auxiliar
  double currentStock = 0;

  @override
  void initState() {
    super.initState();
    loadInitialData(); 
  }

  Future<void> loadInitialData() async {
    try {
      // Asegúrate de que el puerto sea el 5064 (el que te dio Swagger)
      final resProd = await http.get(Uri.parse('http://localhost:5064/api/Products'));
      final resProj = await http.get(Uri.parse('http://localhost:5064/api/Projects'));

      if (resProd.statusCode == 200 && resProj.statusCode == 200) {
        setState(() {
          products = json.decode(resProd.body);
          var allProjects = json.decode(resProj.body);
          // Filtramos solo activas
          projects = allProjects.where((p) => p['isActive'] == true || p['status'] != 'Finished').toList();
        });
      }
    } catch (e) {
      print("Error cargando datos: $e");
    }
  }

  // Cuando selecciona obra, buscamos sus fases
  Future<void> onProjectSelected(String? projectId) async {
    if (projectId == null) return;

    setState(() {
      selectedProjectId = projectId;
      selectedPhaseId = null; // Reseteamos fase anterior
      projectPhases = []; // Limpiamos lista
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5064/api/ProjectPhases?projectId=$projectId')
      );
      
      if (response.statusCode == 200) {
        setState(() {
          projectPhases = json.decode(response.body);
        });
      }
    } catch (e) {
      print("Error cargando fases: $e");
    }
  }

  void onProductSelected(String? id) {
    if (id == null) return;
    // Buscamos el producto en la lista para saber su stock actual
    final prod = products.firstWhere((p) => p['id'] == id, orElse: () => null);
    if (prod != null) {
      setState(() {
        selectedProductId = id;
        currentStock = (prod['stock'] ?? 0).toDouble();
      });
    }
  }

  Future<void> saveExit() async {
    // 1. Validaciones básicas
    if (selectedProductId == null || selectedProjectId == null || _quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Completa los campos obligatorios")));
      return;
    }

    double quantity = double.tryParse(_quantityController.text) ?? 0;
    
    if (quantity <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La cantidad debe ser mayor a 0")));
       return;
    }

    if (quantity > currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡No tienes suficiente stock!")));
      return;
    }

    setState(() => isSaving = true);

    try {
      // 2. Obtener nombre de la fase (si existe) para enviarlo al backend
      String phaseName = "";
      if (selectedPhaseId != null && projectPhases.isNotEmpty) {
         final phaseObj = projectPhases.firstWhere((p) => p['id'] == selectedPhaseId, orElse: () => null);
         if (phaseObj != null) {
           phaseName = phaseObj['name'];
         }
      }

      // 3. ARMAR EL PAQUETE (JSON)
      // Esta estructura coincide exactamente con tu clase "Dispatch" en C#
      final dispatchPayload = {
        "projectId": selectedProjectId,
        "note": _descriptionController.text.isEmpty ? "Salida desde App" : _descriptionController.text,
        "items": [
          {
            "productId": selectedProductId,
            "quantity": quantity, // Enviamos positivo, el backend lo resta
            "projectPhaseName": phaseName
          }
        ]
      };

      // 4. ENVIAR A LA API (Endpoint Correcto)
      final response = await http.post(
        Uri.parse('http://localhost:5064/api/dispatch'), // <--- AQUÍ ESTÁ LA CORRECCIÓN CLAVE
        headers: {"Content-Type": "application/json"},
        body: json.encode(dispatchPayload),
      );

      // 5. RESPUESTA
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Salida registrada correctamente!")));
          Navigator.pop(context, true); // Volver atrás y recargar
        }
      } else {
        throw Exception("Error del servidor (${response.statusCode}): ${response.body}");
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
        title: const Text("Salida de Materiales"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. SELECCIONAR OBRA ---
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Destino (Obra)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.apartment),
                ),
                value: selectedProjectId,
                items: projects.map<DropdownMenuItem<String>>((proj) {
                  return DropdownMenuItem<String>(
                    value: proj['id'],
                    child: Text(proj['name']),
                  );
                }).toList(),
                onChanged: onProjectSelected,
              ),
              const SizedBox(height: 16),

              // --- 2. SELECCIONAR FASE (Dinámico) ---
              if (selectedProjectId != null) 
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Fase / Etapa (Opcional)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.layers),
                      helperText: "Ej: Cimientos, Estructura..."
                    ),
                    value: selectedPhaseId,
                    items: projectPhases.isEmpty 
                      ? [] 
                      : projectPhases.map<DropdownMenuItem<String>>((phase) {
                          return DropdownMenuItem<String>(
                            value: phase['id'],
                            child: Text(phase['name']),
                          );
                        }).toList(),
                    onChanged: (val) => setState(() => selectedPhaseId = val),
                    disabledHint: const Text("Esta obra no tiene fases definidas"),
                  ),
                ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // --- 3. PRODUCTO Y CANTIDAD ---
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Producto",
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
              
              if (selectedProductId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text("Stock en pañol: $currentStock", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Cantidad",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.outbox),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Nota (Opcional)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : saveExit,
                  icon: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
                    : const Icon(Icons.send),
                  label: const Text("CONFIRMAR SALIDA"),
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