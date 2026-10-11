// lib/screens/pantalla_unidades.dart

import 'package:flutter/material.dart';
import '../data/datos_curriculo.dart';
import '../models/estructura_academica.dart';

/// Pantalla que presenta las unidades con diseño moderno, tarjetas redondeadas
/// y colores alineados al tema principal.
class PantallaUnidades extends StatefulWidget {
  final Grado grado;
  final String nombreEstudiante;
  final Function(Unidad) onSeleccionarUnidad;
  final Function(Grado) onCambiarGrado;
  final VoidCallback onEditarPerfil;

  const PantallaUnidades({
    super.key,
    required this.grado,
    this.nombreEstudiante = '',
    required this.onSeleccionarUnidad,
    required this.onCambiarGrado,
    required this.onEditarPerfil,
  });

  @override
  State<PantallaUnidades> createState() => _PantallaUnidadesState();
}

class _PantallaUnidadesState extends State<PantallaUnidades> {
  String _filtroAsignatura = 'Todas';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final asignaturas = ['Todas', ...widget.grado.unidades.map((u) => u.asignatura).toSet()];

    final unidadesFiltradas = _filtroAsignatura == 'Todas'
        ? widget.grado.unidades
        : widget.grado.unidades.where((u) => u.asignatura == _filtroAsignatura).toList();

    final nombreMostrar = widget.nombreEstudiante.isNotEmpty ? widget.nombreEstudiante : 'estudiante';

    return Scaffold(
      backgroundColor: tema.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: tema.colorScheme.primary,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text(
              'PRISMA',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Grado>(
                  value: widget.grado,
                  isDense: true,
                  dropdownColor: tema.colorScheme.primary,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  items: listaGrados.map((Grado g) {
                    return DropdownMenuItem<Grado>(
                      value: g,
                      child: Text(g.nombre, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (Grado? nuevoGrado) {
                    if (nuevoGrado != null && nuevoGrado.id != widget.grado.id) {
                      setState(() {
                        _filtroAsignatura = 'Todas';
                      });
                      widget.onCambiarGrado(nuevoGrado);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: 'Perfil',
            onPressed: widget.onEditarPerfil,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- BANNER DE SALUDO PERSONALIZADO ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, $nombreMostrar! 👋',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: tema.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estas son tus unidades para ${widget.grado.nombre} de Secundaria en Nicaragua',
                      style: TextStyle(
                        fontSize: 13,
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- FILTROS POR ASIGNATURA ---
              if (asignaturas.length > 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: asignaturas.map((asig) {
                        final seleccionada = asig == _filtroAsignatura;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(asig),
                            selected: seleccionada,
                            onSelected: (_) => setState(() => _filtroAsignatura = asig),
                            selectedColor: tema.colorScheme.primary,
                            labelStyle: TextStyle(
                              color: seleccionada ? Colors.white : tema.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // --- LISTA DE TARJETAS REDONDEADAS ---
              ...unidadesFiltradas.map((Unidad unidad) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => widget.onSeleccionarUnidad(unidad),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: tema.colorScheme.primaryContainer.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _resolverIcono(unidad.icono),
                                color: tema.colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    unidad.titulo,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: tema.colorScheme.onSurface,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${unidad.secciones.length} temas clave con Tutor IA',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tema.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: tema.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  IconData _resolverIcono(String icono) {
    switch (icono) {
      case 'calculate':
        return Icons.calculate_outlined;
      case 'functions':
        return Icons.functions_outlined;
      case 'change_history':
        return Icons.change_history_outlined;
      case 'show_chart':
        return Icons.show_chart_outlined;
      case 'menu_book':
      case 'auto_stories':
        return Icons.auto_stories_outlined;
      default:
        return Icons.school_outlined;
    }
  }
}