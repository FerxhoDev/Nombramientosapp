import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pdf_generator.dart';

class ComisionEditScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> comisionData;
  
  const ComisionEditScreen({
    super.key,
    required this.documentId,
    required this.comisionData,
  });

  @override
  State<ComisionEditScreen> createState() => _ComisionEditScreenState();
}

class _ComisionEditScreenState extends State<ComisionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  late TextEditingController _nombreController;
  late TextEditingController _cargoController;
  late TextEditingController _sueldoController;
  late TextEditingController _nitController;
  late TextEditingController _dependenciaController;
  late TextEditingController _fechaInicioController;
  late TextEditingController _fechaFinController;
  late TextEditingController _motivoController;
  late TextEditingController _placasController;
  
  // Form values
  late String _tipoTransporte;
  late String _firmante;
  
  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Loading state
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores con los datos existentes
    _nombreController = TextEditingController(text: widget.comisionData['nombre'] ?? '');
    _cargoController = TextEditingController(text: widget.comisionData['cargo'] ?? '');
    _sueldoController = TextEditingController(text: widget.comisionData['sueldo_mensual'] ?? '');
    _nitController = TextEditingController(text: widget.comisionData['nit'] ?? '');
    _dependenciaController = TextEditingController(text: widget.comisionData['dependencia'] ?? '');
    _motivoController = TextEditingController(text: widget.comisionData['motivo'] ?? '');
    _placasController = TextEditingController(text: widget.comisionData['placas'] ?? '');
    
    // Inicializar fechas
    _fechaInicioController = TextEditingController();
    _fechaFinController = TextEditingController();
    
    if (widget.comisionData['fechaInicio'] != null) {
      final DateTime fechaInicio = (widget.comisionData['fechaInicio'] as Timestamp).toDate();
      _fechaInicioController.text = DateFormat('dd/MM/yyyy').format(fechaInicio);
    }
    
    if (widget.comisionData['fechaFin'] != null) {
      final DateTime fechaFin = (widget.comisionData['fechaFin'] as Timestamp).toDate();
      _fechaFinController.text = DateFormat('dd/MM/yyyy').format(fechaFin);
    }
    
    // Inicializar valores de selección
    _tipoTransporte = widget.comisionData['tipoTransporte'] ?? 'Vehículo de la Institución';
    _firmante = widget.comisionData['firmante'] ?? 'Coordinador II';
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
  
  // Actualizar datos en Firestore
  Future<void> _updateFormData() async {
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
      
      // Prepare data
      final comisionData = {
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
        'fecha_actualizacion': Timestamp.now(),
      };
      
      // Actualizar en Firestore
      await _firestore.collection('nombramientos').doc(widget.documentId).update(comisionData);
      
      // Obtener el número de nombramiento para el PDF
      final String numeroNombramiento = widget.comisionData['numero_nombramiento'] ?? '';
      
      // Generar PDF actualizado
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
          const SnackBar(content: Text('Nombramiento actualizado correctamente')),
        );
        
        // Volver a la pantalla anterior
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
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
        title: Text('Editar Nombramiento #${widget.comisionData['numero_nombramiento'] ?? ''}', 
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
                                  onPressed: _isLoading ? null : _updateFormData,
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
                                    : const Text('Actualizar'),
                                ),
                                const SizedBox(width: 16),
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  ),
                                  child: const Text('Cancelar'),
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

