import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProjectAddScreen extends StatefulWidget {
  const ProjectAddScreen({super.key});

  @override
  State<ProjectAddScreen> createState() => _ProjectAddScreenState();
}

class _ProjectAddScreenState extends State<ProjectAddScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _budgetController = TextEditingController();
  bool isSaving = false;

  Future<void> saveProject() async {
    if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nombre y Dirección son obligatorios")),
      );
      return;
    }

    setState(() => isSaving = true);

    // IDs DE EMPRESA (Hardcodeados por ahora, igual que el resto)
    const String companyId = "3fa85f64-5717-4562-b3fc-2c963f66afa6"; 
    
    final project = {
      "companyId": companyId,
      "name": _nameController.text,
      "description": _addressController.text, // Usamos descripción para la dirección por ahora
      "status": "InProcess", // Arranca activa
      "startDate": DateTime.now().toIso8601String(),
      "budget": double.tryParse(_budgetController.text) ?? 0,
      "isActive": true
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5064/api/Projects'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(project),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Obra creada con éxito!")));
          Navigator.pop(context, true); // Volvemos y avisamos que se creó
        }
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva Obra")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.foundation, size: 60, color: Colors.indigo),
            const SizedBox(height: 20),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nombre de la Obra",
                hintText: "Ej: Edificio Torre Alta",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "Ubicación / Dirección",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Presupuesto Inicial (Opcional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveProject,
                icon: isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) 
                  : const Icon(Icons.save),
                label: const Text("CREAR OBRA"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
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