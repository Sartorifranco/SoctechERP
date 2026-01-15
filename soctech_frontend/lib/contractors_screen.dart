import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ContractorsScreen extends StatefulWidget {
  const ContractorsScreen({super.key});

  @override
  State<ContractorsScreen> createState() => _ContractorsScreenState();
}

class _ContractorsScreenState extends State<ContractorsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<dynamic> contractors = [];
  List<dynamic> jobs = [];
  List<dynamic> projects = []; // Necesitamos las obras para asignarles trabajo

  bool isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

  // Controladores
  final _nameController = TextEditingController();
  final _tradeController = TextEditingController(); // Rubro
  final _cuitController = TextEditingController();
  
  // Controladores para Trabajo
  final _jobDescController = TextEditingController();
  final _amountController = TextEditingController();
  String? selectedContractorId;
  String? selectedProjectId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final resCont = await http.get(Uri.parse('http://127.0.0.1:5064/api/Contractors'));
      final resJobs = await http.get(Uri.parse('http://127.0.0.1:5064/api/Contractors/jobs'));
      final resProj = await http.get(Uri.parse('http://127.0.0.1:5064/api/Projects'));

      if (resCont.statusCode == 200 && resJobs.statusCode == 200) {
        setState(() {
          contractors = json.decode(resCont.body);
          jobs = json.decode(resJobs.body);
          projects = json.decode(resProj.body).where((p) => p['isActive'] == true).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // --- CREAR CONTRATISTA ---
  Future<void> addContractor() async {
    final newC = {
      "name": _nameController.text,
      "trade": _tradeController.text,
      "cuit": _cuitController.text,
      "isActive": true
    };
    await http.post(Uri.parse('http://127.0.0.1:5064/api/Contractors'),
        headers: {"Content-Type": "application/json"}, body: json.encode(newC));
    
    _nameController.clear(); _tradeController.clear(); _cuitController.clear();
    Navigator.pop(context);
    fetchData();
  }

  // --- ASIGNAR TRABAJO ---
  Future<void> addJob() async {
    if(selectedContractorId == null || selectedProjectId == null) return;

    final newJob = {
      "contractorId": selectedContractorId,
      "projectId": selectedProjectId,
      "description": _jobDescController.text,
      "agreedAmount": double.tryParse(_amountController.text) ?? 0,
      "startDate": DateTime.now().toIso8601String(),
      "isPaid": false
    };

    await http.post(Uri.parse('http://127.0.0.1:5064/api/Contractors/jobs'),
        headers: {"Content-Type": "application/json"}, body: json.encode(newJob));

    _jobDescController.clear(); _amountController.clear();
    Navigator.pop(context);
    fetchData();
  }

  // --- MARCAR PAGADO ---
  Future<void> markAsPaid(String jobId) async {
    await http.put(Uri.parse('http://127.0.0.1:5064/api/Contractors/jobs/$jobId/pay'));
    fetchData();
  }

  // --- DIÁLOGOS ---
  void showContractorDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Nuevo Contratista"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nombre / Razón Social")),
        TextField(controller: _tradeController, decoration: const InputDecoration(labelText: "Rubro (Ej: Electricista)")),
        TextField(controller: _cuitController, decoration: const InputDecoration(labelText: "CUIT / DNI")),
      ]),
      actions: [ElevatedButton(onPressed: addContractor, child: const Text("Guardar"))],
    ));
  }

  void showJobDialog() {
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text("Asignar Nuevo Trabajo"),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Contratista"),
              items: contractors.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c['id'], child: Text(c['name']))).toList(),
              onChanged: (v) => setDialogState(() => selectedContractorId = v),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Obra"),
              items: projects.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']))).toList(),
              onChanged: (v) => setDialogState(() => selectedProjectId = v),
            ),
            TextField(controller: _jobDescController, decoration: const InputDecoration(labelText: "Descripción Tarea")),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Monto Pactado (\$)", icon: Icon(Icons.attach_money))),
          ]),
        ),
        actions: [ElevatedButton(onPressed: addJob, child: const Text("Asignar"))],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestión de Subcontratistas"),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: "DIRECTORIO"), Tab(text: "TRABAJOS ACTIVOS")]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabController.index == 0 ? showContractorDialog() : showJobDialog(),
        child: const Icon(Icons.add),
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: LISTA DE CONTRATISTAS
          ListView.builder(
            itemCount: contractors.length,
            itemBuilder: (ctx, i) {
              final c = contractors[i];
              return Card(child: ListTile(
                leading: CircleAvatar(child: Text(c['name'][0])),
                title: Text(c['name']),
                subtitle: Text("${c['trade']} - CUIT: ${c['cuit']}"),
              ));
            },
          ),
          // TAB 2: TRABAJOS
          ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (ctx, i) {
              final job = jobs[i];
              // Buscamos nombres para mostrar bonito
              final contractorName = contractors.firstWhere((c) => c['id'] == job['contractorId'], orElse: () => {'name': '?'})['name'];
              final projectName = projects.firstWhere((p) => p['id'] == job['projectId'], orElse: () => {'name': '?'})['name'];
              bool isPaid = job['isPaid'] ?? false;

              return Card(
                color: isPaid ? Colors.green.shade50 : Colors.white,
                child: ListTile(
                  title: Text(contractorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Obra: $projectName"),
                    Text(job['description']),
                    Text("Monto: ${currencyFormat.format(job['agreedAmount'])}", style: TextStyle(color: Colors.indigo.shade800, fontWeight: FontWeight.bold)),
                  ]),
                  trailing: isPaid 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        onPressed: () => markAsPaid(job['id']),
                        child: const Text("PAGAR"),
                      ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}