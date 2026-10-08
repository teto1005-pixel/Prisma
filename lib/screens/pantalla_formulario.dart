// lib/screens/pantalla_formulario.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/datos_curriculo.dart';
import '../models/estructura_academica.dart';
import '../models/perfil_estudiante.dart';

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

    // Guardar que la app ya fue configurada si es la primera vez
    if (!widget.esEdicion) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ya_configurado', true);
    }

    widget.onGuardarPerfil(nuevoPerfil);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: tema.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school,
                color: tema.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.esEdicion ? 'Editar Mi Perfil' : 'Bienvenido a SecundariaIA',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Educación Secundaria en Nicaragua',
                  style: TextStyle(fontSize: 12, color: tema.colorScheme.onSurfaceVariant),
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Hero Educativo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [tema.colorScheme.primary, tema.colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Tutor Inteligente con IA',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aprende a tu propio ritmo con IA',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Alineado con el currículo del MINED para estudiantes de secundaria de Nicaragua.',
                        style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Campo de Nombre
                Card(
                  shape: RoundedCornerShape(16),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. Tu Nombre',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: tema.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '¿Cómo te gustaría que el tutor IA te llame en las sesiones?',
                          style: TextStyle(fontSize: 13, color: tema.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _controladorNombre,
                          decoration: InputDecoration(
                            hintText: 'Ej: Carlos Fonseca, María Valle...',
                            errorText: _errorNombre ? 'Por favor ingresa tu nombre' : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          onChanged: (_) {
                            if (_errorNombre) setState(() => _errorNombre = false);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Selección de Grado Escolar
                Card(
                  shape: RoundedCornerShape(16),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2. Selecciona tu Grado de Secundaria',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: tema.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'El tutor adaptará la complejidad temática al grado oficial correspondiente.',
                          style: TextStyle(fontSize: 13, color: tema.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: DatosCurriculo.grados.map((Grado grado) {
                            final bool seleccionado = grado.id == _gradoSeleccionadoId;
                            return ChoiceChip(
                              label: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(grado.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(grado.alias, style: const TextStyle(fontSize: 10)),
                                ],
                              ),
                              selected: seleccionado,
                              onSelected: (bool selected) {
                                if (selected) {
                                  setState(() => _gradoSeleccionadoId = grado.id);
                                }
                              },
                              selectedColor: tema.colorScheme.primaryContainer,
                              shape: RoundedCornerShape(12),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Estilo de Aprendizaje
                Card(
                  shape: RoundedCornerShape(16),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '3. Tu Estilo de Aprendizaje Preferido',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: tema.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '¿De qué manera asimilas mejor las explicaciones y materias?',
                          style: TextStyle(fontSize: 13, color: tema.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 14),
                        ...EstiloAprendizaje.values.map((estilo) {
                          final bool seleccionado = estilo == _estiloSeleccionado;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() => _estiloSeleccionado = estilo),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: seleccionado
                                      ? tema.colorScheme.primaryContainer.withOpacity(0.5)
                                      : tema.colorScheme.surfaceVariant.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: seleccionado ? tema.colorScheme.primary : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _obtenerIconoEstilo(estilo),
                                      color: seleccionado ? tema.colorScheme.primary : tema.colorScheme.onSurfaceVariant,
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
                                              color: seleccionado ? tema.colorScheme.primary : null,
                                            ),
                                          ),
                                          Text(
                                            estilo.descripcion,
                                            style: TextStyle(
                                              fontSize: 12,
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
                ),
                const SizedBox(height: 24),

                // Botón de Inicio
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tema.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedCornerShape(14),
                    ),
                    onPressed: _guardarFormulario,
                    icon: const Icon(Icons.school),
                    label: Text(
                      widget.esEdicion ? 'Guardar Cambios' : 'Comenzar Tutoría SecundariaIA',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _obtenerIconoEstilo(EstiloAprendizaje estilo) {
    switch (estilo) {
      case EstiloAprendizaje.visual:
        return Icons.visibility;
      case EstiloAprendizaje.pasoAPaso:
        return Icons.format_list_numbered;
      case EstiloAprendizaje.simplificado:
        return Icons.bolt;
      case EstiloAprendizaje.explicativo:
        return Icons.psychology;
    }
  }

  RoundedRectangleBorder RoundedCornerShape(double r) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
}