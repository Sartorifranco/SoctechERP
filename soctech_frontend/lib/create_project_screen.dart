import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool isSaving = false;

  Future<void> saveProject() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre es obligatorio")),
      );
      return;
    }

    setState(() => isSaving = true);

    // DATOS HARDCODEADOS DE EMPRESA (Luego los haremos dinámicos)
    // Usamos el ID de ejemplo de Swagger por ahora para que funcione seguro
    const String companyId = "3fa85f64-5717-4562-b3fc-2c963f66afa6"; 

    final newProject = {
      "companyId": companyId,
      "name": _nameController.text,
      "address": _addressController.text,
      "status": "Planning",
      "startDate": DateTime.now().toIso8601String(),
      "isActive": true
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5064/api/Projects'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(newProject),
      );

      if (response.statusCode == 201) {
        // Éxito: Volver atrás y avisar que recargue
        if (mounted) Navigator.pop(context, true); 
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de conexión: $e")),
        );
      }
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
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nombre de la Obra",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: "Dirección (Opcional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveProject,
                icon: isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.save),
                label: const Text("GUARDAR OBRA"),
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