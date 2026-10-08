// lib/screens/pantalla_unidades.dart

import 'package:flutter/material.dart';
import '../models/estructura_academica.dart';

/// Pantalla que presenta las unidades de aprendizaje correspondientes al grado seleccionado.
class PantallaUnidades extends StatefulWidget {
  final Grado grado;
  final Function(Unidad) onSeleccionarUnidad;
  final VoidCallback onVolver;

  const PantallaUnidades({
    super.key,
    required this.grado,
    required this.onSeleccionarUnidad,
    required this.onVolver,
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onVolver,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.grado.nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              '${widget.grado.alias} • Unidades Curriculares',
              style: TextStyle(fontSize: 12, color: tema.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Barra de filtros por Asignatura
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: asignaturas.map((asig) {
                    final seleccionada = asig == _filtroAsignatura;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(asig),
                        selected: seleccionada,
                        onSelected: (_) => setState(() => _filtroAsignatura = asig),
                        selectedColor: tema.colorScheme.primaryContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Unidades de Aprendizaje (${unidadesFiltradas.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Tarjetas de Unidades
              ...unidadesFiltradas.map((Unidad unidad) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => widget.onSeleccionarUnidad(unidad),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: tema.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _resolverIcono(unidad.icono),
                              color: tema.colorScheme.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tema.colorScheme.secondaryContainer.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${unidad.asignatura} • Unidad ${unidad.numero}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: tema.colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  unidad.titulo,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${unidad.secciones.length} secciones temáticas con Tutor IA',
                                  style: TextStyle(fontSize: 12, color: tema.colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, size: 16, color: tema.colorScheme.primary),
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
    );
  }

  IconData _resolverIcono(String icono) {
    switch (icono) {
      case 'calculate':
        return Icons.calculate;
      case 'functions':
        return Icons.functions;
      case 'change_history':
        return Icons.change_history;
      case 'show_chart':
        return Icons.show_chart;
      case 'menu_book':
      case 'auto_stories':
        return Icons.menu_book;
      case 'format_quote':
        return Icons.format_quote;
      case 'biotech':
        return Icons.biotech;
      case 'science':
        return Icons.science;
      case 'favorite':
        return Icons.favorite;
      case 'speed':
        return Icons.speed;
      case 'shield':
        return Icons.shield;
      case 'hub':
        return Icons.hub;
      default:
        return Icons.school;
    }
  }
}
