import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _nameController = TextEditingController();
  final _skuController = TextEditingController(); // Código de barras o interno
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();

  bool isSaving = false;

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final newProduct = {
      "name": _nameController.text,
      "sku": _skuController.text,
      "description": _descriptionController.text,
      "costPrice": double.tryParse(_costController.text) ?? 0,
      "salePrice": double.tryParse(_priceController.text) ?? 0,
      "stock": 0, // El stock inicial siempre es 0, luego se hace una "Entrada"
      "reorderLevel": 5, // Alerta cuando queden 5
      "isActive": true
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5064/api/Products'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(newProduct),
      );

      if (response.statusCode == 201) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Producto Creado Exitosamente")));
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
      appBar: AppBar(title: const Text("Nuevo Material / Producto")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Datos Generales", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
              const Divider(),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nombre del Material", icon: Icon(Icons.inventory_2)),
                validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: "Código (SKU)", icon: Icon(Icons.qr_code), helperText: "Código único o de barras"),
                validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
              ),
               const SizedBox(height: 10),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Descripción", icon: Icon(Icons.description)),
              ),

              const SizedBox(height: 20),
              const Text("Costos y Precios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
              const Divider(),

              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Costo de Compra", icon: Icon(Icons.attach_money)),
                validator: (value) => value!.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Precio Venta (Opcional)", icon: Icon(Icons.price_check)),
              ),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : saveProduct,
                  icon: isSaving ? const SizedBox(width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.save),
                  label: const Text("GUARDAR MATERIAL"),
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