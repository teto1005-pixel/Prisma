// lib/main.dart

import 'package:flutter/material.dart';
import 'data/datos_curriculo.dart';
import 'models/estructura_academica.dart';
import 'models/perfil_estudiante.dart';
import 'screens/pantalla_chat_tutor.dart';
import 'screens/pantalla_formulario.dart';
import 'screens/pantalla_formulas.dart';
import 'screens/pantalla_secciones.dart';
import 'screens/pantalla_unidades.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SecundariaIAApp());
}

class SecundariaIAApp extends StatelessWidget {
  const SecundariaIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4338CA),
      primary: const Color(0xFF4338CA),
      secondary: const Color(0xFF7E22CE),
      tertiary: const Color(0xFF0EA5E9),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'SecundariaIA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
        ),
      ),
      home: const EnrutadorSecundariaIA(),
    );
  }
}

class EnrutadorSecundariaIA extends StatefulWidget {
  const EnrutadorSecundariaIA({super.key});

  @override
  State<EnrutadorSecundariaIA> createState() => _EnrutadorSecundariaIAState();
}

class _EnrutadorSecundariaIAState extends State<EnrutadorSecundariaIA> {
  PerfilEstudiante _perfil = PerfilEstudiante(
    nombre: '',
    gradoId: '7mo',
    estiloAprendizaje: EstiloAprendizaje.pasoAPaso,
  );

  bool _esModoEdicionPerfil = false;
  Grado? _gradoSeleccionado;
  Unidad? _unidadSeleccionada;
  Seccion? _seccionSeleccionada;

  int _pestana = 0;
  bool _formularioVisitado = false;

  Grado _obtenerGradoActual() {
    return _gradoSeleccionado ??
        DatosCurriculo.obtenerGradoPorId(_perfil.gradoId) ??
        listaGrados.first;
  }

  @override
  Widget build(BuildContext context) {
    if (!_perfil.estaCompletado || _esModoEdicionPerfil) {
      return PantallaFormulario(
        perfilActual: _perfil,
        esEdicion: _esModoEdicionPerfil,
        onGuardarPerfil: (nuevoPerfil) {
          setState(() {
            _perfil = nuevoPerfil;
            _esModoEdicionPerfil = false;
            _gradoSeleccionado =
                DatosCurriculo.obtenerGradoPorId(nuevoPerfil.gradoId) ??
                    listaGrados.first;
          });
        },
      );
    }

    final gradoActual = _obtenerGradoActual();

    if (_seccionSeleccionada != null && _unidadSeleccionada != null) {
      return PantallaChatTutor(
        grado: gradoActual,
        unidad: _unidadSeleccionada!,
        seccion: _seccionSeleccionada!,
        perfil: _perfil,
        onVolver: () {
          setState(() {
            _seccionSeleccionada = null;
          });
        },
      );
    }

    if (_unidadSeleccionada != null) {
      return PantallaSecciones(
        grado: gradoActual,
        unidad: _unidadSeleccionada!,
        onSeleccionarSeccion: (seccion) {
          setState(() {
            _seccionSeleccionada = seccion;
          });
        },
        onVolver: () {
          setState(() {
            _unidadSeleccionada = null;
          });
        },
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _pestana,
        children: [
          PantallaUnidades(
            grado: gradoActual,
            nombreEstudiante: _perfil.nombre,
            onSeleccionarUnidad: (unidad) {
              setState(() {
                _unidadSeleccionada = unidad;
              });
            },
            onCambiarGrado: (nuevoGrado) {
              setState(() {
                _gradoSeleccionado = nuevoGrado;
                _unidadSeleccionada = null;
                _seccionSeleccionada = null;
              });
            },
            onEditarPerfil: () {
              setState(() {
                _esModoEdicionPerfil = true;
              });
            },
          ),
          _formularioVisitado
              ? PantallaFormulas(
            key: ValueKey(gradoActual.id),
            gradoInicialId: gradoActual.id,
          )
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pestana,
        onDestinationSelected: (indice) {
          setState(() {
            _pestana = indice;
            if (indice == 1) _formularioVisitado = true;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Aprender',
          ),
          NavigationDestination(
            icon: Icon(Icons.functions),
            label: 'Formulario',
          ),
        ],
      ),
    );
  }
}