import 'package:flutter/material.dart';
import 'models/estructura_academica.dart';
import 'models/perfil_estudiante.dart';
import 'screens/pantalla_chat_tutor.dart';
import 'screens/pantalla_formulario.dart';
import 'screens/pantalla_formulas.dart';
import 'screens/pantalla_grados.dart';
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
    // Paleta Deep Purple / Indigo moderno
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4338CA), // Indigo profundo elegante
      primary: const Color(0xFF4338CA),
      secondary: const Color(0xFF7E22CE), // Violeta profundo
      tertiary: const Color(0xFF0EA5E9),  // Acento cian
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

/// Gestiona el estado de navegación y persistencia en memoria del perfil del estudiante.
class EnrutadorSecundariaIA extends StatefulWidget {
  const EnrutadorSecundariaIA({super.key});

  @override
  State<EnrutadorSecundariaIA> createState() => _EnrutadorSecundariaIAState();
}

class _EnrutadorSecundariaIAState extends State<EnrutadorSecundariaIA> {
  PerfilEstudiante _perfil = PerfilEstudiante(
    nombre: '',
    gradoId: 'grado_7',
    estiloAprendizaje: EstiloAprendizaje.pasoAPaso,
  );

  bool _esModoEdicionPerfil = false;
  Grado? _gradoSeleccionado;
  Unidad? _unidadSeleccionada;
  Seccion? _seccionSeleccionada;

  // CAMBIO (pestañas): 0 = Aprender (grados), 1 = Formulario (PDF).
  int _pestana = 0;
  bool _formularioVisitado = false; // el PDF se abre solo la primera vez que se entra

  @override
  Widget build(BuildContext context) {
    // 1. Si el perfil aún no se ha completado o está en modo edición, mostrar el formulario
    if (!_perfil.estaCompletado || _esModoEdicionPerfil) {
      return PantallaFormulario(
        perfilActual: _perfil,
        esEdicion: _esModoEdicionPerfil,
        onGuardarPerfil: (nuevoPerfil) {
          setState(() {
            _perfil = nuevoPerfil;
            _esModoEdicionPerfil = false;
          });
        },
      );
    }

    // 2. Si se seleccionó una sección, mostrar la pantalla de Chat con el Tutor IA
    if (_seccionSeleccionada != null && _unidadSeleccionada != null && _gradoSeleccionado != null) {
      return PantallaChatTutor(
        grado: _gradoSeleccionado!,
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

    // 3. Si se seleccionó una unidad, mostrar la lista de Secciones temáticas
    if (_unidadSeleccionada != null && _gradoSeleccionado != null) {
      return PantallaSecciones(
        grado: _gradoSeleccionado!,
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

    // 4. Si se seleccionó un grado, mostrar la lista de Unidades de dicho grado
    if (_gradoSeleccionado != null) {
      return PantallaUnidades(
        grado: _gradoSeleccionado!,
        onSeleccionarUnidad: (unidad) {
          setState(() {
            _unidadSeleccionada = unidad;
          });
        },
        onVolver: () {
          setState(() {
            _gradoSeleccionado = null;
          });
        },
      );
    }

    // 5. Por defecto: dos pestañas, "Aprender" (grados) y "Formulario" (PDF)
    return Scaffold(
      body: IndexedStack(
        index: _pestana,
        children: [
          PantallaGrados(
            perfil: _perfil,
            onSeleccionarGrado: (grado) {
              setState(() {
                _gradoSeleccionado = grado;
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
            key: ValueKey(_perfil.gradoId),
            gradoInicialId: _perfil.gradoId,
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