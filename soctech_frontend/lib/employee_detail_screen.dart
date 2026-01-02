import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; 

class EmployeeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employee;

  const EmployeeDetailScreen({super.key, required this.employee});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> currentData;
  
  List<dynamic> employeeLogs = [];
  List<dynamic> projects = []; // <--- LISTA DE OBRAS PARA EL DESPLEGABLE
  bool isLoadingLogs = true;
  DateTime selectedPayrollDate = DateTime.now();

  final _addressController = TextEditingController();
  final _salaryController = TextEditingController(); // Para editar sueldo si es FDC

  // Formato moneda
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

  @override
  void initState() {
    super.initState();
    currentData = widget.employee;
    _tabController = TabController(length: 3, vsync: this);
    
    // Inicializar controladores con datos actuales
    _addressController.text = currentData['address'] ?? "";
    if (currentData['negotiatedSalary'] != null) {
      _salaryController.text = currentData['negotiatedSalary'].toString();
    }

    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      // 1. Logs de Trabajo
      final resLogs = await http.get(Uri.parse('http://localhost:5064/api/WorkLogs'));
      // 2. Lista de Proyectos (Para poder asignar obra en Editar)
      final resProj = await http.get(Uri.parse('http://localhost:5064/api/Projects'));

      if (resLogs.statusCode == 200) {
        List<dynamic> allLogs = json.decode(resLogs.body);
        setState(() {
          employeeLogs = allLogs.where((l) => l['employeeId'] == currentData['id']).toList();
          employeeLogs.sort((a, b) => b['date'].compareTo(a['date']));
          
          if (resProj.statusCode == 200) {
            projects = json.decode(resProj.body).where((p) => p['isActive'] == true).toList();
          }
          
          isLoadingLogs = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  // --- REGISTRAR AUSENCIA ---
  Future<void> reportAbsence() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedPayrollDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: "SELECCIONA EL DÍA DE LA FALTA"
    );

    if (pickedDate == null) return;

    final absenceLog = {
      "employeeId": currentData['id'],
      "projectId": currentData['currentProjectId'], // Imputamos la falta a su obra actual
      "date": pickedDate.toIso8601String(),
      "hoursWorked": 0,
      "registeredRateSnapshot": 0,
      "notes": "AUSENTE"
    };

    try {
      await http.post(
        Uri.parse('http://localhost:5064/api/WorkLogs'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(absenceLog),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ausencia registrada. Se descontará el presentismo."), backgroundColor: Colors.red)
      );
      loadInitialData(); // Recargar
    } catch (e) {
      print(e);
    }
  }

  // --- EDITAR EMPLEADO (AHORA CON ASIGNACIÓN DE OBRA) ---
  Future<void> editEmployee() async {
    String? tempProjectId = currentData['currentProjectId'];
    bool isFdc = currentData['union'] == 2;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Editar Legajo"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Datos de Ubicación", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const Divider(),
                    
                    // --- SELECTOR DE OBRA (LO QUE FALTABA) ---
                    DropdownButtonFormField<String>(
                      value: tempProjectId,
                      decoration: const InputDecoration(labelText: "Obra Asignada", icon: Icon(Icons.apartment)),
                      items: projects.map<DropdownMenuItem<String>>((p) {
                        return DropdownMenuItem(value: p['id'], child: Text(p['name']));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => tempProjectId = val),
                      hint: const Text("Sin Asignar"),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: "Domicilio Real", icon: Icon(Icons.home)),
                    ),

                    // Si es FDC, permitimos editar el sueldo aquí también
                    if (isFdc) ...[
                      const SizedBox(height: 15),
                      const Divider(),
                      const Text("Condiciones FDC", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      TextField(
                        controller: _salaryController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Sueldo Acordado (\$)", icon: Icon(Icons.attach_money)),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () async {
                    // Copiamos datos actuales
                    Map<String, dynamic> updatedEmp = Map.from(currentData);
                    
                    // Actualizamos con lo nuevo
                    updatedEmp['address'] = _addressController.text;
                    updatedEmp['currentProjectId'] = tempProjectId; // <--- GUARDAMOS LA OBRA
                    updatedEmp['wageScale'] = null; // Limpieza para evitar error de objeto anidado

                    if (isFdc && _salaryController.text.isNotEmpty) {
                      updatedEmp['negotiatedSalary'] = double.tryParse(_salaryController.text);
                    }

                    try {
                      final response = await http.put(
                        Uri.parse('http://localhost:5064/api/Employees/${currentData['id']}'),
                        headers: {"Content-Type": "application/json"},
                        body: json.encode(updatedEmp),
                      );

                      if (response.statusCode == 204) {
                        setState(() {
                          currentData = updatedEmp; // Actualizamos vista local
                          // Hack visual: recuperamos el nombre de la obra si cambió, aunque currentData solo tiene el ID
                          // Al volver atrás se recargará bien.
                        });
                        Navigator.pop(context, true); // True avisa que hubo cambios
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Legajo actualizado correctamente")));
                      } else {
                        throw Exception("Error ${response.statusCode}");
                      }
                    } catch (e) {
                      print(e);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                  child: const Text("Guardar Cambios"),
                )
              ],
            );
          }
        );
      },
    );
  }

  Future<void> deleteEmployee() async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Desvincular Empleado?"),
        content: const Text("El empleado pasará a estado Inactivo."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("CONFIRMAR BAJA", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await http.delete(Uri.parse('http://localhost:5064/api/Employees/${currentData['id']}'));
        if (mounted) Navigator.pop(context, true); 
      } catch (e) {
        print(e);
      }
    }
  }

  // --- CÁLCULO CIENTÍFICO v5.0 ---
  Map<String, double> calculateSalary() {
    double totalBruto = 0;
    double totalHoras = 0;
    double totalAdicionales = 0;
    
    bool isUocra = currentData['union'] == 0; 
    bool isUecara = currentData['union'] == 1;
    bool isFdc = currentData['union'] == 2; 

    double baseValue = 0;
    if (currentData['negotiatedSalary'] != null && currentData['negotiatedSalary'] > 0) {
      baseValue = (currentData['negotiatedSalary']).toDouble();
    } else {
      baseValue = currentData['wageScale'] != null 
          ? (currentData['wageScale']['basicValue'] ?? 0).toDouble() 
          : 0;
    }

    final logsDelMes = employeeLogs.where((log) {
      DateTime dt = DateTime.parse(log['date']);
      return dt.month == selectedPayrollDate.month && dt.year == selectedPayrollDate.year;
    });

    bool lostPresenteeism = logsDelMes.any((log) {
      String nota = (log['notes'] ?? "").toString().toUpperCase().trim();
      return nota.contains("AUSENTE");
    });

    if (logsDelMes.isEmpty && (isUecara || isFdc)) {
      totalBruto = baseValue; 
      totalHoras = 200; 
    } else {
      for (var log in logsDelMes) {
        String nota = (log['notes'] ?? "").toString().toUpperCase();
        if (nota.contains("AUSENTE")) continue;

        double hours = (log['hoursWorked'] ?? 0).toDouble();
        double rate = (log['registeredRateSnapshot'] > 0) 
            ? (log['registeredRateSnapshot'] ?? 0).toDouble() 
            : baseValue;

        totalHoras += hours;

        if (isUocra) {
          totalBruto += (hours * rate);
        } else {
          totalBruto += (hours * (rate / 200)); 
        }
      }
    }

    // ADICIONALES
    double porcentajePresentismo = 0;
    if (!lostPresenteeism) {
      if (isUocra) porcentajePresentismo = 0.20; 
      if (isUecara || isFdc) porcentajePresentismo = 0.10; 
    }
    double montoPresentismo = totalBruto * porcentajePresentismo;
    totalAdicionales += montoPresentismo;

    double montoAntiguedad = 0;
    int yearsWorked = 0;
    DateTime entry = DateTime.parse(currentData['entryDate']);
    yearsWorked = DateTime.now().difference(entry).inDays ~/ 365;

    if (isUecara || isFdc) {
      montoAntiguedad = totalBruto * (0.01 * yearsWorked);
      totalAdicionales += montoAntiguedad;
    }

    double brutoFinal = totalBruto + totalAdicionales;

    // RETENCIONES
    double descJubilacion = brutoFinal * 0.11;
    double descLey = brutoFinal * 0.03;
    double descObraSocial = brutoFinal * 0.03;
    
    double sindicatoPorc = 0;
    if (isUocra) sindicatoPorc = 0.025;
    if (isUecara) sindicatoPorc = 0.02;
    double descSindicato = brutoFinal * sindicatoPorc;

    double totalDescuentos = descJubilacion + descLey + descObraSocial + descSindicato;
    double neto = brutoFinal - totalDescuentos;

    // PATRONALES (FCL)
    double fondoCeseLaboral = 0;
    double alicuotaFCL = 0;
    if (isUocra) {
      alicuotaFCL = yearsWorked < 1 ? 0.12 : 0.08;
      fondoCeseLaboral = brutoFinal * alicuotaFCL;
    }

    return {
      "basico": totalBruto,
      "presentismo": montoPresentismo,
      "antiguedad": montoAntiguedad,
      "bruto": brutoFinal,
      "neto": neto,
      "horas": totalHoras,
      "jubilacion": descJubilacion,
      "ley19032": descLey,
      "os": descObraSocial,
      "sindicato": descSindicato,
      "lostPresenteeism": lostPresenteeism ? 1.0 : 0.0,
      "fondoCese": fondoCeseLaboral,
      "alicuotaFCL": alicuotaFCL * 100
    };
  }

  @override
  Widget build(BuildContext context) {
    final scaleName = currentData['wageScale'] != null ? currentData['wageScale']['categoryName'] : "Sin Categoría";
    final salaryData = calculateSalary();
    bool isFdc = currentData['union'] == 2;
    bool isUocra = currentData['union'] == 0;
    bool presentismoPerdido = salaryData['lostPresenteeism'] == 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Legajo Digital"),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: editEmployee),
          IconButton(icon: const Icon(Icons.delete_forever), onPressed: deleteEmployee),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "PERFIL"),
            Tab(text: "ASISTENCIA"),
            Tab(text: "LIQUIDACIÓN"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: PERFIL
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 60)),
              const SizedBox(height: 10),
              Center(child: Text("${currentData['lastName']}, ${currentData['firstName']}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              Center(child: Chip(
                label: Text(isFdc ? "FUERA DE CONVENIO" : scaleName), 
                backgroundColor: isFdc ? Colors.purple.shade100 : Colors.indigo.shade100
              )),
              const Divider(height: 30),
              ListTile(leading: const Icon(Icons.badge), title: const Text("CUIL"), subtitle: Text(currentData['cuil'] ?? "-")),
              ListTile(leading: const Icon(Icons.home), title: const Text("Domicilio"), subtitle: Text(currentData['address'] ?? "-")),
              // AQUI MOSTRAMOS LA OBRA ASIGNADA EN EL PERFIL
              ListTile(
                leading: const Icon(Icons.apartment), 
                title: const Text("Obra Asignada"), 
                // Buscamos el nombre del proyecto en la lista cargada
                subtitle: Text(
                  projects.firstWhere((p) => p['id'] == currentData['currentProjectId'], orElse: () => {'name': 'Sin Asignar'})['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)
                )
              ),
              if (isFdc && currentData['negotiatedSalary'] != null)
                 ListTile(leading: const Icon(Icons.attach_money), title: const Text("Sueldo Acordado"), subtitle: Text(currencyFormat.format(currentData['negotiatedSalary']))),
            ],
          ),

          // TAB 2: ASISTENCIA
          Stack(
            children: [
              isLoadingLogs 
                ? const Center(child: CircularProgressIndicator())
                : employeeLogs.isEmpty
                  ? const Center(child: Text("Sin registros."))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: employeeLogs.length,
                      itemBuilder: (context, index) {
                        final log = employeeLogs[index];
                        final dt = DateTime.parse(log['date']);
                        bool isAbsent = (log['notes'] ?? "").toString().toUpperCase().contains("AUSENTE");

                        return ListTile(
                          leading: Icon(
                            isAbsent ? Icons.cancel : Icons.check_circle_outline, 
                            color: isAbsent ? Colors.red : Colors.green
                          ),
                          title: Text(
                            isAbsent ? "AUSENTE (Injustificada)" : "${log['hoursWorked']} horas trabajadas",
                            style: TextStyle(
                              color: isAbsent ? Colors.red : Colors.black,
                              fontWeight: isAbsent ? FontWeight.bold : FontWeight.normal
                            ),
                          ),
                          subtitle: Text(DateFormat('dd/MM/yyyy').format(dt)),
                        );
                      },
                    ),
              
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.extended(
                  onPressed: reportAbsence,
                  label: const Text("Reportar Ausencia"),
                  icon: const Icon(Icons.person_off),
                  backgroundColor: Colors.redAccent,
                ),
              )
            ],
          ),

          // TAB 3: LIQUIDACIÓN
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Periodo a Liquidar:", style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: Text("${selectedPayrollDate.month}/${selectedPayrollDate.year}", style: const TextStyle(fontSize: 16)),
                        onPressed: () async {
                           final d = await showDatePicker(context: context, initialDate: selectedPayrollDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                           if (d != null) setState(() => selectedPayrollDate = d);
                        },
                      )
                    ],
                  ),
                  const Divider(),
                  
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)]
                    ),
                    child: Column(
                      children: [
                        const Text("LIQUIDACIÓN DE HABERES", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const SizedBox(height: 15),
                        
                        _rowLiq(
                          salaryData['horas'] == 200 ? "Sueldo Mensual" : "Básico (${salaryData['horas']!.toStringAsFixed(1)} hs)", 
                          currencyFormat.format(salaryData['basico']), 
                          Colors.black
                        ),
                        
                        if (salaryData['antiguedad']! > 0)
                           _rowLiq("Antigüedad", currencyFormat.format(salaryData['antiguedad']), Colors.black),
                        
                        _rowLiq(
                          presentismoPerdido ? "Presentismo (PERDIDO)" : "Presentismo (Beneficio)", 
                          currencyFormat.format(salaryData['presentismo']), 
                          presentismoPerdido ? Colors.red : Colors.black
                        ),
                        
                        const Divider(thickness: 1),
                        _rowLiq("TOTAL BRUTO", currencyFormat.format(salaryData['bruto']), Colors.black, isBold: true),
                        const Divider(thickness: 1),

                        _rowLiq("Jubilación (11%)", "-${currencyFormat.format(salaryData['jubilacion'])}", Colors.red.shade700),
                        _rowLiq("Obra Social (3%)", "-${currencyFormat.format(salaryData['os'])}", Colors.red.shade700),
                        if (salaryData['sindicato']! > 0)
                          _rowLiq("Sindicato", "-${currencyFormat.format(salaryData['sindicato'])}", Colors.red.shade700),
                        
                        const Divider(thickness: 2),
                        Container(
                          padding: const EdgeInsets.all(10),
                          color: Colors.green.shade50,
                          child: _rowLiq("NETO A COBRAR", currencyFormat.format(salaryData['neto']), Colors.green.shade800, isBold: true, size: 20),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (isUocra)
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Column(
                        children: [
                          Row(children: [Icon(Icons.business_center, color: Colors.orange[800]), SizedBox(width: 10), Text("OBLIGACIONES EMPLEADOR (IERIC)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[900]))]),
                          const Divider(),
                          const Text("Fondo de Cese Laboral (A depositar)", style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Alicuota: ${salaryData['alicuotaFCL']!.toStringAsFixed(0)}%"),
                              Text(currencyFormat.format(salaryData['fondoCese']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowLiq(String label, String value, Color color, {bool isBold = false, double size = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: size, color: Colors.grey[800]))),
          Text(value, style: TextStyle(fontSize: size, color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}