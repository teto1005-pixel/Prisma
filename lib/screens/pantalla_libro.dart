// lib/screens/pantalla_libro.dart

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../data/paginas_libros.dart';
import '../models/estructura_academica.dart';

/// Abre el libro de texto del grado en la primera página de la sección.
/// Se usa con Navigator para que el botón "atrás" del teléfono regrese al chat.
void abrirLibro(
    BuildContext context, {
      required Grado grado,
      required Seccion seccion,
    }) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PantallaLibro(grado: grado, seccion: seccion),
    ),
  );
}

class PantallaLibro extends StatefulWidget {
  const PantallaLibro({
    super.key,
    required this.grado,
    required this.seccion,
  });

  final Grado grado;
  final Seccion seccion;

  @override
  State<PantallaLibro> createState() => _PantallaLibroState();
}

class _PantallaLibroState extends State<PantallaLibro> {
  final PdfViewerController _controlador = PdfViewerController();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ruta = pdfPorGrado[widget.grado.id];
    final rango = paginasPorSeccion[widget.seccion.id];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.seccion.titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              rango == null
                  ? 'Libro de ${widget.grado.nombre}'
                  : 'Libro de ${widget.grado.nombre} • ${rango.etiqueta}',
              style: TextStyle(fontSize: 11, color: tema.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          if (rango != null) ...[
            IconButton(
              icon: const Icon(Icons.first_page),
              tooltip: 'Inicio de la sección',
              onPressed: () => _controlador.goToPage(pageNumber: rango.inicio),
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              tooltip: 'Fin de la sección',
              onPressed: () => _controlador.goToPage(pageNumber: rango.fin),
            ),
          ],
        ],
      ),
      body: ruta == null
          ? const Center(child: Text('No hay libro disponible para este grado.'))
          : PdfViewer.asset(
        ruta,
        controller: _controlador,
        initialPageNumber: rango?.inicio ?? 1,
      ),
    );
  }
}