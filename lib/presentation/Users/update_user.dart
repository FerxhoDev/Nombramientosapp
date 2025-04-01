import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class UsuarioForm extends StatefulWidget {
  final String? usuarioId;
  final Map<String, dynamic>? usuarioData;
  
  const UsuarioForm({
    super.key, 
    this.usuarioId,
    this.usuarioData,
  });

  @override
  State<UsuarioForm> createState() => _UsuarioFormState();
}

class _UsuarioFormState extends State<UsuarioForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nombreController = TextEditingController();
  final _cargoController = TextEditingController();
  final _renglonController = TextEditingController();
  final _sueldoController = TextEditingController();
  final _nitController = TextEditingController();
  
  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Flag to check if we're editing
  bool get isEditing => widget.usuarioId != null;
  
  @override
  void initState() {
    super.initState();
    
    // If we're editing, populate the form with existing data
    if (isEditing && widget.usuarioData != null) {
      _populateFormWithData(widget.usuarioData!);
    }
  }
  
  void _populateFormWithData(Map<String, dynamic> data) {
    _nombreController.text = data['nombre'] ?? '';
    _cargoController.text = data['cargo'] ?? '';
    _renglonController.text = data['renglon'] ?? '';
    _sueldoController.text = data['sueldo_mensual']?.toString() ?? '';
    _nitController.text = data['nit'] ?? '';
  }
  
  @override
  void dispose() {
    _nombreController.dispose();
    _cargoController.dispose();
    _renglonController.dispose();
    _sueldoController.dispose();
    _nitController.dispose();
    super.dispose();
  }

  // Fetch employee suggestions from Firestore
  Future<List<String>> _getSuggestions(String pattern) async {
    if (pattern.length < 2) return [];
    
    final snapshot = await _firestore
        .collection('empleados')
        .where('nombre', isGreaterThanOrEqualTo: pattern)
        .where('nombre', isLessThanOrEqualTo: pattern + '\uf8ff')
        .limit(10)
        .get();
    
    return snapshot.docs.map((doc) => doc['nombre'] as String).toList();
  }
  
  // Fetch employee data from Firestore by name
  Future<void> _fetchEmployeeData(String name) async {
    try {
      final snapshot = await _firestore
          .collection('empleados')
          .where('nombre', isEqualTo: name)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          _cargoController.text = data['cargo'] ?? '';
          _renglonController.text = data['renglon'] ?? '';
          _nitController.text = data['nit'] ?? '';
          _sueldoController.text = data['sueldo_mensual']?.toString() ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar empleado: $e')),
      );
    }
  }
  
  // Save or update the form data
  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    try {
      // Prepare data
      final usuarioData = {
        'nombre': _nombreController.text,
        'cargo': _cargoController.text,
        'renglon': _renglonController.text,
        'sueldo_mensual': _sueldoController.text,
        'nit': _nitController.text,
        'actualizado': Timestamp.now(),
      };
      
      // If not editing, add creation timestamp
      if (!isEditing) {
        usuarioData['fecha_registro'] = Timestamp.now();
      }
      
      if (isEditing) {
        // Update existing document
        await _firestore.collection('empleados').doc(widget.usuarioId).update(usuarioData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario actualizado correctamente')),
          );
        }
      } else {
        // Create new document
        await _firestore.collection('usuarios').add(usuarioData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario guardado correctamente')),
          );
        }
      }
      
      // Navigate back
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Usuario' : 'Nuevo Usuario', 
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        foregroundColor: Colors.black54,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información del Usuario',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Nombre
                            if (isEditing)
                              TextFormField(
                                controller: _nombreController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingrese el nombre';
                                  }
                                  return null;
                                },
                              )
                            else
                              TypeAheadFormField<String>(
                                textFieldConfiguration: TextFieldConfiguration(
                                  controller: _nombreController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                suggestionsCallback: _getSuggestions,
                                itemBuilder: (context, suggestion) {
                                  return ListTile(
                                    title: Text(suggestion),
                                  );
                                },
                                onSuggestionSelected: (suggestion) {
                                  _nombreController.text = suggestion;
                                  _fetchEmployeeData(suggestion);
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor ingrese el nombre';
                                  }
                                  return null;
                                },
                              ),
                            const SizedBox(height: 16),
                            
                            // Cargo
                            TextFormField(
                              controller: _cargoController,
                              decoration: const InputDecoration(
                                labelText: 'Cargo',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese el cargo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Renglón
                            TextFormField(
                              controller: _renglonController,
                              decoration: const InputDecoration(
                                labelText: 'Renglón',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese el renglón';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Sueldo Mensual
                            TextFormField(
                              controller: _sueldoController,
                              decoration: const InputDecoration(
                                labelText: 'Sueldo Mensual',
                                border: OutlineInputBorder(),
                                prefixText: 'Q ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese el sueldo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // NIT
                            TextFormField(
                              controller: _nitController,
                              decoration: const InputDecoration(
                                labelText: 'NIT',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingrese el NIT';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            
                            // Botones
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: _saveForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[900],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    ),
                                    child: Text(isEditing ? 'Actualizar' : 'Guardar'),
                                  ),
                                  const SizedBox(width: 16),
                                  OutlinedButton(
                                    onPressed: () {
                                      // Limpiar el formulario o cancelar
                                      if (isEditing) {
                                        Navigator.pop(context);
                                      } else {
                                        // Limpiar el formulario
                                        _formKey.currentState!.reset();
                                        _nombreController.clear();
                                        _cargoController.clear();
                                        _renglonController.clear();
                                        _sueldoController.clear();
                                        _nitController.clear();
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    ),
                                    child: Text(isEditing ? 'Cancelar' : 'Limpiar'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

