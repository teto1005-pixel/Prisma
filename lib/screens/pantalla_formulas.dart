// lib/screens/pantalla_formulas.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

/// Un PDF de formulario por grado. Las claves son los ids de `Grado`.
/// Copia tus PDF a assets/pdf/ con estos nombres (o cambia los nombres aquí).
const Map<String, String> pdfFormularioPorGrado = {
  '7mo': 'assets/pdf/formulario_7mo.pdf',
  '8vo': 'assets/pdf/formulario_8vo.pdf',
  '9no': 'assets/pdf/formulario_9no.pdf',
  '10mo': 'assets/pdf/formulario_10mo.pdf',
  '11mo': 'assets/pdf/formulario_11mo.pdf',
};

/// Muestra el formulario (PDF) de cada grado para consulta de los estudiantes.
/// Abre el del grado del estudiante y permite cambiar a los demás.
/// Se puede hacer zoom con dos dedos y desplazarse hacia arriba y abajo.
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
  final Map<String, PdfViewerController> _controladores = {};

  /// Grados cuyo PDF ya se abrió: cada visor se crea al entrar por primera
  /// vez y luego conserva la página en la que se quedó el estudiante.
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
    for (final id in _ids) {
      _controladores[id] = PdfViewerController();
    }
    _disponibles = _leerDisponibles();
  }

  /// Qué PDF están realmente incluidos en la app, para avisar con claridad
  /// (y no mostrar una pantalla en blanco) si falta alguno.
  Future<Set<String>> _leerDisponibles() async {
    try {
      final manifiesto = await AssetManifest.loadFromAssetBundle(rootBundle);
      final incluidos = manifiesto.listAssets().toSet();
      return {
        for (final e in pdfFormularioPorGrado.entries)
          if (incluidos.contains(e.value)) e.key,
      };
    } catch (_) {
      return pdfFormularioPorGrado.keys.toSet(); // no se pudo comprobar: se intenta abrir
    }
  }

  Future<void> _irA(int pagina) async {
    try {
      await _controladores[_gradoId]?.goToPage(pageNumber: pagina);
    } catch (_) {
      // Si la página no existe o el PDF aún carga, se queda donde estaba.
    }
  }

  Future<void> _preguntarPagina() async {
    final campo = TextEditingController();
    final texto = await showDialog<String>(
      context: context,
      builder: (contextoDialogo) {
        return AlertDialog(
          title: const Text('Ir a la página'),
          content: TextField(
            controller: campo,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(hintText: 'Número de página'),
            onSubmitted: (valor) => Navigator.of(contextoDialogo).pop(valor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contextoDialogo).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(contextoDialogo).pop(campo.text),
              child: const Text('Ir'),
            ),
          ],
        );
      },
    );
    campo.dispose();

    final pagina = int.tryParse(texto ?? '');
    if (pagina != null && pagina >= 1) await _irA(pagina);
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
      controller: _controladores[id]!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Formulario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Fórmulas de matemáticas para consultar',
              style: TextStyle(fontSize: 11, color: tema.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.first_page),
            tooltip: 'Primera página',
            onPressed: () => _irA(1),
          ),
          IconButton(
            icon: const Icon(Icons.pin_outlined),
            tooltip: 'Ir a la página...',
            onPressed: _preguntarPagina,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final id in _ids)
                    ButtonSegment<String>(value: id, label: Text(id)),
                ],
                selected: {_gradoId},
                onSelectionChanged: (seleccion) {
                  setState(() {
                    _gradoId = seleccion.first;
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