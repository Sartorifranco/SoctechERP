import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'create_provider_screen.dart'; // Importamos la pantalla de creación

class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({super.key});

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  List<dynamic> providers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProviders();
  }

  Future<void> fetchProviders() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/Providers'));
      if (response.statusCode == 200) {
        setState(() {
          providers = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => isLoading = false);
    }
  }

  void navigateToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateProviderScreen()),
    );
    fetchProviders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Directorio de Proveedores")),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAdd,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : providers.isEmpty
              ? const Center(child: Text("No hay proveedores registrados."))
              : ListView.builder(
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final p = providers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: const Icon(Icons.business, color: Colors.deepOrange),
                        ),
                        title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("CUIT: ${p['cuit']}"),
                            if (p['contactName'] != null) Text("Contacto: ${p['contactName']}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () {
                            // Aquí podrías lanzar una llamada real
                            if (p['phoneNumber'] != null) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Llamando a ${p['phoneNumber']}...")));
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}