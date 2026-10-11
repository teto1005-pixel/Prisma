// lib/screens/pantalla_formulario.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/datos_curriculo.dart';
import '../models/estructura_academica.dart';
import '../models/perfil_estudiante.dart';

/// Sombra suave de las tarjetas (equivale a Colors.black con alpha 0.04).
/// Al ser const no se recrea en cada rebuild.
const List<BoxShadow> _sombraTarjeta = [
  BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 10,
    offset: Offset(0, 4),
  ),
];

/// Pantalla de formulario inicial (Onboarding) y edición de perfil del estudiante.
class PantallaFormulario extends StatefulWidget {
  final PerfilEstudiante perfilActual;
  final Function(PerfilEstudiante) onGuardarPerfil;
  final bool esEdicion;

  const PantallaFormulario({
    super.key,
    required this.perfilActual,
    required this.onGuardarPerfil,
    this.esEdicion = false,
  });

  @override
  State<PantallaFormulario> createState() => _PantallaFormularioState();
}

class _PantallaFormularioState extends State<PantallaFormulario> {
  late TextEditingController _controladorNombre;
  late String _gradoSeleccionadoId;
  late EstiloAprendizaje _estiloSeleccionado;
  bool _errorNombre = false;

  @override
  void initState() {
    super.initState();
    _controladorNombre = TextEditingController(text: widget.perfilActual.nombre);
    _gradoSeleccionadoId = widget.perfilActual.gradoId;
    _estiloSeleccionado = widget.perfilActual.estiloAprendizaje;
  }

  @override
  void dispose() {
    _controladorNombre.dispose();
    super.dispose();
  }

  Future<void> _guardarFormulario() async {
    final nombre = _controladorNombre.text.trim();
    if (nombre.isEmpty) {
      setState(() {
        _errorNombre = true;
      });
      return;
    }

    final nuevoPerfil = PerfilEstudiante(
      nombre: nombre,
      gradoId: _gradoSeleccionadoId,
      estiloAprendizaje: _estiloSeleccionado,
    );

    if (!widget.esEdicion) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ya_configurado', true);
    }

    widget.onGuardarPerfil(nuevoPerfil);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    // Colores derivados que se usaban varias veces: se calculan una sola vez.
    final colorFondoSuave = tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final colorBordeSuave = tema.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: tema.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: tema.colorScheme.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.esEdicion ? 'Editar Mi Perfil' : 'Bienvenido a Prisma',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Educación Secundaria en Nicaragua',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- BANNER HERO EDUCATIVO ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tema.colorScheme.primary,
                        tema.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: tema.colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white70, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Tutor Inteligente con IA',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Aprende a tu propio ritmo con IA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Alineado con el currículo del MINED para estudiantes de secundaria de Nicaragua.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- 1. CAMPO DE NOMBRE ---
                _TarjetaFormulario(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _EncabezadoTarjeta(
                        titulo: '1. Tu Nombre',
                        subtitulo: '¿Cómo te gustaría que el tutor te llame en las sesiones?',
                      ),
                      TextField(
                        controller: _controladorNombre,
                        decoration: InputDecoration(
                          hintText: 'Nombre o Apodo',
                          errorText: _errorNombre ? 'Por favor ingresa tu nombre' : null,
                          filled: true,
                          fillColor: colorFondoSuave,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: colorBordeSuave),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: tema.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          prefixIcon: Icon(Icons.person_outline, color: tema.colorScheme.primary),
                        ),
                        onChanged: (_) {
                          if (_errorNombre) setState(() => _errorNombre = false);
                        },
                      ),
                    ],
                  ),
                ),

                // --- 2. SELECCIÓN DE GRADO ESCOLAR ---
                _TarjetaFormulario(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _EncabezadoTarjeta(
                        titulo: '2. Selecciona tu Grado de Secundaria',
                        subtitulo: 'El tutor adaptará la complejidad temática al grado oficial correspondiente.',
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: DatosCurriculo.grados.map((Grado grado) {
                          final bool seleccionado = grado.id == _gradoSeleccionadoId;
                          return ChoiceChip(
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    grado.nombre,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: seleccionado ? Colors.white : tema.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    grado.alias,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: seleccionado
                                          ? Colors.white.withValues(alpha: 0.8)
                                          : tema.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            selected: seleccionado,
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(() => _gradoSeleccionadoId = grado.id);
                              }
                            },
                            selectedColor: tema.colorScheme.primary,
                            backgroundColor: colorFondoSuave,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: seleccionado ? Colors.transparent : colorBordeSuave,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // --- 3. ESTILO DE APRENDIZAJE ---
                _TarjetaFormulario(
                  margenInferior: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _EncabezadoTarjeta(
                        titulo: '3. Tu Estilo de Aprendizaje Preferido',
                        subtitulo: '¿De qué manera asimilas mejor las explicaciones y materias?',
                      ),
                      ...EstiloAprendizaje.values.map((estilo) {
                        final bool seleccionado = estilo == _estiloSeleccionado;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setState(() => _estiloSeleccionado = estilo),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: seleccionado
                                    ? tema.colorScheme.primaryContainer.withValues(alpha: 0.5)
                                    : tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: seleccionado ? tema.colorScheme.primary : colorBordeSuave,
                                  width: seleccionado ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _obtenerIconoEstilo(estilo),
                                    color: seleccionado
                                        ? tema.colorScheme.primary
                                        : tema.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          estilo.nombreLegible,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: seleccionado
                                                ? tema.colorScheme.primary
                                                : tema.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          estilo.descripcion,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: tema.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // --- BOTÓN DE INICIO ---
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tema.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _guardarFormulario,
                    icon: const Icon(Icons.school, size: 20),
                    label: Text(
                      widget.esEdicion ? 'Guardar Cambios' : 'Comenzar Tutoría Secundaria',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _obtenerIconoEstilo(EstiloAprendizaje estilo) {
    switch (estilo) {
      case EstiloAprendizaje.pasoAPaso:
        return Icons.format_list_numbered_rounded;
      case EstiloAprendizaje.simplificado:
        return Icons.bolt_rounded;
      case EstiloAprendizaje.explicativo:
        return Icons.psychology_rounded;
    }
  }
}

/// Contenedor blanco redondeado con sombra, común a las 3 tarjetas del formulario.
class _TarjetaFormulario extends StatelessWidget {
  final Widget child;
  final double margenInferior;

  const _TarjetaFormulario({
    required this.child,
    this.margenInferior = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: margenInferior),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _sombraTarjeta,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

/// Título + subtítulo que encabeza cada tarjeta del formulario.
class _EncabezadoTarjeta extends StatelessWidget {
  final String titulo;
  final String subtitulo;

  const _EncabezadoTarjeta({
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: tema.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitulo,
          style: TextStyle(
            fontSize: 12,
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}