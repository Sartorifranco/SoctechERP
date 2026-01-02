import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateProviderScreen extends StatefulWidget {
  const CreateProviderScreen({super.key});

  @override
  State<CreateProviderScreen> createState() => _CreateProviderScreenState();
}

class _CreateProviderScreenState extends State<CreateProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _nameController = TextEditingController(); // Razón Social
  final _cuitController = TextEditingController(); 
  final _contactController = TextEditingController(); // Nombre del vendedor
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool isSaving = false;

  Future<void> saveProvider() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final newProvider = {
      "name": _nameController.text,
      "cuit": _cuitController.text,
      "contactName": _contactController.text,
      "phoneNumber": _phoneController.text,
      "email": _emailController.text,
      "address": "Dirección Fiscal", // Opcional o harcodeado por ahora
      "isActive": true
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5064/api/Providers'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(newProvider),
      );

      if (response.statusCode == 201) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Proveedor Registrado Exitosamente")));
          Navigator.pop(context); // Volver atrás
        }
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nuevo Proveedor")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Datos Fiscales", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
              const Divider(),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Razón Social / Nombre", icon: Icon(Icons.business)),
                validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _cuitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "CUIT", icon: Icon(Icons.badge), helperText: "Sin guiones"),
                validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
              ),

              const SizedBox(height: 20),
              const Text("Datos de Contacto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
              const Divider(),

              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: "Nombre de Contacto", icon: Icon(Icons.person)),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Teléfono / WhatsApp", icon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email", icon: Icon(Icons.email)),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : saveProvider,
                  icon: isSaving ? const SizedBox(width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.save),
                  label: const Text("GUARDAR PROVEEDOR"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}