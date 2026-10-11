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

/// Sombras const (equivalen a Colors.black con alpha 0.03 y 0.04).
/// Al ser const no se recrean en cada rebuild.
const List<BoxShadow> _sombraBurbuja = [
  BoxShadow(
    color: Color(0x08000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  ),
];

const List<BoxShadow> _sombraIndicador = [
  BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 6,
    offset: Offset(0, 2),
  ),
];

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
  /// Almacén en memoria para no perder las conversaciones al salir de la pantalla
  static final Map<String, List<MensajeUI>> _historialMensajes = {};

  /// Expresión regular de _corregirLatex: se compila una sola vez
  /// (antes se recompilaba en cada trozo recibido de la IA).
  static final RegExp _regexLatexPegado = RegExp(
    r'(\$[^\$\n]+?)([\,;\.\?]|(?:\s+antes|\s+decimos|\s+donde|\s+y\s+|\s+que\s+))',
  );

  /// Fórmula en línea $...$ (sin tocar los bloques $$...$$), en una sola línea.
  static final RegExp _regexMatematicaEnLinea = RegExp(
    r'(?<!\$)\$(?!\$)([^\$\n]+?)\$(?!\$)',
  );

  /// Contenido de una fórmula que empieza con un número.
  static final RegExp _regexEmpiezaConDigito = RegExp(r'^\d');

  final TextEditingController _controladorTexto = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ServicioGemini _servicioGemini = ServicioGemini();

  final List<MensajeUI> _mensajes = [];
  bool _estaCargando = false;
  String _textoEnCurso = '';

  /// Replica _textoEnCurso para redibujar solo la burbuja que se está
  /// transmitiendo, sin reconstruir toda la lista de mensajes.
  final ValueNotifier<String> _textoEnCursoNotificador = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _iniciarSesion();
  }

  /// Función para reparar automáticamente bloques LaTeX mal cerrados o pegados
  String _corregirLatex(String texto) {
    if (texto.isEmpty) return texto;

    return texto.split('\n').map((linea) {
      var resultado = linea;

      // 1) Si los $ de la línea vienen en pares, el LaTeX ya está bien cerrado:
      // no se toca. Antes se insertaban $ de más (por ejemplo en "$2^5$) y ...")
      // y la fórmula se mostraba como código.
      if (!'\$'.allMatches(resultado).length.isEven) {
        resultado = resultado.replaceAllMapped(
          _regexLatexPegado,
              (match) {
            String bloque = match.group(1)!;
            String seguido = match.group(2)!;
            if (!bloque.endsWith(r'$')) {
              return '$bloque\$$seguido';
            }
            return match.group(0)!;
          },
        );
      }

      // 2) gpt_markdown no reconoce como fórmula un "$" seguido de un número
      // (ej. "$3, 6, 9$"). Un espacio fino "\," al inicio lo soluciona y no
      // cambia cómo se ve la fórmula.
      return resultado.replaceAllMapped(
        _regexMatematicaEnLinea,
            (match) {
          final contenido = match.group(1)!;
          if (_regexEmpiezaConDigito.hasMatch(contenido)) {
            return '\$\\,$contenido\$';
          }
          return match.group(0)!;
        },
      );
    }).join('\n');
  }

  /// Actualiza el texto de la respuesta en transmisión. Solo reconstruye la
  /// pantalla completa cuando la burbuja aparece o desaparece; mientras llegan
  /// trozos únicamente se redibuja la burbuja en curso.
  void _actualizarTextoEnCurso(String nuevo) {
    final cambiaVisibilidad = _textoEnCurso.isEmpty != nuevo.isEmpty;
    _textoEnCurso = nuevo;
    _textoEnCursoNotificador.value = nuevo;
    if (cambiaVisibilidad) setState(() {});
  }

  void _iniciarSesion() {
    _servicioGemini.iniciarChat(
      perfil: widget.perfil,
      grado: widget.grado,
      unidad: widget.unidad,
      seccion: widget.seccion,
    );

    // Si ya existen mensajes guardados para esta sección, los recuperamos
    if (_historialMensajes.containsKey(widget.seccion.id) &&
        _historialMensajes[widget.seccion.id]!.isNotEmpty) {
      _mensajes.addAll(_historialMensajes[widget.seccion.id]!);
      _hacerScrollAlFinal();
      return;
    }

    final horaActual = _formatearHora();
    final nombreEstudiante = widget.perfil.nombre.isNotEmpty ? widget.perfil.nombre : 'estudiante';

    final mensajeInicial = MensajeUI(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      esUsuario: false,
      texto: '''
¡Hola **$nombreEstudiante**! 👋 Soy tu tutor de **Secundaria**.

- Hoy exploraremos juntos: **${widget.seccion.titulo}** (*${widget.unidad.asignatura} - ${widget.grado.nombre}*).

He adaptado mis explicaciones para ti con tu estilo preferido: **${widget.perfil.estiloAprendizaje.nombreLegible}**.

¿Qué duda tienes sobre este tema? Puedes escribirla o seleccionar una de las preguntas sugeridas.
''',
      hora: horaActual,
    );

    _mensajes.add(mensajeInicial);
    _historialMensajes[widget.seccion.id] = List.from(_mensajes);
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
          _actualizarTextoEnCurso('');
          continue;
        }

        buffer.write(trozo);

        if (reloj.elapsedMilliseconds >= 80) {
          reloj.reset();
          _actualizarTextoEnCurso(_corregirLatex(buffer.toString()));
          _seguirAlFinal();
        }
      }

      if (!mounted) return;
      _textoEnCursoNotificador.value = '';
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
        _historialMensajes[widget.seccion.id] = List.from(_mensajes);
      });
    } catch (e) {
      if (!mounted) return;
      final mensajeError = e is ErrorServicioGemini
          ? e.mensaje
          : 'Ocurrió un problema inesperado.';
      _textoEnCursoNotificador.value = '';
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
        _historialMensajes[widget.seccion.id] = List.from(_mensajes);
      });
    }

    _hacerScrollAlFinal();
  }

  void _reiniciarConversacion() {
    setState(() {
      _mensajes.clear();
      _historialMensajes.remove(widget.seccion.id);
      _servicioGemini.reiniciarChat();
      _iniciarSesion();
    });
  }

  @override
  void dispose() {
    _controladorTexto.dispose();
    _scrollController.dispose();
    _textoEnCursoNotificador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final rangoLibro = paginasPorSeccion[widget.seccion.id];

    return Scaffold(
      backgroundColor: tema.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: tema.colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onVolver,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.seccion.titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.unidad.asignatura} - ${widget.grado.nombre}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          if (rangoLibro != null)
            IconButton(
              icon: const Icon(Icons.menu_book, color: Colors.white),
              tooltip: 'Ver en el libro',
              onPressed: () => abrirLibro(
                context,
                grado: widget.grado,
                seccion: widget.seccion,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
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
              if (rangoLibro != null) _construirBannerLibro(tema, rangoLibro),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: _mensajes.length + 1 + (_textoEnCurso.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _construirCajaSugerencias(tema);
                    }
                    if (index - 1 < _mensajes.length) {
                      final mensaje = _mensajes[index - 1];
                      return _construirBurbujaMensaje(mensaje, tema);
                    }
                    return ValueListenableBuilder<String>(
                      valueListenable: _textoEnCursoNotificador,
                      builder: (context, textoActual, _) {
                        return _construirBurbujaMensaje(
                          MensajeUI(
                            id: 'respuesta_en_curso',
                            esUsuario: false,
                            texto: textoActual,
                            hora: _formatearHora(),
                          ),
                          tema,
                          transmitiendo: true,
                        );
                      },
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _sombraIndicador,
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
                            const SizedBox(width: 10),
                            Text(
                              'Prisma está pensando...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: tema.colorScheme.onSurfaceVariant,
                              ),
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
      color: tema.colorScheme.primaryContainer.withValues(alpha: 0.3),
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
              Icon(Icons.menu_book, size: 16, color: tema.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'En tu libro de ${widget.grado.nombre}: ${rango.etiqueta}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: tema.colorScheme.onSurface,
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.seccion.preguntasSugeridas.map((sug) {
              return ActionChip(
                label: Text(sug, style: const TextStyle(fontSize: 12)),
                onPressed: () => _enviarPregunta(sug),
                backgroundColor: tema.colorScheme.surface,
                labelStyle: TextStyle(color: tema.colorScheme.onSurface),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Divider(color: tema.colorScheme.outlineVariant.withValues(alpha: 0.4)),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!esUsuario)
            CircleAvatar(
              radius: 16,
              backgroundColor: tema.colorScheme.primaryContainer.withValues(alpha: 0.6),
              child: Icon(Icons.auto_awesome, size: 16, color: tema.colorScheme.primary),
            ),
          if (!esUsuario) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: esUsuario
                    ? tema.colorScheme.primary
                    : (mensaje.esError
                    ? tema.colorScheme.errorContainer
                    : tema.colorScheme.surface),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(esUsuario ? 18 : 4),
                  bottomRight: Radius.circular(esUsuario ? 4 : 18),
                ),
                boxShadow: _sombraBurbuja,
                border: Border.all(
                  color: esUsuario
                      ? Colors.transparent
                      : tema.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  width: 1.0,
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
                        height: 1.45,
                        color: mensaje.esError
                            ? tema.colorScheme.onErrorContainer
                            : tema.colorScheme.onSurface,
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
                          color: esUsuario
                              ? Colors.white.withValues(alpha: 0.75)
                              : tema.colorScheme.onSurfaceVariant,
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
                          child: Icon(
                            Icons.copy_rounded,
                            size: 13,
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
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
    final colorBorde = tema.colorScheme.outlineVariant.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tema.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorBorde,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.calculate_outlined, color: tema.colorScheme.primary),
              tooltip: 'Calculadora',
              onPressed: _abrirCalculadora,
            ),
            Expanded(
              child: TextField(
                controller: _controladorTexto,
                decoration: InputDecoration(
                  hintText: 'Pregúntale al tutor sobre esta lección...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colorBorde),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: tema.colorScheme.primary,
                      width: 1.5,
                    ),
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
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                backgroundColor: tema.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: _estaCargando ? null : () => _enviarPregunta(_controladorTexto.text),
            ),
          ],
        ),
      ),
    );
  }
}