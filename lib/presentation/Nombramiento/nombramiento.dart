import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importar esto
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'pdf_generator.dart';

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
  
  // Loading state
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Inicializar datos de localización para español
    initializeDateFormatting('es', null);
  }
  
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue[900],
            hintColor: Colors.blue[900],
            colorScheme: ColorScheme.light(primary: Colors.blue[900]!),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }
  
  // Obtener el siguiente número de nombramiento
  Future<String> _getNextNombramientoNumber() async {
    final now = DateTime.now();
    final year = now.year.toString();
    
    // Referencia al documento contador para el año actual
    final counterRef = _firestore.collection('contadores').doc('nombramientos_$year');
    
    // Ejecutar una transacción para garantizar la consistencia
    return _firestore.runTransaction<String>((transaction) async {
      // Obtener el documento actual
      final counterDoc = await transaction.get(counterRef);
      
      int currentCount = 1; // Valor predeterminado si no existe
      
      // Si el documento existe, incrementar el contador
      if (counterDoc.exists) {
        currentCount = (counterDoc.data()?['count'] ?? 0) + 1;
      }
      
      // Actualizar el contador en Firestore
      transaction.set(counterRef, {'count': currentCount}, SetOptions(merge: true));
      
      // Formatear el número de nombramiento (por ejemplo: 01-2025)
      return '${currentCount.toString().padLeft(2, '0')}-$year';
    });
  }
  
  // Save form data to Firestore and generate PDF
  Future<void> _saveFormData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Parse dates
      DateTime? fechaInicio;
      DateTime? fechaFin;
      
      try {
        if (_fechaInicioController.text.isNotEmpty) {
          fechaInicio = DateFormat('dd/MM/yyyy').parse(_fechaInicioController.text);
        }
        
        if (_fechaFinController.text.isNotEmpty) {
          fechaFin = DateFormat('dd/MM/yyyy').parse(_fechaFinController.text);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en formato de fecha: $e')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Obtener el número de nombramiento
      final numeroNombramiento = await _getNextNombramientoNumber();
      
      // Prepare data
      final comisionData = {
        'numero_nombramiento': numeroNombramiento,
        'nombre': _nombreController.text,
        'cargo': _cargoController.text,
        'sueldo_mensual': _sueldoController.text,
        'nit': _nitController.text,
        'dependencia': _dependenciaController.text,
        'fechaInicio': fechaInicio != null ? Timestamp.fromDate(fechaInicio) : null,
        'fechaFin': fechaFin != null ? Timestamp.fromDate(fechaFin) : null,
        'motivo': _motivoController.text,
        'tipoTransporte': _tipoTransporte,
        'placas': _tipoTransporte == 'Vehículo de la Institución' ? _placasController.text : '',
        'firmante': _firmante,
        'fecha_registro': Timestamp.now(),
      };
      
      // Save to Firestore in 'nombramientos' collection (nueva colección)
      final docRef = await _firestore.collection('nombramientos').add(comisionData);
      
      // Generar PDF
      await NombramientoPdfGenerator.printNombramiento(
        numeroNombramiento: numeroNombramiento,
        nombre: _nombreController.text,
        cargo: _cargoController.text,
        sueldo: _sueldoController.text,
        nit: _nitController.text,
        dependencia: _dependenciaController.text,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        motivo: _motivoController.text,
        tipoTransporte: _tipoTransporte,
        placas: _placasController.text,
        firmante: _firmante,
      );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nombramiento #$numeroNombramiento guardado correctamente')),
        );
        
        // Clear form
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
          _firmante = 'Coordinador II';
        });
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulario de Nombramiento', style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
        foregroundColor: Colors.black54,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isLoading ? null : () async {
              if (_formKey.currentState!.validate()) {
                try {
                  // Parse dates
                  DateTime? fechaInicio;
                  DateTime? fechaFin;
                  
                  if (_fechaInicioController.text.isNotEmpty) {
                    fechaInicio = DateFormat('dd/MM/yyyy').parse(_fechaInicioController.text);
                  }
                  
                  if (_fechaFinController.text.isNotEmpty) {
                    fechaFin = DateFormat('dd/MM/yyyy').parse(_fechaFinController.text);
                  }
                  
                  // Vista previa del PDF sin guardar en Firestore
                  await NombramientoPdfGenerator.printNombramiento(
                    numeroNombramiento: "XX-${DateTime.now().year}",
                    nombre: _nombreController.text,
                    cargo: _cargoController.text,
                    sueldo: _sueldoController.text,
                    nit: _nitController.text,
                    dependencia: _dependenciaController.text,
                    fechaInicio: fechaInicio,
                    fechaFin: fechaFin,
                    motivo: _motivoController.text,
                    tipoTransporte: _tipoTransporte,
                    placas: _placasController.text,
                    firmante: _firmante,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al generar PDF: $e')),
                  );
                }
              }
            },
            tooltip: 'Vista previa PDF',
          ),
        ],
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
                                  onPressed: _isLoading ? null : _saveFormData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[900],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  ),
                                  child: _isLoading 
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Guardar y Generar PDF'),
                                ),
                                const SizedBox(width: 16),
                                OutlinedButton(
                                  onPressed: _isLoading 
                                    ? null 
                                    : () {
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
                                          _firmante = 'Coordinador II';
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

