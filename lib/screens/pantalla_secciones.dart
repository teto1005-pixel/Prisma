// lib/screens/pantalla_secciones.dart

import 'package:flutter/material.dart';
import '../data/paginas_libros.dart';
import '../models/estructura_academica.dart';
import 'pantalla_libro.dart';

/// Pantalla que desglosa las secciones temáticas de una unidad para iniciar la sesión de IA.
class PantallaSecciones extends StatelessWidget {
  final Grado grado;
  final Unidad unidad;
  final Function(Seccion) onSeleccionarSeccion;
  final VoidCallback onVolver;

  const PantallaSecciones({
    super.key,
    required this.grado,
    required this.unidad,
    required this.onSeleccionarSeccion,
    required this.onVolver,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onVolver,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unidad ${unidad.numero}: ${unidad.asignatura}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              '${grado.nombre} • Temas y Secciones',
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
              // Encabezado de Unidad
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tema.colorScheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: tema.colorScheme.primary,
                          radius: 16,
                          child: const Icon(Icons.bookmark, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            unidad.titulo,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: tema.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Elige una sección temática para iniciar tu sesión de tutoría inteligente con IA.',
                      style: TextStyle(fontSize: 12, color: tema.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Text(
                'Secciones Temáticas (${unidad.secciones.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Lista de Secciones
              ...unidad.secciones.map((Seccion seccion) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seccion.titulo,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          seccion.descripcionCorta,
                          style: TextStyle(fontSize: 13, color: tema.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Conceptos Clave:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: tema.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: seccion.conceptosClave.map((concepto) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: tema.colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                concepto,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tema.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tema.colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => onSeleccionarSeccion(seccion),
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            label: const Text(
                              'Iniciar Tutoría con IA',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        // CAMBIO (libro): páginas de la sección y acceso al libro.
                        if (paginasPorSeccion.containsKey(seccion.id))
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () => abrirLibro(
                                context,
                                grado: grado,
                                seccion: seccion,
                              ),
                              icon: const Icon(Icons.menu_book, size: 18),
                              label: Text(
                                'Ver en el libro (${paginasPorSeccion[seccion.id]!.etiqueta})',
                              ),
                            ),
                          ),
                      ],
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
}