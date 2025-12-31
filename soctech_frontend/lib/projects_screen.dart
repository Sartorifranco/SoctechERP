import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'project_add_screen.dart'; 
import 'project_detail_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<dynamic> projects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://localhost:5064/api/Projects'));
      if (response.statusCode == 200) {
        setState(() {
          projects = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final proj = projects[index];
                    // Si el backend no manda 'isActive', asumimos false
                    final bool isActive = proj['isActive'] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: isActive ? Colors.indigo : Colors.grey,
                          child: const Icon(Icons.apartment, color: Colors.white),
                        ),
                        title: Text(
                          proj['name'], 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text(proj['description'] ?? "Sin dirección"),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(5)
                              ),
                              child: Text(
                                proj['status'] ?? "Activo",
                                style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.indigo),
                        
                        // --- ESTA ES LA CLAVE: SIN BOTÓN VER COSTOS ---
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectDetailScreen(project: proj),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProjectAddScreen()),
          );
          if (result == true) fetchProjects();
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apartment, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text("No tienes obras activas", style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}