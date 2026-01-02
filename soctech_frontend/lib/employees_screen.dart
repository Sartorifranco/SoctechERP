import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'employee_detail_screen.dart'; 

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> with SingleTickerProviderStateMixin {
  List<dynamic> employees = [];
  List<dynamic> wageScales = []; 
  List<dynamic> projects = []; // Lista de Obras
  bool isLoading = true;

  late TabController _tabController;

  // Controladores
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cuilController = TextEditingController();
  final _salaryController = TextEditingController(); 
  
  // Selecciones
  String? selectedScaleId;
  String? selectedProjectId; 
  String selectedUnion = "UOCRA"; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadData();
  }

  Future<void> loadData() async {
    try {
      final resEmp = await http.get(Uri.parse('http://localhost:5064/api/Employees'));
      final resScales = await http.get(Uri.parse('http://localhost:5064/api/WageScales')); 
      final resProj = await http.get(Uri.parse('http://localhost:5064/api/Projects')); 

      if (resEmp.statusCode == 200 && resScales.statusCode == 200 && resProj.statusCode == 200) {
        setState(() {
          employees = json.decode(resEmp.body);
          wageScales = json.decode(resScales.body);
          // Cargamos todas las obras para poder visualizar el nombre, incluso si se inactivaron
          projects = json.decode(resProj.body); 
          isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => isLoading = false);
    }
  }

  List<dynamic> getFilteredScales() {
    int unionType = selectedUnion == "UOCRA" ? 0 : 1; 
    return wageScales.where((s) => s['union'] == unionType).toList();
  }

  // --- OBTENER OBRAS ACTIVAS PARA EL SELECTOR ---
  List<dynamic> getActiveProjects() {
    return projects.where((p) => p['isActive'] == true).toList();
  }

  Future<void> addEmployee() async {
    if (_nameController.text.isEmpty || _lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faltan datos obligatorios")));
      return;
    }

    int unionEnum = 0;
    if (selectedUnion == "UECARA") unionEnum = 1;
    if (selectedUnion == "FDC") unionEnum = 2;

    int freqEnum = (selectedUnion == "UOCRA") ? 0 : 1; 

    double? manualSalary;
    if (selectedUnion == "FDC" && _salaryController.text.isNotEmpty) {
      manualSalary = double.tryParse(_salaryController.text);
    }

    final newEmployee = {
      "firstName": _nameController.text,
      "lastName": _lastNameController.text,
      "cuil": _cuilController.text,
      "address": "Sin Dirección", 
      "entryDate": DateTime.now().toIso8601String(),
      "union": unionEnum,
      "frequency": freqEnum,
      "wageScaleId": selectedScaleId, 
      "negotiatedSalary": manualSalary, 
      "currentProjectId": selectedProjectId, 
      "isActive": true
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5064/api/Employees'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(newEmployee),
      );

      if (response.statusCode == 201) {
        _nameController.clear();
        _lastNameController.clear();
        _cuilController.clear();
        _salaryController.clear();
        setState(() {
          selectedScaleId = null;
          selectedProjectId = null;
        });
        Navigator.pop(context); 
        loadData(); 
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( 
          builder: (context, setDialogState) {
            bool isFdc = selectedUnion == "FDC"; 

            return AlertDialog(
              title: const Text("Alta de Personal"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Datos Personales", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const Divider(),
                    TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nombres", icon: Icon(Icons.person))),
                    TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: "Apellidos", icon: Icon(Icons.person_outline))),
                    TextField(controller: _cuilController, decoration: const InputDecoration(labelText: "CUIL", icon: Icon(Icons.badge))),
                    
                    const SizedBox(height: 20),
                    const Text("Asignación de Obra", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const Divider(),
                    
                    // --- SELECTOR DE OBRA ---
                    DropdownButtonFormField<String>(
                      value: selectedProjectId,
                      decoration: const InputDecoration(labelText: "Obra Asignada", icon: Icon(Icons.apartment)),
                      items: getActiveProjects().map<DropdownMenuItem<String>>((p) {
                         return DropdownMenuItem(value: p['id'], child: Text(p['name']));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedProjectId = val),
                      hint: const Text("Seleccione Obra (Opcional)"),
                    ),

                    const SizedBox(height: 20),
                    const Text("Datos Contractuales", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const Divider(),
                    
                    DropdownButtonFormField<String>(
                      value: selectedUnion,
                      decoration: const InputDecoration(labelText: "Convenio / Área", icon: Icon(Icons.gavel)),
                      items: const [
                        DropdownMenuItem(value: "UOCRA", child: Text("UOCRA (Obrero)")),
                        DropdownMenuItem(value: "UECARA", child: Text("UECARA (Administrativo)")),
                        DropdownMenuItem(value: "FDC", child: Text("Fuera de Convenio (Manual)")),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedUnion = val!;
                          selectedScaleId = null; 
                        });
                      },
                    ),

                    const SizedBox(height: 10),

                    if (isFdc) 
                      TextField(
                        controller: _salaryController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Sueldo Bruto Acordado (\$)", 
                          icon: Icon(Icons.attach_money),
                          helperText: "Ingrese el valor mensual exacto"
                        ),
                      )
                    else 
                      DropdownButtonFormField<String>(
                        value: selectedScaleId,
                        decoration: const InputDecoration(labelText: "Categoría Oficial", icon: Icon(Icons.work)),
                        items: getFilteredScales().map<DropdownMenuItem<String>>((scale) {
                          final val = scale['basicValue'];
                          final tipo = selectedUnion == "UOCRA" ? "/hr" : "/mes";
                          return DropdownMenuItem<String>(
                            value: scale['id'],
                            child: Text("${scale['categoryName']} (\$${val}$tipo)"),
                          );
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedScaleId = val),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(onPressed: addEmployee, child: const Text("Dar de Alta")),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listUocra = employees.where((e) => e['union'] == 0).toList();
    final listAdmin = employees.where((e) => e['union'] == 1 || e['union'] == 2).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recursos Humanos"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.construction), text: "OBRA (UOCRA)"),
            Tab(icon: Icon(Icons.computer), text: "ADMIN / FDC"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddDialog,
        icon: const Icon(Icons.person_add),
        label: const Text("Nuevo Legajo"),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildEmployeeList(listUocra, isHourly: true),
              _buildEmployeeList(listAdmin, isHourly: false),
            ],
          ),
    );
  }

  Widget _buildEmployeeList(List<dynamic> list, {required bool isHourly}) {
    if (list.isEmpty) return const Center(child: Text("No hay legajos en esta categoría"));

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final emp = list[index];
        bool isFdc = emp['union'] == 2;
        
        double rate;
        String category;

        if (isFdc && emp['negotiatedSalary'] != null) {
          rate = (emp['negotiatedSalary'] ?? 0).toDouble();
          category = "Sueldo Acordado";
        } else {
          rate = (emp['wageScale'] != null) ? (emp['wageScale']['basicValue'] ?? 0).toDouble() : 0;
          category = (emp['wageScale'] != null) ? emp['wageScale']['categoryName'] : "Sin Cat.";
        }

        // --- CORRECCIÓN AQUÍ: BÚSQUEDA ROBUSTA DE OBRA ---
        String obraAsignada = "Sin Asignar";
        
        if (emp['currentProjectId'] != null && projects.isNotEmpty) {
           try {
             // Comparamos convirtiendo a String y minúsculas para evitar error por mayúsculas
             final proj = projects.firstWhere(
               (p) => p['id'].toString().toLowerCase() == emp['currentProjectId'].toString().toLowerCase(), 
               orElse: () => null
             );
             if (proj != null) obraAsignada = proj['name'];
           } catch (e) {
             // Si falla algo, queda en "Sin Asignar"
           }
        }
        // ------------------------------------------------

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isHourly ? Colors.orange : (isFdc ? Colors.purple : Colors.blue),
              child: Text(emp['lastName'].isNotEmpty ? emp['lastName'][0] : "?", style: const TextStyle(color: Colors.white)),
            ),
            title: Text("${emp['lastName']}, ${emp['firstName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            
            // Subtítulo con Obra bien visible
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isFdc ? "Fuera de Convenio" : category),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.apartment, size: 14, color: obraAsignada == "Sin Asignar" ? Colors.red : Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      obraAsignada, 
                      style: TextStyle(
                        color: obraAsignada == "Sin Asignar" ? Colors.red : Colors.green[700], 
                        fontWeight: FontWeight.bold
                      )
                    )
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("\$$rate", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(isHourly ? "Jornal Hora" : "Mensual", style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EmployeeDetailScreen(employee: emp)),
              );
              if (result == true) loadData(); 
            },
          ),
        );
      },
    );
  }
}