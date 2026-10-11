// lib/screens/pantalla_chat_tutor.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../data/paginas_libros.dart';
import '../models/estructura_academica.dart';
import '../models/perfil_estudiante.dart';
import '../services/servicio_gemini.dart';
import 'calculadora_cientifica.dart';
import 'pantalla_libro.dart';

/// Modelo interno para gestionar los mensajes del chat interactivo.
class MensajeUI {
  final String id;
  final bool esUsuario;
  final String texto;
  final String hora;
  final bool esError;

  MensajeUI({
    required this.id,
    required this.esUsuario,
    required this.texto,
    required this.hora,
    this.esError = false,
  });
}

/// Pantalla principal de conversación en tiempo real con el Tutor Inteligente Secundaria.
class PantallaChatTutor extends StatefulWidget {
  final Grado grado;
  final Unidad unidad;
  final Seccion seccion;
  final PerfilEstudiante perfil;
  final VoidCallback onVolver;

  const PantallaChatTutor({
    super.key,
    required this.grado,
    required this.unidad,
    required this.seccion,
    required this.perfil,
    required this.onVolver,
  });

  @override
  State<PantallaChatTutor> createState() => _PantallaChatTutorState();
}

class _PantallaChatTutorState extends State<PantallaChatTutor> {
  final TextEditingController _controladorTexto = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ServicioGemini _servicioGemini = ServicioGemini();

  final List<MensajeUI> _mensajes = [];
  bool _estaCargando = false;
  String _textoEnCurso = '';

  @override
  void initState() {
    super.initState();
    _iniciarSesion();
  }

  /// Función para reparar automáticamente bloques LaTeX mal cerrados o pegados
  String _corregirLatex(String texto) {
    if (texto.isEmpty) return texto;

    String resultado = texto;

    // Repara casos como $3^2 + 4^2$ o expresiones donde la IA no cierra $ antes de comas, puntos o signos ?
    resultado = resultado.replaceAllMapped(
      RegExp(r'(\$[^\$\n]+?)([\,;\.\?]|(?:\s+antes|\s+decimos|\s+donde|\s+y\s+|\s+que\s+))'),
          (match) {
        String bloque = match.group(1)!;
        String seguido = match.group(2)!;
        if (!bloque.endsWith(r'$')) {
          return '$bloque\$$seguido';
        }
        return match.group(0)!;
      },
    );

    return resultado;
  }

  void _iniciarSesion() {
    _servicioGemini.iniciarChat(
      perfil: widget.perfil,
      grado: widget.grado,
      unidad: widget.unidad,
      seccion: widget.seccion,
    );

    final horaActual = _formatearHora();
    final nombreEstudiante = widget.perfil.nombre.isNotEmpty ? widget.perfil.nombre : 'estudiante';

    _mensajes.add(
      MensajeUI(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        esUsuario: false,
        texto: '''
¡Hola **$nombreEstudiante**! 👋 Soy tu tutor de **Secundaria**.

- Hoy exploraremos juntos: **${widget.seccion.titulo}** (*${widget.unidad.asignatura} - ${widget.grado.nombre}*).

He adaptado mis explicaciones para ti con tu estilo preferido: **${widget.perfil.estiloAprendizaje.nombreLegible}**.

¿Qué duda tienes sobre este tema? Puedes escribirla o seleccionar una de las preguntas sugeridas.
''',
        hora: horaActual,
      ),
    );
  }

  String _formatearHora() {
    final ahora = DateTime.now();
    final hora = ahora.hour > 12 ? ahora.hour - 12 : (ahora.hour == 0 ? 12 : ahora.hour);
    final ampm = ahora.hour >= 12 ? 'PM' : 'AM';
    final minuto = ahora.minute.toString().padLeft(2, '0');
    return '$hora:$minuto $ampm';
  }

