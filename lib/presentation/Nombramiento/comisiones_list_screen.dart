import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nombramientos_app/presentation/Nombramiento/nombramiento.dart';
import 'comision_edit_screen.dart';
import 'pdf_generator.dart';

class ComisionesListScreen extends StatefulWidget {
  const ComisionesListScreen({super.key});

  @override
  State<ComisionesListScreen> createState() => _ComisionesListScreenState();
}

class _ComisionesListScreenState extends State<ComisionesListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterYear = '';
  final List<String> _availableYears = [];
  
  @override
  void initState() {
    super.initState();
    _loadAvailableYears();
  }
  
  // Cargar los años disponibles para filtrar
  Future<void> _loadAvailableYears() async {
    try {
      final QuerySnapshot yearSnapshot = await _firestore
          .collection('nombramientos')
          .get();
      
      final Set<String> years = {};
      
      for (var doc in yearSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['numero_nombramiento'] != null) {
          final String numeroNombramiento = data['numero_nombramiento'].toString();
          final parts = numeroNombramiento.split('-');
          if (parts.length > 1) {
            years.add(parts[1]);
          }
        }
      }
      
      setState(() {
        _availableYears.clear();
        _availableYears.add('Todos');
        _availableYears.addAll(years.toList()..sort((a, b) => b.compareTo(a)));
        _filterYear = _availableYears.first;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar años: $e')),
      );
    }
  }

  // Eliminar un nombramiento
  Future<void> _deleteNombramiento(String docId, String numeroNombramiento) async {
    try {
      await _firestore.collection('nombramientos').doc(docId).delete();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nombramiento #$numeroNombramiento eliminado')),
        );
        setState(() {}); // Refrescar la lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }
  
  // Regenerar el PDF de un nombramiento
  Future<void> _regeneratePdf(Map<String, dynamic> data) async {
    try {
      // Convertir Timestamp a DateTime
      DateTime? fechaInicio;
      DateTime? fechaFin;
      
      if (data['fechaInicio'] != null) {
        fechaInicio = (data['fechaInicio'] as Timestamp).toDate();
      }
      
      if (data['fechaFin'] != null) {
        fechaFin = (data['fechaFin'] as Timestamp).toDate();
      }
      
      await NombramientoPdfGenerator.printNombramiento(
        numeroNombramiento: data['numero_nombramiento'] ?? '',
        nombre: data['nombre'] ?? '',
        cargo: data['cargo'] ?? '',
        sueldo: data['sueldo_mensual'] ?? '',
        nit: data['nit'] ?? '',
        dependencia: data['dependencia'] ?? '',
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        motivo: data['motivo'] ?? '',
        tipoTransporte: data['tipoTransporte'] ?? '',
        placas: data['placas'] ?? '',
        firmante: data['firmante'] ?? '',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al regenerar PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nombramientos de Comisión', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        foregroundColor: Colors.black54,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadAvailableYears();
            },
            tooltip: 'Refrescar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o número',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Filtrar por año: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _filterYear,
                      items: _availableYears.map((String year) {
                        return DropdownMenuItem<String>(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _filterYear = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de nombramientos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('nombramientos').orderBy('fecha_registro', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No hay nombramientos registrados'));
                      }
                      
                      // Filtrar los documentos
                      final docs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nombre = (data['nombre'] ?? '').toString().toLowerCase();
                        final numeroNombramiento = (data['numero_nombramiento'] ?? '').toString().toLowerCase();
                        
                        // Filtrar por búsqueda
                        final matchesSearch = _searchQuery.isEmpty || 
                            nombre.contains(_searchQuery) || 
                            numeroNombramiento.contains(_searchQuery);
                        
                        // Filtrar por año
                        bool matchesYear = true;
                        if (_filterYear != 'Todos') {
                          matchesYear = numeroNombramiento.contains('-$_filterYear');
                        }
                        
                        return matchesSearch && matchesYear;
                      }).toList();
                      
                      if (docs.isEmpty) {
                        return const Center(child: Text('No se encontraron resultados'));
                      }
                      
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final String numeroNombramiento = data['numero_nombramiento'] ?? 'Sin número';
                          final String nombre = data['nombre'] ?? 'Sin nombre';
                          
                          // Formatear fechas
                          String fechaInicio = 'No definida';
                          String fechaFin = 'No definida';
                          
                          if (data['fechaInicio'] != null) {
                            final DateTime date = (data['fechaInicio'] as Timestamp).toDate();
                            fechaInicio = DateFormat('dd/MM/yyyy').format(date);
                          }
                          
                          if (data['fechaFin'] != null) {
                            final DateTime date = (data['fechaFin'] as Timestamp).toDate();
                            fechaFin = DateFormat('dd/MM/yyyy').format(date);
                          }
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 2,
                            child: ExpansionTile(
                              title: Text(
                                'Nombramiento #$numeroNombramiento',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(nombre),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow('Cargo', data['cargo'] ?? 'No especificado'),
                                      _buildInfoRow('Dependencia', data['dependencia'] ?? 'No especificada'),
                                      _buildInfoRow('Período', '$fechaInicio al $fechaFin'),
                                      _buildInfoRow('Motivo', data['motivo'] ?? 'No especificado'),
                                      _buildInfoRow('Transporte', data['tipoTransporte'] ?? 'No especificado'),
                                      
                                      const SizedBox(height: 16),
                                      
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.edit),
                                            label: const Text('Editar'),
                                            onPressed: () async {
                                              final result = await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ComisionEditScreen(
                                                    documentId: doc.id,
                                                    comisionData: data,
                                                  ),
                                                ),
                                              );
                                              
                                              if (result == true) {
                                                setState(() {}); // Refrescar la lista
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue[700],
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.picture_as_pdf),
                                            label: const Text('PDF'),
                                            onPressed: () => _regeneratePdf(data),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green[700],
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.delete),
                                            label: const Text('Eliminar'),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Confirmar eliminación'),
                                                  content: Text('¿Está seguro que desea eliminar el nombramiento #$numeroNombramiento?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('Cancelar'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        _deleteNombramiento(doc.id, numeroNombramiento);
                                                      },
                                                      child: const Text('Eliminar'),
                                                      style: TextButton.styleFrom(
                                                        foregroundColor: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red[700],
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ComisionForm()),
          ).then((_) => setState(() {})); // Refrescar al volver
        },
        backgroundColor: Colors.blue[900],
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Nuevo Nombramiento',
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

