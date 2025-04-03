import 'package:flutter/material.dart';
import 'package:nombramientos_app/presentation/Nombramiento/comisiones_list_screen.dart';
import 'package:nombramientos_app/presentation/Nombramiento/nombramiento.dart';
import 'package:nombramientos_app/presentation/Users/add_user.dart';
import 'package:nombramientos_app/presentation/Users/list_user.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Widget _selectedScreen = const ComisionForm(); // Pantalla inicial

  void _setScreen(Widget screen) {
    setState(() {
      _selectedScreen = screen;
    });
    Navigator.pop(context); // Cerrar el Drawer después de seleccionar una opción
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Nombramientos Informática y Telecomunicaciones Quetzaltenango',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[900],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue[900]),
              child: Column(
                children: [
                  const Text(
                    'GERENCIA DE INFORMATICA',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Image.asset('assets/OJ.png', width: 50, height: 50),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('Crear Nombramiento'),
              onTap: () {
                _setScreen(const ComisionForm());
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Comisiones'),
              onTap: () {
                _setScreen(const ComisionesListScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1),
              title: const Text('Añadir Colaborador'),
              onTap: () {
                _setScreen(FormularioScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Colaboradores'),
              onTap: () {
                _setScreen(const UsuariosListScreen());
              },
            ),
          ],
        ),
      ),
      body: _selectedScreen,
    );
  }
}
