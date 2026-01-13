import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart'; 
import 'employee_detail_screen.dart'; 

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> with SingleTickerProviderStateMixin {
  List<dynamic> employees = [];
  List<dynamic> wageScales = []; 
  List<dynamic> projects = []; 
  bool isLoading = true;

  late TabController _tabController;

  // Controladores Alta Manual
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cuilController = TextEditingController();
  final _salaryController = TextEditingController(); 
  
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
        if (mounted) {
          setState(() {
            employees = json.decode(resEmp.body);
            wageScales = json.decode(resScales.body);
            projects = json.decode(resProj.body); 
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if(mounted) setState(() => isLoading = false);
    }
  }

  // --- BORRAR TODOS LOS EMPLEADOS ---
  Future<void> deleteAllEmployees() async {
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ BORRAR TODO"),
        content: const Text("¿Estás seguro? Esto eliminará TODOS los legajos de la base de datos. No se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Sí, Eliminar Todo")
          ),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    setState(() => isLoading = true);
    try {
      final res = await http.delete(Uri.parse('http://localhost:5064/api/Employees/delete-all'));
      if (res.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🗑️ Base de empleados vaciada.")));
        loadData();
      } else {
        throw Exception("Error ${res.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al borrar: $e")));
    }
  }

  Future<void> importCsv() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      setState(() => isLoading = true);
      
      var platformFile = result.files.first;
      var request = http.MultipartRequest('POST', Uri.parse('http://localhost:5064/api/Employees/import'));
      
      // Para Windows usamos path, para web bytes (aquí usamos path)
      if (platformFile.path != null) {
        request.files.add(await http.MultipartFile.fromPath('file', platformFile.path!));
      }

      try {
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          int imported = data['imported'];
          int errors = data['errors'];

          if(mounted) {
            Color color = errors > 0 ? Colors.orange : Colors.green;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("✅ $imported legajos importados. ($errors errores)"), backgroundColor: color)
            );
          }
          loadData(); 
        } else {
          throw Exception("Error servidor: ${response.statusCode}");
        }
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al importar: $e")));
        setState(() => isLoading = false);
      }
    }
  }

  // ... (getFilteredScales, getActiveProjects, addEmployee, showAddDialog se mantienen igual)
  // Para ahorrar espacio, asumo que copias los métodos de lógica de alta manual del código anterior aquí.
  // Si los necesitas, avísame.
  // ...
  
  // MÉTODOS AUXILIARES FALTANTES PARA QUE COMPILE:
  List<dynamic> getFilteredScales() {
    int unionType = selectedUnion == "UOCRA" ? 0 : 1; 
    return wageScales.where((s) => s['union'] == unionType).toList();
  }

  List<dynamic> getActiveProjects() {
    return projects.where((p) => p['isActive'] == true).toList();
  }

  Future<void> addEmployee() async {
    // Lógica de alta manual (Idéntica al código anterior)
    // ...
  }
  
  void showAddDialog() {
      // Lógica de dialogo (Idéntica al código anterior)
      // ...
  }
  // ...

  @override
  Widget build(BuildContext context) {
    final listUocra = employees.where((e) => e['union'] == 0).toList();
    final listAdmin = employees.where((e) => e['union'] == 1 || e['union'] == 2).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Recursos Humanos"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // BOTÓN BORRAR TODO
          IconButton(
            onPressed: deleteAllEmployees, 
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            tooltip: "Borrar toda la nómina",
          ),
          // BOTÓN IMPORTAR CSV
          Padding(
            padding: const EdgeInsets.only(right: 15, left: 10),
            child: TextButton.icon(
              onPressed: importCsv,
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text("Importar CSV", style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
              ),
            ),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.construction), text: "OBRA (UOCRA)"),
            Tab(icon: Icon(Icons.computer), text: "ADMIN / FDC"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddDialog, // Asegúrate de tener este método del código anterior
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

  // ESTA ES LA LISTA BONITA QUE HICIMOS ANTES
  Widget _buildEmployeeList(List<dynamic> list, {required bool isHourly}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("No hay legajos aquí", style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.separated( 
      itemCount: list.length,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), 
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
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
          category = (emp['wageScale'] != null) ? emp['wageScale']['categoryName'] : "Sin Categoría";
        }

        String obraAsignada = "Sin Asignar";
        if (emp['currentProjectId'] != null && projects.isNotEmpty) {
           try {
             final proj = projects.firstWhere(
               (p) => p['id'].toString().toLowerCase() == emp['currentProjectId'].toString().toLowerCase(), 
               orElse: () => null
             );
             if (proj != null) obraAsignada = proj['name'];
           } catch (e) {}
        }
        
        Color avatarColor = isHourly ? Colors.orange.shade700 : (isFdc ? Colors.purple.shade700 : Colors.blue.shade700);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.grey.shade200, blurRadius: 6, offset: const Offset(0, 3))
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EmployeeDetailScreen(employee: emp)),
                );
                if (result == true) loadData(); 
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: avatarColor.withOpacity(0.1),
                      child: Text(
                        emp['lastName'] != null && emp['lastName'].isNotEmpty ? emp['lastName'][0] : "?", 
                        style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 20)
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${emp['lastName'] ?? ''}, ${emp['firstName'] ?? emp['fullName'] ?? 'Desconocido'}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(category, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: obraAsignada == "Sin Asignar" ? Colors.red.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: obraAsignada == "Sin Asignar" ? Colors.red.shade200 : Colors.green.shade200)
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.apartment, size: 12, color: obraAsignada == "Sin Asignar" ? Colors.red.shade700 : Colors.green.shade700),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    obraAsignada,
                                    style: TextStyle(
                                      fontSize: 11, fontWeight: FontWeight.bold,
                                      color: obraAsignada == "Sin Asignar" ? Colors.red.shade700 : Colors.green.shade700
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("\$${rate.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)),
                        Text(isHourly ? "/hora" : "/mes", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}