  void _hacerScrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _seguirAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      if (pos.maxScrollExtent - pos.pixels < 150) {
        _scrollController.jumpTo(pos.maxScrollExtent);
      }
    });
  }

  Future<void> _enviarPregunta(String textoMensaje) async {
    final mensajeLimpio = textoMensaje.trim();
    if (mensajeLimpio.isEmpty || _estaCargando) return;

    final horaMensaje = _formatearHora();

    setState(() {
      _mensajes.add(
        MensajeUI(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          esUsuario: true,
          texto: mensajeLimpio,
          hora: horaMensaje,
        ),
      );
      _controladorTexto.clear();
      _estaCargando = true;
    });

    _hacerScrollAlFinal();

    try {
      final buffer = StringBuffer();
      final reloj = Stopwatch()..start();

      await for (final trozo in _servicioGemini.enviarMensajeStream(mensajeLimpio)) {
        if (!mounted) return;

        if (trozo == '[REINICIAR_RESPUESTA]') {
          buffer.clear();
          setState(() => _textoEnCurso = '');
          continue;
        }

        buffer.write(trozo);

        if (reloj.elapsedMilliseconds >= 80) {
          reloj.reset();
          setState(() => _textoEnCurso = _corregirLatex(buffer.toString()));
          _seguirAlFinal();
        }
      }

      if (!mounted) return;
      setState(() {
        _mensajes.add(
          MensajeUI(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            esUsuario: false,
            texto: _corregirLatex(buffer.toString()),
            hora: _formatearHora(),
          ),
        );
        _textoEnCurso = '';
        _estaCargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      final mensajeError = e is ErrorServicioGemini
          ? e.mensaje
          : 'Ocurrió un problema inesperado.';
      setState(() {
        _textoEnCurso = '';
        _mensajes.add(
          MensajeUI(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            esUsuario: false,
            texto: '⚠️ **No se pudo obtener respuesta del tutor:**\n\n$mensajeError\n\n*Intenta de nuevo en unos segundos.*',
            hora: _formatearHora(),
            esError: true,
          ),
        );
        _estaCargando = false;
      });
    }

    _hacerScrollAlFinal();
  }

  void _reiniciarConversacion() {
    setState(() {
      _mensajes.clear();
      _servicioGemini.reiniciarChat();
      _iniciarSesion();
    });
  }

  @override
  void dispose() {
    _controladorTexto.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onVolver,
        ),
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
              '${widget.unidad.asignatura} - ${widget.grado.nombre}',
              style: TextStyle(fontSize: 11, color: tema.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          if (paginasPorSeccion.containsKey(widget.seccion.id))
            IconButton(
              icon: const Icon(Icons.menu_book),
              tooltip: 'Ver en el libro',
              onPressed: () => abrirLibro(
                context,
                grado: widget.grado,
                seccion: widget.seccion,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reiniciar conversación',
            onPressed: _estaCargando ? null : _reiniciarConversacion,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              if (paginasPorSeccion.containsKey(widget.seccion.id))
                _construirBannerLibro(tema, paginasPorSeccion[widget.seccion.id]!),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: _mensajes.length + 1 + (_textoEnCurso.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _construirCajaSugerencias(tema);
                    }
                    if (index - 1 < _mensajes.length) {
                      final mensaje = _mensajes[index - 1];
                      return _construirBurbujaMensaje(mensaje, tema);
                    }
                    return _construirBurbujaMensaje(
                      MensajeUI(
                        id: 'respuesta_en_curso',
                        esUsuario: false,
                        texto: _textoEnCurso,
                        hora: _formatearHora(),
                      ),
                      tema,
                      transmitiendo: true,
                    );
                  },
                ),
              ),

              if (_estaCargando && _textoEnCurso.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: tema.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Prisma está pensando...',
                              style: TextStyle(fontSize: 12, color: tema.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              _construirBarraEntrada(tema),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirBannerLibro(ThemeData tema, RangoPaginas rango) {
    return Material(
      color: tema.colorScheme.secondaryContainer.withOpacity(0.5),
      child: InkWell(
        onTap: () => abrirLibro(
          context,
          grado: widget.grado,
          seccion: widget.seccion,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.menu_book, size: 16, color: tema.colorScheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'En tu libro de ${widget.grado.nombre}: ${rango.etiqueta}',
                  style: TextStyle(
                    fontSize: 12,
                    color: tema.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              Text(
                'Abrir',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: tema.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirCajaSugerencias(ThemeData tema) {
    if (widget.seccion.preguntasSugeridas.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Preguntas sugeridas para esta lección:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: tema.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.seccion.preguntasSugeridas.map((sug) {
              return ActionChip(
                label: Text(sug, style: const TextStyle(fontSize: 11)),
                onPressed: () => _enviarPregunta(sug),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              );
            }).toList(),
          ),
          const Divider(height: 20),
        ],
      ),
    );
  }

  Widget _construirBurbujaMensaje(
      MensajeUI mensaje,
      ThemeData tema, {
        bool transmitiendo = false,
      }) {
    final esUsuario = mensaje.esUsuario;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!esUsuario)
            CircleAvatar(
              radius: 16,
              backgroundColor: tema.colorScheme.primaryContainer,
              child: Icon(Icons.auto_awesome, size: 16, color: tema.colorScheme.primary),
            ),
          if (!esUsuario) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: esUsuario
                    ? tema.colorScheme.primary
                    : (mensaje.esError
                    ? tema.colorScheme.errorContainer
                    : tema.colorScheme.surfaceContainerHighest.withOpacity(0.5)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(esUsuario ? 16 : 4),
                  bottomRight: Radius.circular(esUsuario ? 4 : 16),
                ),
                border: Border.all(
                  color: esUsuario ? Colors.transparent : tema.colorScheme.outlineVariant.withOpacity(0.5),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (esUsuario)
                    Text(
                      mensaje.texto,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    )
                  else
                    GptMarkdown(
                      mensaje.texto,
                      useDollarSignsForLatex: true,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: mensaje.esError ? tema.colorScheme.onErrorContainer : tema.colorScheme.onSurface,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mensaje.hora,
                        style: TextStyle(
                          fontSize: 10,
                          color: esUsuario ? Colors.white70 : tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (!esUsuario && !mensaje.esError && !transmitiendo) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: mensaje.texto));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copiado al portapapeles'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Icon(Icons.copy, size: 13, color: tema.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (esUsuario) const SizedBox(width: 8),
          if (esUsuario)
            CircleAvatar(
              radius: 16,
              backgroundColor: tema.colorScheme.primary,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }

  void _abrirCalculadora() {
    mostrarCalculadora(
      context,
      alUsarResultado: (texto) {
        final actual = _controladorTexto.text;
        final nuevo = actual.isEmpty ? texto : '$actual $texto';
        _controladorTexto.value = TextEditingValue(
          text: nuevo,
          selection: TextSelection.collapsed(offset: nuevo.length),
        );
      },
    );
  }

  Widget _construirBarraEntrada(ThemeData tema) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        border: Border(top: BorderSide(color: tema.colorScheme.outlineVariant, width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.calculate_outlined),
              tooltip: 'Calculadora',
              onPressed: _abrirCalculadora,
            ),
            Expanded(
              child: TextField(
                controller: _controladorTexto,
                decoration: InputDecoration(
                  hintText: 'Pregúntale al tutor sobre esta lección...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: tema.colorScheme.outlineVariant),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: 3,
                minLines: 1,
                onSubmitted: (texto) => _enviarPregunta(texto),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: tema.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _estaCargando ? null : () => _enviarPregunta(_controladorTexto.text),
            ),
          ],
        ),
      ),
    );
  }
}