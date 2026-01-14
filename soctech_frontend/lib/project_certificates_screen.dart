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
  // CONFIGURACIÓN DE RED (IP Segura para Windows)
  final String baseUrl = 'http://127.0.0.1:5064/api';

  List<dynamic> certificates = [];
  bool isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

  // Controladores
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _percentController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool isSaving = false; // Para evitar doble click al guardar

  @override
  void initState() {
    super.initState();
    fetchCertificates();
  }

  Future<void> fetchCertificates() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/ProjectCertificates'));
      
      if (response.statusCode == 200) {
        // 🛡️ DECODIFICACIÓN SEGURA
        final List<dynamic> allCerts = json.decode(response.body) as List<dynamic>;
        
        if (mounted) {
          setState(() {
            // Filtramos por ID de proyecto de forma segura
            certificates = allCerts.where((c) => c['projectId'].toString() == widget.project['id'].toString()).toList();
            
            // Ordenamos por fecha (más reciente primero)
            certificates.sort((a, b) {
              DateTime dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1900);
              DateTime dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1900);
              return dateB.compareTo(dateA);
            });
            
            isLoading = false;
          });
        }
      } else {
        throw Exception("Error ${response.statusCode}");
      }
    } catch (e) {
      print("Error cargando certificados: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> addCertificate() async {
    if (_amountController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El monto es obligatorio")));
       return;
    }

    setState(() => isSaving = true);

    final newCert = {
      "projectId": widget.project['id'],
      "date": selectedDate.toIso8601String(),
      "amount": double.tryParse(_amountController.text) ?? 0,
      "percentage": double.tryParse(_percentController.text) ?? 0,
      "note": _noteController.text.isEmpty ? "Certificado de Avance" : _noteController.text
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ProjectCertificates'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(newCert),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context); // Cierra el diálogo
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Certificado generado correctamente"), backgroundColor: Colors.green));
          
          // Limpieza
          _amountController.clear();
          _noteController.clear();
          _percentController.clear();
          
          // Recarga la lista
          fetchCertificates();
        }
      } else {
        throw Exception("Error al guardar: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void showAddDialog() {
    // Reseteamos fecha al abrir
    selectedDate = DateTime.now();
    
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
                    child: Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: isSaving ? null : addCertificate, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Generar Certificado"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cálculos Financieros Seguros
    double totalContract = (widget.project['contractAmount'] ?? widget.project['totalContractAmount'] ?? 0).toDouble(); // Probamos dos nombres comunes de variable
    double totalCertified = certificates.fold(0, (sum, item) => sum + (item['amount'] ?? 0));
    double progress = totalContract > 0 ? (totalCertified / totalContract) : 0;
    // Tope visual al 100%
    if (progress > 1.0) progress = 1.0; 

    return Scaffold(
      appBar: AppBar(title: Text("Ingresos: ${widget.project['name']}"), backgroundColor: Colors.green[700], foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddDialog,
        label: const Text("Certificar Avance"),
        icon: const Icon(Icons.receipt_long),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
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
                LinearProgressIndicator(value: progress, minHeight: 10, color: Colors.green, backgroundColor: Colors.grey.shade300, borderRadius: BorderRadius.circular(5)),
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
                ? const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 50, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("No hay certificados emitidos."),
                    ],
                  ))
                : ListView.builder(
                    itemCount: certificates.length,
                    itemBuilder: (context, index) {
                      final cert = certificates[index];
                      final dt = DateTime.tryParse(cert['date']) ?? DateTime.now();
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100, 
                            child: Icon(Icons.check, color: Colors.green.shade800)
                          ),
                          title: Text(cert['note'] ?? 'Sin concepto', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Fecha: ${DateFormat('dd/MM/yyyy').format(dt)} - Avance reportado: ${cert['percentage']}%"),
                          trailing: Text(
                            currencyFormat.format(cert['amount'] ?? 0),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade800),
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