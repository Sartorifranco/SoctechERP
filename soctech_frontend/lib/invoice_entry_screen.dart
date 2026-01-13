import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; 

class InvoiceEntryScreen extends StatefulWidget {
  const InvoiceEntryScreen({super.key});

  @override
  State<InvoiceEntryScreen> createState() => _InvoiceEntryScreenState();
}

class _InvoiceEntryScreenState extends State<InvoiceEntryScreen> {
  // Datos Maestros
  List<dynamic> providers = [];
  List<dynamic> purchaseOrders = [];
  List<dynamic> projects = []; 
  
  bool isLoading = true;
  bool isSaving = false;

  // Selecciones
  String? selectedProviderId;
  String? selectedOrderId; 
  String? selectedProjectId;

  // Controladores
  final _invoiceNumCtrl = TextEditingController();
  final _netAmountCtrl = TextEditingController(text: "0.00");
  final _vatAmountCtrl = TextEditingController(text: "0.00");
  final _taxesAmountCtrl = TextEditingController(text: "0.00");
  
  // Variables calculadas
  double totalCalculated = 0;
  DateTime selectedDate = DateTime.now();
  DateTime selectedDueDate = DateTime.now().add(const Duration(days: 30));

  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

  @override
  void initState() {
    super.initState();
    loadMasterData();
    
    _netAmountCtrl.addListener(_calculateTotal);
    _vatAmountCtrl.addListener(_calculateTotal);
    _taxesAmountCtrl.addListener(_calculateTotal);
  }

