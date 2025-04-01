import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FormularioScreen extends StatefulWidget {
  const FormularioScreen({super.key});

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cargoController = TextEditingController();
  final TextEditingController _renglonController = TextEditingController();
  final TextEditingController _sueldoController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();

  Future<void> enviarDatos() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('empleados').add({
        'nombre': _nombreController.text,
        'cargo': _cargoController.text,
        'renglon': _renglonController.text,
        'sueldo_mensual': double.tryParse(_sueldoController.text) ?? 0.0,
        'nit': _nitController.text,
        'fecha_registro': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos enviados correctamente')),
       );
      }


      // Limpiar los campos después de enviar
      _nombreController.clear();
      _cargoController.clear();
      _renglonController.clear();
      _sueldoController.clear();
      _nitController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Usuario', style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
        foregroundColor: Colors.black54,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título de la sección
                      const Padding(
                        padding: EdgeInsets.only(bottom: 20.0),
                        child: Text(
                          'Información Personal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black ,
                          ),
                        ),
                      ),
                      
                      // Nombre
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            hintText: 'Ingrese el nombre completo',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: const Icon(Icons.person),
                          ),
                          validator: (value) => value!.isEmpty ? 'Ingrese un nombre' : null,
                        ),
                      ),
                      
                      // Cargo
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _cargoController,
                          decoration: InputDecoration(
                            labelText: 'Cargo',
                            hintText: 'Ingrese el cargo',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: const Icon(Icons.work),
                          ),
                          validator: (value) => value!.isEmpty ? 'Ingrese un cargo' : null,
                        ),
                      ),
                      
                      // Renglón
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextFormField(
                          controller: _renglonController,
                          decoration: InputDecoration(
                            labelText: 'Renglón',
                            hintText: 'Ingrese el renglón',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            prefixIcon: const Icon(Icons.format_list_numbered),
                          ),
                          validator: (value) => value!.isEmpty ? 'Ingrese el renglón' : null,
                        ),
                      ),
                      
                      // Fila con Sueldo y NIT
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sueldo Mensual
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: TextFormField(
                                  controller: _sueldoController,
                                  decoration: InputDecoration(
                                    labelText: 'Sueldo Mensual',
                                    hintText: 'Ingrese el sueldo',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    prefixIcon: const Icon(Icons.attach_money),
                                    prefixText: 'Q ',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) => value!.isEmpty ? 'Ingrese el sueldo' : null,
                                ),
                              ),
                            ),
                            
                            // NIT
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: TextFormField(
                                  controller: _nitController,
                                  decoration: InputDecoration(
                                    labelText: 'NIT',
                                    hintText: 'Ingrese el NIT',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    prefixIcon: const Icon(Icons.badge),
                                  ),
                                  validator: (value) => value!.isEmpty ? 'Ingrese el NIT' : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Botones
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Botón Enviar
                              ElevatedButton.icon(
                                onPressed: enviarDatos,
                                icon: const Icon(Icons.save),
                                label: const Text('Guardar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[900],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Botón Limpiar
                              OutlinedButton.icon(
                                onPressed: () {
                                  _formKey.currentState!.reset();
                                  _nombreController.clear();
                                  _cargoController.clear();
                                  _renglonController.clear();
                                  _sueldoController.clear();
                                  _nitController.clear();
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Limpiar'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

