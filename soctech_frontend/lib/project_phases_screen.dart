import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProjectPhasesScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  final List<dynamic> projectMovements; // Gastos Materiales
  final List<dynamic> projectWorkLogs;  // Gastos Mano de Obra (NUEVO)

  const ProjectPhasesScreen({
    super.key, 
    required this.project,
    required this.projectMovements, 
    required this.projectWorkLogs, // <--- Requerido
  });

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
        Navigator.pop(context);
        fetchPhases();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- CÁLCULO FINANCIERO TOTAL POR FASE ---
  double calculatePhaseTotalSpent(String phaseId) {
    // 1. Sumar Materiales de esta fase
    var phaseMaterials = widget.projectMovements.where((m) => m['projectPhaseId'] == phaseId);
    double materialTotal = 0;
    for (var m in phaseMaterials) {
      materialTotal += (m['quantity'] * m['unitCost']).abs();
    }

    // 2. Sumar Mano de Obra de esta fase
    var phaseLabor = widget.projectWorkLogs.where((w) => w['projectPhaseId'] == phaseId);
    double laborTotal = 0;
    for (var w in phaseLabor) {
      laborTotal += (w['hoursWorked'] * (w['registeredRateSnapshot'] ?? 0));
    }

    return materialTotal + laborTotal;
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nueva Fase de Obra"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nombre (Ej: Cimientos)")),
            const SizedBox(height: 10),
            TextField(controller: _budgetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Presupuesto (\$)")),
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
      appBar: AppBar(title: Text("WBS: ${widget.project['name']}")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : phases.isEmpty
              ? const Center(child: Text("Sin fases definidas"))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: phases.length,
                  itemBuilder: (context, index) {
                    final phase = phases[index];
                    
                    final double budget = (phase['budget'] ?? 0).toDouble();
                    // AQUÍ ESTÁ EL PODER: Suma todo
                    final double spent = calculatePhaseTotalSpent(phase['id']);
                    
                    final double progress = budget > 0 ? (spent / budget) : 0;
                    final bool isOverBudget = spent > budget;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("${index + 1}. ${phase['name']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                if(isOverBudget)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                    child: const Text("ALERTA COSTOS", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                  )
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: progress > 1 ? 1 : progress,
                              backgroundColor: Colors.grey.shade200,
                              color: isOverBudget ? Colors.red : Colors.green,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Ejecutado: \$${spent.toStringAsFixed(0)}", 
                                  style: TextStyle(fontWeight: FontWeight.bold, color: isOverBudget ? Colors.red : Colors.black87)
                                ),
                                Text("Presupuesto: \$${budget.toStringAsFixed(0)}", style: const TextStyle(color: Colors.grey)),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: phases.isNotEmpty ? FloatingActionButton(onPressed: showAddDialog, child: const Icon(Icons.add)) : null,
    );
  }
}