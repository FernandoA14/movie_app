import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(
    home: HomePage(),
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
  ));
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegistrosPage()),
            );
          },
          child: Text('Mostrar Registros'),
        ),
      ),
    );
  }
}

class RegistrosPage extends StatefulWidget {
  @override
  _RegistrosPageState createState() => _RegistrosPageState();
}

class _RegistrosPageState extends State<RegistrosPage> {
  late Future<List<Persona>> _personasFuture;
  late Database _database;

  @override
  void initState() {
    super.initState();
    _personasFuture = _openDatabaseAndFetchPersonas();
  }

  Future<List<Persona>> _openDatabaseAndFetchPersonas() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'goddesgo.db');

    bool exists = await databaseExists(path);

    if (!exists) {
      await Directory(dirname(path)).create(recursive: true);
      ByteData data = await rootBundle.load(join('assets', 'goddesgo.db'));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    _database = await openDatabase(path);

    List<Map<String, dynamic>> personasData = await _database.query('personas');

    List<Persona> personas = personasData.map((data) => Persona.fromMap(data)).toList();

    return personas;
  }

  void _mostrarDetallesPersona(BuildContext context, Persona persona) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Detalles de la persona'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${persona.id}'),
              Text('Nombre: ${persona.nombre}'),
              Text('Apellido: ${persona.apellido}'),
              Text('Celular: ${persona.celular}'),
              Text('Correo: ${persona.correo}'),
              Text('Contraseña: ${persona.contrasena}'),
              Text('ID Rol: ${persona.idRol}'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cerrar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra la ventana emergente
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personas Registradas'),
      ),
      body: FutureBuilder<List<Persona>>(
        future: _personasFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _mostrarDetallesPersona(context, snapshot.data![index]);
                  },
                  child: ListTile(
                    title: Text(snapshot.data![index].nombre),
                    subtitle: Text(snapshot.data![index].apellido),
                    leading: CircleAvatar(
                      child: Text(snapshot.data![index].id.toString()),
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text('Error al cargar los datos');
          }

          return CircularProgressIndicator();
        },
      ),
    );
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }
}

class Persona {
  final int id;
  final String nombre;
  final String apellido;
  final String celular;
  final String correo;
  final String contrasena;
  final int idRol;

  Persona({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.celular,
    required this.correo,
    required this.contrasena,
    required this.idRol,
  });

  factory Persona.fromMap(Map<String, dynamic> map) {
    return Persona(
      id: map['id_persona'],
      nombre: map['nombre'],
      apellido: map['apellido'],
      celular: map['celular'],
      correo: map['correo'],
      contrasena: map['contrasena'],
      idRol: map['id_rol'],
    );
  }
}