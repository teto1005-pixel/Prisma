// lib/screens/pantalla_formulas.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

/// Un PDF de formulario por grado. Las claves son los ids de `Grado`.
const Map<String, String> pdfFormularioPorGrado = {
  '7mo': 'assets/pdf/formulario_7mo.pdf',
  '8vo': 'assets/pdf/formulario_8vo.pdf',
  '9no': 'assets/pdf/formulario_9no.pdf',
  '10mo': 'assets/pdf/formulario_10mo.pdf',
  '11mo': 'assets/pdf/formulario_11mo.pdf',
};

/// Muestra el formulario (PDF) de cada grado para consulta de los estudiantes.
/// Se puede hacer zoom con dos dedos y desplazarse libremente hacia arriba y abajo.
class PantallaFormulas extends StatefulWidget {
  const PantallaFormulas({super.key, this.gradoInicialId});

  /// Id del grado del estudiante (por ejemplo "8vo"). Si no coincide con
  /// ninguno, se abre el primero de la lista.
  final String? gradoInicialId;

  @override
  State<PantallaFormulas> createState() => _PantallaFormulasState();
}

class _PantallaFormulasState extends State<PantallaFormulas> {
  final List<String> _ids = pdfFormularioPorGrado.keys.toList();

  /// Controladores creados bajo demanda: solo existen para los grados que
  /// el estudiante realmente abre.
  final Map<String, PdfViewerController> _controladores = {};

  /// Grados cuyo PDF ya se abrió.
  final Set<String> _visitados = {};

  late String _gradoId;
  late final Future<Set<String>> _disponibles;

  @override
  void initState() {
    super.initState();
    final inicial = widget.gradoInicialId;
    _gradoId = (inicial != null && pdfFormularioPorGrado.containsKey(inicial))
        ? inicial
        : _ids.first;
    _visitados.add(_gradoId);
    _disponibles = _leerDisponibles();
  }

  /// Qué PDF están realmente incluidos en la app.
  Future<Set<String>> _leerDisponibles() async {
    try {
      final manifiesto = await AssetManifest.loadFromAssetBundle(rootBundle);
      final incluidos = manifiesto.listAssets().toSet();
      return {
        for (final e in pdfFormularioPorGrado.entries)
          if (incluidos.contains(e.value)) e.key,
      };
    } catch (_) {
      return pdfFormularioPorGrado.keys.toSet();
    }
  }

  Widget _visor(String id, Set<String> disponibles, ThemeData tema) {
    if (!_visitados.contains(id)) return const SizedBox.shrink();

    final ruta = pdfFormularioPorGrado[id]!;
    if (!disponibles.contains(id)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No se encontró el formulario de $id.\n\n'
                'Copia el PDF a $ruta y vuelve a compilar la app.',
            textAlign: TextAlign.center,
            style: TextStyle(color: tema.colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return PdfViewer.asset(
      ruta,
      key: ValueKey(id),
      controller: _controladores.putIfAbsent(id, () => PdfViewerController()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: tema.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: tema.colorScheme.primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Formulario',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Fórmulas de matemáticas para consultar',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: tema.colorScheme.primary,
                  selectedForegroundColor: Colors.white,
                  side: BorderSide(
                    color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                segments: [
                  for (final id in _ids)
                    ButtonSegment<String>(
                      value: id,
                      label: Text(
                        id,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
                selected: {_gradoId},
                onSelectionChanged: (seleccion) {
                  final nuevoId = seleccion.first;
                  if (nuevoId == _gradoId) return;
                  setState(() {
                    _gradoId = nuevoId;
                    _visitados.add(_gradoId);
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<Set<String>>(
              future: _disponibles,
              builder: (context, instantanea) {
                final disponibles = instantanea.data;
                if (disponibles == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return IndexedStack(
                  index: _ids.indexOf(_gradoId),
                  children: [
                    for (final id in _ids) _visor(id, disponibles, tema),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}