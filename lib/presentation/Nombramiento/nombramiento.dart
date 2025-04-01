import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class ComisionForm extends StatefulWidget {
  const ComisionForm({super.key});

  @override
  State<ComisionForm> createState() => _ComisionFormState();
}

class _ComisionFormState extends State<ComisionForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nombreController = TextEditingController();
  final _cargoController = TextEditingController();
  final _sueldoController = TextEditingController();
  final _nitController = TextEditingController();
  final _dependenciaController = TextEditingController();
  final _fechaInicioController = TextEditingController();
  final _fechaFinController = TextEditingController();
  final _motivoController = TextEditingController();
  final _placasController = TextEditingController();
  
  // Form values
  String _tipoTransporte = 'Vehículo de la Institución';
  String _firmante = 'Coordinador II';
  
  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  void dispose() {
    _nombreController.dispose();
    _cargoController.dispose();
    _sueldoController.dispose();
    _nitController.dispose();
    _dependenciaController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    _motivoController.dispose();
    _placasController.dispose();
    super.dispose();
  }

  // Fetch employee suggestions from Firestore
  Future<List<String>> _getSuggestions(String pattern) async {
    if (pattern.length < 3) return [];
    
    final snapshot = await _firestore
        .collection('empleados')
        .where('nombre', isGreaterThanOrEqualTo: pattern)
        .where('nombre', isLessThanOrEqualTo: pattern + '\uf8ff')
        .limit(6)
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
          _nitController.text = data['nit'] ?? '';
          _sueldoController.text = data['sueldo_mensual']?.toString() ?? '';
          // You can add more fields as needed
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar empleado: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulario de Comisión', style: TextStyle(fontWeight: FontWeight.bold),),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información personal
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Información Personal',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // TypeAhead field for employee name with autocomplete
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
                                TextFormField(
                                  controller: _cargoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Cargo y Reglón',
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
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
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
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
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Dependencia
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dependencia',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _dependenciaController,
                                  decoration: const InputDecoration(
                                    labelText: 'Dependencia',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese la dependencia';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Fechas
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Período de Comisión',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _fechaInicioController,
                                        decoration: InputDecoration(
                                          labelText: 'Fecha de Inicio',
                                          border: const OutlineInputBorder(),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.calendar_today),
                                            onPressed: () => _selectDate(context, _fechaInicioController),
                                          ),
                                        ),
                                        readOnly: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Por favor seleccione la fecha de inicio';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _fechaFinController,
                                        decoration: InputDecoration(
                                          labelText: 'Fecha de Fin',
                                          border: const OutlineInputBorder(),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.calendar_today),
                                            onPressed: () => _selectDate(context, _fechaFinController),
                                          ),
                                        ),
                                        readOnly: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Por favor seleccione la fecha de fin';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Motivo de comisión
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Motivo de Comisión',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _motivoController,
                                  decoration: const InputDecoration(
                                    labelText: 'Motivo de Comisión',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor ingrese el motivo de la comisión';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Tipo de transporte
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tipo de Transporte',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                RadioListTile<String>(
                                  activeColor: Colors.blue[900],
                                  title: const Text('Vehículo de la Institución'),
                                  value: 'Vehículo de la Institución',
                                  groupValue: _tipoTransporte,
                                  onChanged: (value) {
                                    setState(() {
                                      _tipoTransporte = value!;
                                    });
                                  },
                                ),
                                if (_tipoTransporte == 'Vehículo de la Institución')
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                    child: TextFormField(
                                      controller: _placasController,
                                      decoration: const InputDecoration(
                                        labelText: 'Placas del Vehículo',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (_tipoTransporte == 'Vehículo de la Institución' && 
                                            (value == null || value.isEmpty)) {
                                          return 'Por favor ingrese las placas del vehículo';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                RadioListTile<String>(
                                  activeColor: Colors.blue[900],
                                  title: const Text('Vehículo Propio'),
                                  value: 'Vehículo Propio',
                                  groupValue: _tipoTransporte,
                                  onChanged: (value) {
                                    setState(() {
                                      _tipoTransporte = value!;
                                    });
                                  },
                                ),
                                RadioListTile<String>(
                                  activeColor: Colors.blue[900],
                                  title: const Text('Transporte Extra Urbano'),
                                  value: 'Transporte Extra Urbano',
                                  groupValue: _tipoTransporte,
                                  onChanged: (value) {
                                    setState(() {
                                      _tipoTransporte = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Firmante
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Firmante',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Firmante',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _firmante,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Coordinador II',
                                      child: Text('Coordinador II'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Jefe VI',
                                      child: Text('Jefe VI'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _firmante = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Botones
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      // Procesar el formulario
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Procesando datos')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[900],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  ),
                                  child: const Text('Guardar'),
                                ),
                                const SizedBox(width: 16),
                                OutlinedButton(
                                  onPressed: () {
                                    // Limpiar el formulario
                                    _formKey.currentState!.reset();
                                    _nombreController.clear();
                                    _cargoController.clear();
                                    _sueldoController.clear();
                                    _nitController.clear();
                                    _dependenciaController.clear();
                                    _fechaInicioController.clear();
                                    _fechaFinController.clear();
                                    _motivoController.clear();
                                    _placasController.clear();
                                    setState(() {
                                      _tipoTransporte = 'Vehículo de la Institución';
                                      _firmante = 'Jefe VI';
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  ),
                                  child: const Text('Limpiar'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