  Future<void> loadMasterData() async {
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('http://localhost:5064/api/Providers')),       // [0]
        http.get(Uri.parse('http://localhost:5064/api/PurchaseOrders')),  // [1]
        http.get(Uri.parse('http://localhost:5064/api/Projects')),        // [2]
      ]);

      if (responses[0].statusCode == 200) {
        setState(() {
          providers = json.decode(responses[0].body);
          purchaseOrders = json.decode(responses[1].body);
          
          projects = json.decode(responses[2].body)
              .where((p) => p['isActive'] == true)
              .toList();
              
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando datos: $e");
      setState(() => isLoading = false);
    }
  }

  void onOrderSelected(String? orderId) {
    setState(() {
      selectedOrderId = orderId;
    });

    if (orderId != null) {
      final order = purchaseOrders.firstWhere((o) => o['id'] == orderId);
      
      double totalOrden = (order['totalAmount'] ?? 0).toDouble();
      double netoEstimado = totalOrden / 1.21;
      double ivaEstimado = totalOrden - netoEstimado;

      _netAmountCtrl.text = netoEstimado.toStringAsFixed(2);
      _vatAmountCtrl.text = ivaEstimado.toStringAsFixed(2);
      _taxesAmountCtrl.text = "0.00";
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Datos importados de la Orden #${order['orderNumber']}"),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(milliseconds: 1500),
        )
      );
    }
  }

  void _calculateTotal() {
    double net = double.tryParse(_netAmountCtrl.text) ?? 0;
    double vat = double.tryParse(_vatAmountCtrl.text) ?? 0;
    double tax = double.tryParse(_taxesAmountCtrl.text) ?? 0;
    
    setState(() {
      totalCalculated = net + vat + tax;
    });
  }

  // --- FUNCIÓN DE ESCANEO IA (CORREGIDA) ---
  Future<void> scanInvoiceWithAI() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery); 
    
    if (image == null) return; 

    setState(() => isLoading = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🤖 La IA está analizando el comprobante...")));

    try {
      // -----------------------------------------------------------------------
      // ✅ CORRECCIÓN AQUÍ: Apuntamos al nuevo controlador 'api/Ai/scan-invoice'
      // -----------------------------------------------------------------------
      var request = http.MultipartRequest('POST', Uri.parse('http://localhost:5064/api/Ai/scan-invoice'));
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          // Numero de factura
          if (data['invoiceNumber'] != null) {
             _invoiceNumCtrl.text = data['invoiceNumber'];
          }
          
          // Fecha
          if (data['date'] != null) {
            try {
               selectedDate = DateTime.parse(data['date']);
            } catch(e) {
               print("No se pudo parsear fecha IA");
            }
          }

          // Montos
          _netAmountCtrl.text = (data['netAmount'] ?? 0).toString();
          _vatAmountCtrl.text = (data['vatAmount'] ?? 0).toString();
          
          // INTELIGENCIA DE PROVEEDOR
          String aiProviderName = (data['providerName'] ?? "").toString().toLowerCase();
          if (aiProviderName.isNotEmpty) {
             try {
               var match = providers.firstWhere(
                 (p) => aiProviderName.contains(p['name'].toString().toLowerCase()) || 
                        p['name'].toString().toLowerCase().contains(aiProviderName)
               );
               selectedProviderId = match['id'];
             } catch (e) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Proveedor '${data['providerName']}' no reconocido. Seleccione manualmente.")));
             }
          }

          isLoading = false;
        });
        
        _calculateTotal();

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Datos extraídos correctamente"), backgroundColor: Colors.green));

      } else {
        throw Exception("Error del servidor: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Error IA"), content: Text(e.toString())));
    }
  }

  Future<void> saveInvoice() async {
    if (selectedProviderId == null || _invoiceNumCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Faltan datos obligatorios (Proveedor o Nro Factura)")));
      return;
    }

    setState(() => isSaving = true);

    final invoiceData = {
      "invoiceNumber": _invoiceNumCtrl.text,
      "invoiceDate": selectedDate.toIso8601String(),
      "dueDate": selectedDueDate.toIso8601String(),
      "providerId": selectedProviderId,
      "providerName": providers.firstWhere((p) => p['id'] == selectedProviderId)['name'],
      "relatedPurchaseOrderId": selectedOrderId, 
      "projectId": selectedProjectId, 
      "netAmount": double.parse(_netAmountCtrl.text),
      "vatAmount": double.parse(_vatAmountCtrl.text),
      "otherTaxes": double.parse(_taxesAmountCtrl.text),
      "totalAmount": totalCalculated,
      "status": "Draft" 
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5064/api/SupplierInvoices'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(invoiceData),
      );

      if (response.statusCode == 201) {
        if (mounted) {
           final created = json.decode(response.body);
           String statusMsg = created['status'] == "Flagged" 
              ? "Guardada, pero con diferencias de precio (Observada)" 
              : "Factura procesada y validada correctamente";
           
           Color color = created['status'] == "Flagged" ? Colors.orange : Colors.green;

           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(statusMsg), backgroundColor: color));
           Navigator.pop(context);
        }
      } else {
        throw Exception("Error ${response.body}");
      }
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  List<dynamic> getProviderOrders() {
    if (selectedProviderId == null) return [];
    return purchaseOrders.where((o) => o['providerId'] == selectedProviderId && o['status'] != 'Finished').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carga de Comprobantes"),
        backgroundColor: Colors.indigo.shade900, 
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: scanInvoiceWithAI,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text("ESCANEAR (IA)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, 

      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80), 
            child: Column(
              children: [
                // --- SECCIÓN 1: ENCABEZADO ---
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.indigo.shade50,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Seleccionar Proveedor",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.store),
                          filled: true,
                          fillColor: Colors.white
                        ),
                        value: selectedProviderId,
                        items: providers.map<DropdownMenuItem<String>>((p) {
                          return DropdownMenuItem(value: p['id'], child: Text(p['name']));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedProviderId = val;
                            selectedOrderId = null; 
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: "Vincular Orden de Compra (3-Way Match)",
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.receipt_long),
                                filled: true,
                                fillColor: Colors.white,
                                helperText: selectedProviderId == null ? "Seleccione proveedor primero" : null
                              ),
                              value: selectedOrderId,
                              items: getProviderOrders().map<DropdownMenuItem<String>>((o) {
                                return DropdownMenuItem(value: o['id'], child: Text("OC #${o['orderNumber']} - ${currencyFormat.format(o['totalAmount'])}"));
                              }).toList(),
                              onChanged: onOrderSelected, 
                              disabledHint: const Text("Sin Órdenes Pendientes"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // --- SECCIÓN 2: DATOS DEL COMPROBANTE ---
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Datos Fiscales", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                      const SizedBox(height: 15),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _invoiceNumCtrl,
                              decoration: const InputDecoration(labelText: "Nro. Factura (Ej: 0001-1234)", border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: "Imputación (Obra)", border: OutlineInputBorder()),
                              value: selectedProjectId,
                              items: projects.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'], child: Text(p['name']))).toList(),
                              onChanged: (v) => selectedProjectId = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      Row(
                        children: [
                          Expanded(
                             child: _datePickerField("Fecha Emisión", selectedDate, (d) => setState(() => selectedDate = d)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                             child: _datePickerField("Vencimiento Pago", selectedDueDate, (d) => setState(() => selectedDueDate = d)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- SECCIÓN 3: IMPORTES ---
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            children: [
                              _moneyInput("Neto Gravado", _netAmountCtrl),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: _moneyInput("IVA Total", _vatAmountCtrl)),
                                  const SizedBox(width: 10),
                                  Expanded(child: _moneyInput("Perc. / Otros", _taxesAmountCtrl)),
                                ],
                              ),
                              const Divider(height: 30, thickness: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("TOTAL A PAGAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(
                                    currencyFormat.format(totalCalculated),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.green),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                          onPressed: isSaving ? null : saveInvoice,
                          icon: const Icon(Icons.check_circle),
                          label: const Text("PROCESAR FACTURA", style: TextStyle(fontSize: 18)),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _datePickerField(String label, DateTime current, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: current, firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (d != null) onSelect(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.calendar_today)),
        child: Text(DateFormat('dd/MM/yyyy').format(current)),
      ),
    );
  }

  Widget _moneyInput(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixText: "\$ ",
        border: const OutlineInputBorder(),
        isDense: true
      ),
    );
  }
}