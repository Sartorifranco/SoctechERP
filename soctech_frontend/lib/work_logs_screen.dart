import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WorkLogsScreen extends StatefulWidget {
  const WorkLogsScreen({super.key});

  @override
  State<WorkLogsScreen> createState() => _WorkLogsScreenState();
}

class _WorkLogsScreenState extends State<WorkLogsScreen> {
  // Datos maestros
  List<dynamic> projects = [];
  List<dynamic> employees = [];
  List<dynamic> phases = [];
  
  // Historial
  List<dynamic> recentLogs = [];

  // Selecciones
  String? selectedProjectId;
  String? selectedPhaseId;
  String? selectedEmployeeId;
  
  // Controladores
  final _hoursController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  bool isLoading = true;
  bool isSaving = false;

  // Calculadora visual
  double estimatedCost = 0;
  String calculationExplanation = ""; // Texto dinámico para explicar el cálculo

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      final resProj = await http.get(Uri.parse('http://localhost:5064/api/Projects'));
      final resEmp = await http.get(Uri.parse('http://localhost:5064/api/Employees'));
      final resLogs = await http.get(Uri.parse('http://localhost:5064/api/WorkLogs'));

      if (resProj.statusCode == 200 && resEmp.statusCode == 200) {
        setState(() {
          var allProjects = json.decode(resProj.body);
          // Filtramos obras activas
          projects = allProjects.where((p) => p['isActive'] == true || p['status'] != 'Finished').toList();
          
          // Incluimos WageScale gracias al backend
          employees = json.decode(resEmp.body);
          
          if (resLogs.statusCode == 200) {
            recentLogs = json.decode(resLogs.body);
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> onProjectSelected(String? projectId) async {
    if (projectId == null) return;
    setState(() {
      selectedProjectId = projectId;
      selectedPhaseId = null;
      phases = [];
    });

    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/ProjectPhases?projectId=$projectId'));
      if (response.statusCode == 200) {
        setState(() {
          phases = json.decode(response.body);
        });
      }
    } catch (e) {
      print("Error cargando fases: $e");
    }
  }

  // --- LÓGICA INTELIGENTE DE CÁLCULO ---
  void calculatePreview() {
    if (selectedEmployeeId == null || _hoursController.text.isEmpty) {
      setState(() {
        estimatedCost = 0;
        calculationExplanation = "";
      });
      return;
    }

    final emp = employees.firstWhere((e) => e['id'] == selectedEmployeeId);
    double hours = double.tryParse(_hoursController.text) ?? 0;
    
    double rate = 0;
    String categoryName = "Sin Categoría";
    bool isMonthly = false;

    if (emp['wageScale'] != null) {
      rate = (emp['wageScale']['basicValue'] ?? 0).toDouble();
      categoryName = emp['wageScale']['categoryName'];
      // Si el valor es muy alto (ej: > 100.000), asumimos que es mensual (UECARA)
      // O idealmente usaríamos el enum 'Union' del empleado si lo trajéramos mapeado
      if (rate > 200000) { 
        isMonthly = true;
      }
    }

    // Ajuste Matemático
    double finalRate = isMonthly ? (rate / 200) : rate; // 200 horas mensuales promedio

    setState(() {
      estimatedCost = hours * finalRate;
      
      // EXPLICACIÓN UX PARA EL USUARIO
      if (isMonthly) {
        calculationExplanation = "Legajo Mensual ($categoryName).\nCálculo: Sueldo \$$rate / 200hs = \$${finalRate.toStringAsFixed(0)}/hr.";
      } else {
        calculationExplanation = "Legajo Jornal ($categoryName).\nCálculo: Valor Hora Oficial UOCRA = \$$rate.";
      }
    });
  }

  Future<void> saveLog() async {
    if (selectedProjectId == null || selectedEmployeeId == null || _hoursController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faltan datos obligatorios")));
      return;
    }

    setState(() => isSaving = true);

    // Nota: Aquí podrías guardar el 'registeredRateSnapshot' calculado en el front si quisieras,
    // pero el backend ya lo hace. Dejamos que el backend decida el snapshot oficial.
    
    final newLog = {
      "employeeId": selectedEmployeeId,
      "projectId": selectedProjectId,
      "projectPhaseId": selectedPhaseId, 
      "date": selectedDate.toIso8601String(),
      "hoursWorked": double.parse(_hoursController.text),
      "notes": _notesController.text
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5064/api/WorkLogs'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(newLog),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Parte diario registrado correctamente")));
        _hoursController.clear();
        _notesController.clear();
        setState(() {
          estimatedCost = 0;
          calculationExplanation = "";
          isSaving = false;
        });
        
        final resLogs = await http.get(Uri.parse('http://localhost:5064/api/WorkLogs'));
        if (resLogs.statusCode == 200) {
          setState(() => recentLogs = json.decode(resLogs.body));
        }
      } else {
        throw Exception("Error ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Carga de Horas")),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TARJETA DE CARGA
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // FECHA
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text("Fecha: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.calendar_today, color: Colors.indigo),
                          onTap: pickDate,
                        ),
                        const Divider(),
                        
                        // 1. OBRA
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Obra / Proyecto", prefixIcon: Icon(Icons.apartment)),
                          items: projects.map<DropdownMenuItem<String>>((p) => 
                            DropdownMenuItem(value: p['id'], child: Text(p['name']))
                          ).toList(),
                          onChanged: onProjectSelected,
                        ),
                        const SizedBox(height: 15),

                        // 2. FASE
                        if (selectedProjectId != null)
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: "Fase de Obra", prefixIcon: Icon(Icons.layers), helperText: "Imputación de costos"),
                            value: selectedPhaseId,
                            items: phases.map<DropdownMenuItem<String>>((ph) => 
                              DropdownMenuItem(value: ph['id'], child: Text(ph['name']))
                            ).toList(),
                            onChanged: (val) => setState(() => selectedPhaseId = val),
                          ),
                        const SizedBox(height: 15),

                        // 3. EMPLEADO
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Empleado", prefixIcon: Icon(Icons.person)),
                          items: employees.map<DropdownMenuItem<String>>((e) {
                             String cat = (e['wageScale'] != null) ? e['wageScale']['categoryName'] : "";
                             return DropdownMenuItem(value: e['id'], child: Text("${e['lastName']}, ${e['firstName']} ($cat)"));
                          }).toList(),
                          onChanged: (val) {
                            setState(() => selectedEmployeeId = val);
                            calculatePreview();
                          },
                        ),
                        const SizedBox(height: 15),

