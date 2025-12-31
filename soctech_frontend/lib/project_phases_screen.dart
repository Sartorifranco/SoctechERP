import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProjectPhasesScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectPhasesScreen({super.key, required this.project});

  @override
  State<ProjectPhasesScreen> createState() => _ProjectPhasesScreenState();
}

class _ProjectPhasesScreenState extends State<ProjectPhasesScreen> {
  List<dynamic> phases = [];
  bool isLoading = true;
  final _nameController = TextEditingController();
  final _budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPhases();
  }

  Future<void> fetchPhases() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5064/api/ProjectPhases?projectId=${widget.project['id']}')
      );
      if (response.statusCode == 200) {
        setState(() {
          phases = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => isLoading = false);
    }
  }

  Future<void> addPhase() async {
    if (_nameController.text.isEmpty) return;

    final newPhase = {
      "projectId": widget.project['id'],
      "name": _nameController.text,
      "description": "Fase creada desde App",
      "budget": double.tryParse(_budgetController.text) ?? 0,
      "isCompleted": false
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5064/api/ProjectPhases'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(newPhase),
      );

      if (response.statusCode == 201) {
        _nameController.clear();
        _budgetController.clear();
        Navigator.pop(context); // Cierra el diálogo
        fetchPhases(); // Recarga la lista
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nueva Fase de Obra"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nombre (Ej: Cimientos)", prefixIcon: Icon(Icons.flag)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Presupuesto Fase", prefixIcon: Icon(Icons.attach_money)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(onPressed: addPhase, child: const Text("Crear")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Fases: ${widget.project['name']}")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : phases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.layers_clear, size: 60, color: Colors.grey),
                      const Text("Esta obra no tiene fases definidas."),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: showAddDialog,
                        icon: const Icon(Icons.add),
                        label: const Text("Definir Primera Fase"),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: phases.length,
                  itemBuilder: (context, index) {
                    final phase = phases[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Text("${index + 1}", style: TextStyle(color: Colors.orange.shade900)),
                        ),
                        title: Text(phase['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Presupuesto: \$${phase['budget']}"),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                ),
      floatingActionButton: phases.isNotEmpty 
        ? FloatingActionButton(onPressed: showAddDialog, child: const Icon(Icons.add))
        : null,
    );
  }
}