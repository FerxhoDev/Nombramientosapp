import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nombramientos_app/presentation/Users/add_user.dart';
import 'package:nombramientos_app/presentation/Users/update_user.dart';

class UsuariosListScreen extends StatefulWidget {
  const UsuariosListScreen({super.key});

  @override
  State<UsuariosListScreen> createState() => _UsuariosListScreenState();
}

class _UsuariosListScreenState extends State<UsuariosListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Colaboradores', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        foregroundColor: Colors.black54,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FormularioScreen()),
              ).then((_) => setState(() {})); // Refresh list when returning
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 8),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('empleados').orderBy('fecha_registro', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No hay usuarios registrados'));
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                
                // Format date if it exists
                String fechaRegistro = 'No especificada';
                
                if (data['fecha_registro'] != null) {
                  try {
                    final timestamp = data['fecha_registro'] as Timestamp;
                    fechaRegistro = DateFormat('dd/MM/yyyy').format(timestamp.toDate());
                  } catch (e) {
                    // If it's stored as a string
                    fechaRegistro = data['fecha_registro'].toString();
                  }
                }
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      data['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('Cargo: ${data['cargo'] ?? 'No especificado'}'),
                        Text('NIT: ${data['nit'] ?? 'No especificado'}'),
                        Text('Sueldo: Q${data['sueldo_mensual'] ?? '0.00'}'),
                        Text('Fecha de registro: $fechaRegistro'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue[900]),
                          onPressed: () {
                            _navigateToEditForm(context, doc.id, data);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmation(context, doc.id);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      _navigateToEditForm(context, doc.id, data);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
  
  void _navigateToEditForm(BuildContext context, String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UsuarioForm(usuarioId: docId, usuarioData: data),
      ),
    ).then((_) => setState(() {})); // Refresh list when returning
  }
  
  void _showDeleteConfirmation(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Está seguro que desea eliminar este usuario?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _deleteUsuario(docId);
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _deleteUsuario(String docId) async {
    try {
      await _firestore.collection('empleados').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }
}
