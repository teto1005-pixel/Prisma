// lib/screens/pantalla_secciones.dart

import 'package:flutter/material.dart';
import '../data/paginas_libros.dart';
import '../models/estructura_academica.dart';
import 'pantalla_libro.dart';

/// Sombra suave de las tarjetas (equivale a Colors.black con alpha 0.04).
/// Al ser const no se recrea en cada rebuild.
const List<BoxShadow> _sombraTarjeta = [
  BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 10,
    offset: Offset(0, 4),
  ),
];

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
      backgroundColor: tema.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: tema.colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onVolver,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unidad ${unidad.numero}: ${unidad.asignatura}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${grado.nombre} • Temas y Secciones',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
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
              // --- BANNER DESTACADO DE LA UNIDAD ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tema.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: tema.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: tema.colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bookmark_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            unidad.titulo,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: tema.colorScheme.onPrimaryContainer,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Elige una sección temática para iniciar tu sesión de tutoría inteligente con IA.',
                      style: TextStyle(
                        fontSize: 12,
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Secciones Temáticas (${unidad.secciones.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: tema.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // --- LISTA DE TARJETAS DE SECCIONES REDONDEADAS ---
              ...unidad.secciones.map((Seccion seccion) {
                return _TarjetaSeccion(
                  grado: grado,
                  seccion: seccion,
                  onIniciar: () => onSeleccionarSeccion(seccion),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta individual de una sección temática.
class _TarjetaSeccion extends StatelessWidget {
  final Grado grado;
  final Seccion seccion;
  final VoidCallback onIniciar;

  const _TarjetaSeccion({
    super.key,
    required this.grado,
    required this.seccion,
    required this.onIniciar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // Una sola consulta al mapa (antes: containsKey + [] con '!').
    final paginaLibro = paginasPorSeccion[seccion.id];
    final colorChip = tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _sombraTarjeta,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seccion.titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tema.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              seccion.descripcionCorta,
              style: TextStyle(
                fontSize: 13,
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorChip,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    concepto,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: tema.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onIniciar,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text(
                  'Iniciar Tutoría con IA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            if (paginaLibro != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: tema.colorScheme.primary,
                  ),
                  onPressed: () => abrirLibro(
                    context,
                    grado: grado,
                    seccion: seccion,
                  ),
                  icon: const Icon(Icons.menu_book_outlined, size: 18),
                  label: Text(
                    'Ver en el libro (${paginaLibro.etiqueta})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}