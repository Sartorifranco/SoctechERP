import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'project_certificates_screen.dart'; // <--- IMPORTAR LA NUEVA PANTALLA

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<dynamic> projects = [];
  bool isLoading = true;
  
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contractController = TextEditingController(); // <--- NUEVO CONTROLADOR

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/Projects'));
      if (response.statusCode == 200) {
        setState(() {
          projects = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  Future<void> addProject() async {
    final newProject = {
      "name": _nameController.text,
      "address": _addressController.text,
      "totalContractAmount": double.tryParse(_contractController.text) ?? 0, // <--- GUARDAMOS CONTRATO
      "isActive": true
    };

    await http.post(
      Uri.parse('http://localhost:5064/api/Projects'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(newProject),
    );

    _nameController.clear();
    _addressController.clear();
    _contractController.clear();
    Navigator.pop(context);
    fetchProjects();
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nueva Obra"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nombre del Proyecto")),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: "Dirección")),
            TextField(controller: _contractController, decoration: const InputDecoration(labelText: "Monto Total Contrato (\$)", icon: Icon(Icons.attach_money)), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(onPressed: addProject, child: const Text("Guardar")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Obras Activas")),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
                double contract = (project['totalContractAmount'] ?? 0).toDouble();

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.apartment)),
                    title: Text(project['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project['address']),
                        Text("Contrato: ${currencyFormat.format(contract)}", style: TextStyle(color: Colors.green[800], fontSize: 12)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.receipt_long, color: Colors.blue), // Icono de Ingresos
                      tooltip: "Certificaciones / Cobros",
                      onPressed: () {
                        // NAVEGAR A CERTIFICACIONES
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => ProjectCertificatesScreen(project: project))
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}