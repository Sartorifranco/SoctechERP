import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MassAttendanceScreen extends StatefulWidget {
  const MassAttendanceScreen({super.key});

  @override
  State<MassAttendanceScreen> createState() => _MassAttendanceScreenState();
}

class _MassAttendanceScreenState extends State<MassAttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  
  List<dynamic> allEmployees = []; // Todos los empleados
  List<dynamic> filteredEmployees = []; // Solo los de la obra seleccionada
  List<dynamic> projects = []; // Lista de Obras
  
  List<String> selectedEmployeeIds = []; 
  String? selectedProjectId; // OBRA FILTRO

  bool isLoading = true;
  bool isSaving = false;

  double defaultHours = 9; 
  String note = ""; 

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final resEmp = await http.get(Uri.parse('http://localhost:5064/api/Employees'));
      final resProj = await http.get(Uri.parse('http://localhost:5064/api/Projects'));

      if (resEmp.statusCode == 200 && resProj.statusCode == 200) {
        setState(() {
          allEmployees = json.decode(resEmp.body).where((e) => e['isActive'] == true).toList();
          projects = json.decode(resProj.body).where((p) => p['isActive'] == true).toList();
          
          // Inicialmente la lista filtrada está vacía hasta que elija obra
          filteredEmployees = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // --- CUANDO SELECCIONA OBRA, FILTRAMOS ---
  void onProjectChanged(String? projId) {
    setState(() {
      selectedProjectId = projId;
      if (projId == null) {
        filteredEmployees = [];
      } else {
        // Filtramos empleados que tengan currentProjectId == projId
        filteredEmployees = allEmployees.where((e) => e['currentProjectId'] == projId).toList();
        
        // Auto-seleccionamos a todos para agilizar
        selectedEmployeeIds = filteredEmployees.map<String>((e) => e['id'].toString()).toList();
      }
    });
  }

  void toggleSelection(String id) {
    setState(() {
      if (selectedEmployeeIds.contains(id)) {
        selectedEmployeeIds.remove(id);
      } else {
        selectedEmployeeIds.add(id);
      }
    });
  }

  void selectAll(bool select) {
    setState(() {
      if (select) {
        selectedEmployeeIds = filteredEmployees.map<String>((e) => e['id'].toString()).toList();
      } else {
        selectedEmployeeIds.clear();
      }
    });
  }

  Future<void> saveAttendance(bool isPresent) async {
    if (selectedEmployeeIds.isEmpty) return;
    if (selectedProjectId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleccione una Obra primero")));
       return;
    }

    setState(() => isSaving = true);

    int successCount = 0;

    for (String empId in selectedEmployeeIds) {
      final log = {
        "employeeId": empId,
        "projectId": selectedProjectId, // <--- AQUÍ IMPUTAMOS EL COSTO A LA OBRA
        "date": selectedDate.toIso8601String(),
        "hoursWorked": isPresent ? defaultHours : 0, 
        "notes": isPresent ? note : "AUSENTE", 
        "registeredRateSnapshot": 0 
      };

      try {
        await http.post(
          Uri.parse('http://localhost:5064/api/WorkLogs'),
          headers: {"Content-Type": "application/json"},
          body: json.encode(log),
        );
        successCount++;
      } catch (e) {
        print("Error: $e");
      }
    }

    setState(() => isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPresent 
            ? "¡Presentismo cargado a $successCount empleados en obra!" 
            : "¡Ausencias registradas!"),
          backgroundColor: isPresent ? Colors.green : Colors.red,
        )
      );
      // Opcional: limpiar selección
      // setState(() => selectedEmployeeIds.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Control de Cuadrilla"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final d = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
              if (d != null) setState(() => selectedDate = d);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // --- BARRA SUPERIOR (FECHA Y OBRA) ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.indigo.shade50,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Fecha: $formattedDate", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        const Text("Jornada: "),
                        SizedBox(
                          width: 40,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            controller: TextEditingController(text: defaultHours.toString()),
                            onChanged: (val) => defaultHours = double.tryParse(val) ?? 9,
                          ),
                        ),
                        const Text(" hs"),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // DROPDOWN DE OBRA (FILTRO PRINCIPAL)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Seleccionar Obra / Cuadrilla",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.apartment),
                    filled: true,
                    fillColor: Colors.white
                  ),
                  value: selectedProjectId,
                  items: projects.map<DropdownMenuItem<String>>((p) {
                    return DropdownMenuItem(value: p['id'], child: Text(p['name']));
                  }).toList(),
                  onChanged: onProjectChanged,
                  hint: const Text("¿Dónde estamos trabajando hoy?"),
                ),
              ],
            ),
          ),
          
          // --- LISTA DE EMPLEADOS ---
          if (selectedProjectId == null)
            const Expanded(child: Center(child: Text("Seleccione una obra para ver el personal asignado", style: TextStyle(color: Colors.grey))))
          else if (filteredEmployees.isEmpty)
             const Expanded(child: Center(child: Text("No hay personal asignado a esta obra", style: TextStyle(color: Colors.grey))))
          else
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey.shade200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Personal: ${filteredEmployees.length} | Sel: ${selectedEmployeeIds.length}"),
                        Row(
                          children: [
                            TextButton(onPressed: () => selectAll(true), child: const Text("Todos")),
                            TextButton(onPressed: () => selectAll(false), child: const Text("Ninguno")),
                          ],
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredEmployees.length,
                      itemBuilder: (context, index) {
                        final emp = filteredEmployees[index];
                        final isSelected = selectedEmployeeIds.contains(emp['id']);
                        
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) => toggleSelection(emp['id']),
                          title: Text("${emp['lastName']}, ${emp['firstName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(emp['cuil'] ?? ""),
                          secondary: CircleAvatar(
                            child: Text(emp['firstName'][0]),
                            backgroundColor: isSelected ? Colors.indigo : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // --- BOTONES DE ACCIÓN ---
          if (selectedProjectId != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: isSaving 
                ? const CircularProgressIndicator()
                : Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red.shade900, padding: const EdgeInsets.symmetric(vertical: 15)),
                        onPressed: () => saveAttendance(false), 
                        icon: const Icon(Icons.person_off),
                        label: const Text("AUSENTES"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                        onPressed: () => saveAttendance(true), 
                        icon: const Icon(Icons.check_circle),
                        label: const Text("PRESENTES"),
                      ),
                    ),
                  ],
                ),
            )
        ],
      ),
    );
  }
}