                        // 4. INFO BOX (UX MEJORADA)
                        if (calculationExplanation.isNotEmpty)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200)
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.blue),
                                const SizedBox(width: 10),
                                Expanded(child: Text(calculationExplanation, style: TextStyle(color: Colors.blue.shade900, fontSize: 12))),
                              ],
                            ),
                          ),

                        // 5. HORAS Y TOTAL
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _hoursController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: "Horas", suffixText: "hs", border: OutlineInputBorder()),
                                onChanged: (_) => calculatePreview(),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 55,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  border: Border.all(color: Colors.green.shade200),
                                  borderRadius: BorderRadius.circular(5)
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("COSTO TOTAL", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                    Text("\$${estimatedCost.toStringAsFixed(0)}", 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: isSaving ? null : saveLog,
                            icon: const Icon(Icons.save),
                            label: const Text("REGISTRAR PARTE"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                
                // ... Lista de historial (igual que antes) ...
                const SizedBox(height: 20),
                const Text("Historial Reciente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentLogs.length > 5 ? 5 : recentLogs.length,
                  itemBuilder: (context, index) {
                    final log = recentLogs[index];
                    final date = DateTime.parse(log['date']);
                    final empName = log['employee'] != null ? "${log['employee']['lastName']}, ${log['employee']['firstName']}" : "Desconocido";
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.timer, color: Colors.grey),
                        title: Text(empName),
                        subtitle: Text("${date.day}/${date.month} - ${log['hoursWorked']} hs"),
                        trailing: Text("\$${(log['hoursWorked'] * (log['registeredRateSnapshot']??0)).toStringAsFixed(0)}"),
                      ),
                    );
                  },
                )
              ],
            ),
          ),
    );
  }
}