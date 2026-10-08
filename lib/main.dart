import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/estructura_academica.dart';
import 'models/perfil_estudiante.dart';
import 'screens/pantalla_chat_tutor.dart';
import 'screens/pantalla_formulario.dart';
import 'screens/pantalla_grados.dart';
import 'screens/pantalla_secciones.dart';
import 'screens/pantalla_unidades.dart';

Future<void> main() async {
  // Asegura la conexión con el motor nativo de Flutter antes de llamadas asíncronas
  WidgetsFlutterBinding.ensureInitialized();

  // Carga de datos guardados en el dispositivo
  final prefs = await SharedPreferences.getInstance();
  final bool yaConfigurado = prefs.getBool('ya_configurado') ?? false;
  final String nombreGuardado = prefs.getString('perfil_nombre') ?? '';
  final String gradoIdGuardado = prefs.getString('perfil_grado_id') ?? 'grado_7';
  final int estiloIndexGuardado = prefs.getInt('perfil_estilo_index') ?? 0;

  // Reconstrucción del perfil guardado o valores por defecto
  final perfilInicial = PerfilEstudiante(
    nombre: nombreGuardado,
    gradoId: gradoIdGuardado,
    estiloAprendizaje: EstiloAprendizaje.values[
    estiloIndexGuardado.clamp(0, EstiloAprendizaje.values.length - 1)],
  );

  runApp(SecundariaIAApp(
    yaConfigurado: yaConfigurado,
    perfilInicial: perfilInicial,
  ));
}

/// Aplicación principal SecundariaIA configurada con Material Design 3.
class SecundariaIAApp extends StatelessWidget {
  final bool yaConfigurado;
  final PerfilEstudiante perfilInicial;

  const SecundariaIAApp({
    super.key,
    required this.yaConfigurado,
    required this.perfilInicial,
  });

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
      home: EnrutadorSecundariaIA(
        yaConfiguradoInicial: yaConfigurado,
        perfilInicial: perfilInicial,
      ),
    );
  }
}

/// Gestiona el estado de navegación y persistencia del perfil del estudiante.
class EnrutadorSecundariaIA extends StatefulWidget {
  final bool yaConfiguradoInicial;
  final PerfilEstudiante perfilInicial;

  const EnrutadorSecundariaIA({
    super.key,
    required this.yaConfiguradoInicial,
    required this.perfilInicial,
  });

  @override
  State<EnrutadorSecundariaIA> createState() => _EnrutadorSecundariaIAState();
}

class _EnrutadorSecundariaIAState extends State<EnrutadorSecundariaIA> {
  late PerfilEstudiante _perfil;
  late bool _yaConfigurado;
  bool _esModoEdicionPerfil = false;

  Grado? _gradoSeleccionado;
  Unidad? _unidadSeleccionada;
  Seccion? _seccionSeleccionada;

  @override
  void initState() {
    super.initState();
    _perfil = widget.perfilInicial;
    _yaConfigurado = widget.yaConfiguradoInicial;
  }

  /// Guarda el perfil de forma persistente en SharedPreferences.
  Future<void> _guardarPerfilEnDisco(PerfilEstudiante nuevoPerfil) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('perfil_nombre', nuevoPerfil.nombre);
    await prefs.setString('perfil_grado_id', nuevoPerfil.gradoId);
    await prefs.setInt('perfil_estilo_index', nuevoPerfil.estiloAprendizaje.index);
    await prefs.setBool('ya_configurado', true);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Si la app no ha sido configurada o el estudiante quiere editar su perfil
    if (!_yaConfigurado || _esModoEdicionPerfil) {
      return PantallaFormulario(
        perfilActual: _perfil,
        esEdicion: _esModoEdicionPerfil,
        onGuardarPerfil: (nuevoPerfil) async {
          await _guardarPerfilEnDisco(nuevoPerfil);
          setState(() {
            _perfil = nuevoPerfil;
            _yaConfigurado = true;
            _esModoEdicionPerfil = false;
          });
        },
      );
    }

    // 2. Si se seleccionó una sección, mostrar la pantalla de Chat con el Tutor IA
    if (_seccionSeleccionada != null &&
        _unidadSeleccionada != null &&
        _gradoSeleccionado != null) {
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

    // 5. Por defecto: Mostrar la pantalla de selección de Grados Académicos
    return PantallaGrados(
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
    );
  }
}