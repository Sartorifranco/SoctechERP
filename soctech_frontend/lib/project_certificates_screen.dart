import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ProjectCertificatesScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProjectCertificatesScreen({super.key, required this.project});

  @override
  State<ProjectCertificatesScreen> createState() => _ProjectCertificatesScreenState();
}

class _ProjectCertificatesScreenState extends State<ProjectCertificatesScreen> {
  List<dynamic> certificates = [];
  bool isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

  // Controladores para nuevo certificado
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _percentController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchCertificates();
  }

  Future<void> fetchCertificates() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/ProjectCertificates'));
      if (response.statusCode == 200) {
        List<dynamic> allCerts = json.decode(response.body);
        setState(() {
          // Filtramos solo los de ESTA obra
          certificates = allCerts.where((c) => c['projectId'] == widget.project['id']).toList();
          // Ordenamos por fecha descendente
          certificates.sort((a, b) => b['date'].compareTo(a['date']));
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> addCertificate() async {
    if (_amountController.text.isEmpty) return;

    final newCert = {
      "projectId": widget.project['id'],
      "date": selectedDate.toIso8601String(),
      "amount": double.tryParse(_amountController.text) ?? 0,
      "percentage": double.tryParse(_percentController.text) ?? 0,
      "note": _noteController.text
    };

    try {
      await http.post(
        Uri.parse('http://localhost:5064/api/ProjectCertificates'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(newCert),
      );
      Navigator.pop(context);
      fetchCertificates();
      _amountController.clear();
      _noteController.clear();
      _percentController.clear();
    } catch (e) {
      print(e);
    }
  }

  void showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuevo Certificado de Avance"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: "Concepto (Ej: Certificado Nº 1)", icon: Icon(Icons.description)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _percentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "% Avance", suffixText: "%"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Monto a Cobrar", prefixText: "\$"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Fecha de Emisión:"),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (d != null) setState(() => selectedDate = d);
                    },
                    child: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  )
                ],
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(onPressed: addCertificate, child: const Text("Generar Certificado")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cálculos Financieros
    double totalContract = (widget.project['totalContractAmount'] ?? 0).toDouble();
    double totalCertified = certificates.fold(0, (sum, item) => sum + (item['amount'] ?? 0));
    double progress = totalContract > 0 ? (totalCertified / totalContract) : 0;

    return Scaffold(
      appBar: AppBar(title: Text("Ingresos: ${widget.project['name']}")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddDialog,
        label: const Text("Certificar Avance"),
        icon: const Icon(Icons.receipt_long),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // --- TARJETA DE RESUMEN FINANCIERO ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.green.shade50,
            child: Column(
              children: [
                const Text("ESTADO DEL CONTRATO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 10),
                Text(currencyFormat.format(totalCertified), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                Text("Cobrado / Certificado hasta la fecha", style: TextStyle(color: Colors.green.shade700)),
                const SizedBox(height: 15),
                
                // BARRA DE PROGRESO DEL CONTRATO
                LinearProgressIndicator(value: progress, minHeight: 10, color: Colors.green, backgroundColor: Colors.grey.shade300),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${(progress * 100).toStringAsFixed(1)}% Ejecutado"),
                    Text("Total Contrato: ${currencyFormat.format(totalContract)}"),
                  ],
                )
              ],
            ),
          ),

          // --- LISTA DE CERTIFICADOS ---
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator())
              : certificates.isEmpty 
                ? const Center(child: Text("No hay certificados emitidos."))
                : ListView.builder(
                    itemCount: certificates.length,
                    itemBuilder: (context, index) {
                      final cert = certificates[index];
                      final dt = DateTime.parse(cert['date']);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
                          title: Text(cert['note']),
                          subtitle: Text("Fecha: ${DateFormat('dd/MM/yyyy').format(dt)} - Avance: ${cert['percentage']}%"),
                          trailing: Text(
                            currencyFormat.format(cert['amount']),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}