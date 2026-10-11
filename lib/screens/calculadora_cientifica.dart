// lib/screens/calculadora_cientifica.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/editor_expresion.dart';
import '../services/motor_calculadora.dart';

/// Abre la calculadora como una hoja que sube desde abajo.
Future<void> mostrarCalculadora(
    BuildContext context, {
      void Function(String texto)? alUsarResultado,
    }) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (contextoHoja) {
      return FractionallySizedBox(
        heightFactor: 0.97,
        child: CalculadoraCientifica(
          alUsarResultado: alUsarResultado == null
              ? null
              : (texto) {
            Navigator.of(contextoHoja).pop();
            alUsarResultado(texto);
          },
        ),
      );
    },
  );
}

class CalculadoraCientifica extends StatefulWidget {
  const CalculadoraCientifica({super.key, this.alUsarResultado});

  final void Function(String texto)? alUsarResultado;

  @override
  State<CalculadoraCientifica> createState() => _CalculadoraCientificaState();
}

class _CalculadoraCientificaState extends State<CalculadoraCientifica> {
  /// Tamaño de letra según qué tan adentro de una cajita se escribe.
  static const List<double> _tamanos = [30, 24, 19, 15];

  /// Lo que se está escribiendo (fracciones, raíces, etc. con sus cajitas).
  final EditorExpresion _editor = EditorExpresion();

  /// Para mantener a la vista el cursor cuando la expresión es larga.
  final GlobalKey _claveCursor = GlobalKey();

  bool _grados = true;
  Valor? _ans;
  Valor? _valor;
  String? _error;
  List<ModoResultado> _modos = const [];
  int _modoIdx = 0;

  /// true justo después de "=": la siguiente tecla empieza una cuenta nueva.
  bool _trasResultado = false;

  ModoResultado get _modo =>
      _modos.isEmpty ? ModoResultado.decimal : _modos[_modoIdx];

  double _tamanoNivel(int nivel) => _tamanos[nivel.clamp(0, _tamanos.length - 1)];

  // ---------------------------------------------------------------- acciones

  /// Aplica un cambio al editor. Si venimos de "=", empieza una cuenta nueva
  /// (con Ans al inicio si la tecla es un operador).
  void _aplicar(void Function() cambio, {bool operador = false}) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_trasResultado) {
        _trasResultado = false;
        _editor.limpiar();
        if (operador) _editor.insertarSimbolo('Ans');
      }
      _valor = null;
      _error = null;
      cambio();
    });
  }

  void _insertar(String texto, {bool operador = false}) {
    _aplicar(() => _editor.insertarSimbolo(texto), operador: operador);
  }

  void _borrar() {
    HapticFeedback.selectionClick();
    setState(() {
      _trasResultado = false;
      _valor = null;
      _error = null;
      _editor.borrar();
    });
  }

  void _limpiarTodo() {
    HapticFeedback.selectionClick();
    setState(() {
      _editor.limpiar();
      _valor = null;
      _error = null;
      _trasResultado = false;
    });
  }

  void _mover(int direccion) {
    HapticFeedback.selectionClick();
    setState(() {
      _trasResultado = false;
      _editor.mover(direccion);
    });
  }

  void _tocarRanura(Ranura ranura) {
    setState(() {
      _trasResultado = false;
      _editor.irAlFinalDe(ranura);
    });
  }

  void _evaluar() {
    if (_editor.vacio) return;
    final texto = _editor.aTexto();
    HapticFeedback.mediumImpact();
    try {
      final v = MotorCalculadora.evaluar(texto, ans: _ans, grados: _grados);
      final modos = modosDisponibles(v);
      setState(() {
        _valor = v;
        _ans = v;
        _error = null;
        _modos = modos;
        _modoIdx = modos.indexOf(modoInicial(v));
        _trasResultado = true;
      });
    } on ErrorCalculadora catch (e) {
      setState(() {
        _valor = null;
        _error = e.mensaje;
        _trasResultado = false;
      });
    } catch (_) {
      setState(() {
        _valor = null;
        _error = 'Error matemático';
        _trasResultado = false;
      });
    }
  }

  void _cambiarModo() {
    if (_modos.length < 2) return;
    HapticFeedback.selectionClick();
    setState(() => _modoIdx = (_modoIdx + 1) % _modos.length);
  }

  void _alternarAngulo() {
    HapticFeedback.selectionClick();
    setState(() => _grados = !_grados);
  }

  void _usarEnChat() {
    final v = _valor;
    if (v == null) return;
    widget.alUsarResultado?.call(formatear(v, _modo).plano);
  }

  // ------------------------------------------------------------------ vista

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        _construirPantalla(cs),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
            child: _construirTeclado(cs),
          ),
        ),
      ],
    );
  }

  Widget _construirPantalla(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(
                'Calculadora científica',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              InkWell(
                onTap: _alternarAngulo,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _grados ? 'DEG' : 'RAD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 92, child: _construirExpresion(cs)),
          SizedBox(
            height: 76,
            child: Align(
              alignment: Alignment.centerRight,
              child: _construirResultado(cs),
            ),
          ),
          SizedBox(height: 34, child: _construirBarraInferior(cs)),
        ],
      ),
    );
  }

  // ------------------------------------------------- pantalla de expresión

  Widget _construirExpresion(ColorScheme cs) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contexto = _claveCursor.currentContext;
      if (mounted && contexto != null) {
        Scrollable.ensureVisible(
          contexto,
          alignment: 0.5,
          duration: const Duration(milliseconds: 80),
        );
      }
    });

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tocarRanura(_editor.raiz),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _construirRanura(_editor.raiz, 0, cs),
        ),
      ),
    );
  }

  /// Dibuja una cajita: sus nodos y, si el cursor está ahí, el cursor.
  Widget _construirRanura(Ranura r, int nivel, ColorScheme cs) {
    final tam = _tamanoNivel(nivel);
    final activa = identical(r, _editor.actual);
    final esRaiz = identical(r, _editor.raiz);

    final hijos = <Widget>[];
    for (var i = 0; i <= r.nodos.length; i++) {
      if (activa && i == _editor.pos) {
        hijos.add(_Cursor(key: _claveCursor, alto: tam * 1.25, color: cs.primary));
      }
      if (i < r.nodos.length) {
        hijos.add(_construirNodo(r.nodos[i], nivel, cs));
      }
    }

    if (esRaiz) {
      if (r.vacia) {
        hijos.add(Text('0', style: TextStyle(fontSize: tam, color: cs.outline)));
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: hijos,
      );
    }

    final contenido = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: hijos,
    );

    // Cajita vacía: se dibuja el recuadro (□) para que se vea dónde escribir.
    if (r.vacia) {
      return GestureDetector(
        onTap: () => _tocarRanura(r),
        child: Container(
          constraints: BoxConstraints(minWidth: tam * 0.75, minHeight: tam * 1.25),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: activa ? cs.primary : cs.outline,
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: contenido,
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _tocarRanura(r),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: contenido,
      ),
    );
  }

  Widget _construirNodo(Nodo n, int nivel, ColorScheme cs) {
    final tam = _tamanoNivel(nivel);
    final estilo = TextStyle(
      fontSize: tam,
      fontWeight: FontWeight.w500,
      color: cs.onSurface,
    );
    final sub = nivel + 1;

    if (n is Simbolo) return Text(n.texto, style: estilo);

    if (n is NodoFraccion) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _construirRanura(n.numerador, sub, cs)),
              Container(
                height: 1.6,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: cs.onSurface,
              ),
              Center(child: _construirRanura(n.denominador, sub, cs)),
            ],
          ),
        ),
      );
    }

    if (n is NodoPotencia) {
      // Exponente arriba: una caja pequeña con un espacio debajo la sube.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _construirRanura(n.exponente, sub, cs),
          SizedBox(height: tam * 0.6),
        ],
      );
    }

    if (n is NodoPotenciaCaja) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _construirRanura(n.base, nivel, cs),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _construirRanura(n.exponente, sub, cs),
              SizedBox(height: tam * 0.6),
            ],
          ),
        ],
      );
    }

    if (n is NodoRaizCuadrada) {
      return _dibujarRaiz(null, n.radicando, nivel, cs);
    }

    if (n is NodoRaizN) {
      return _dibujarRaiz(n.indice, n.radicando, nivel, cs);
    }

    if (n is NodoLogBase) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('log', style: estilo),
          // Base abajo, como subíndice.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: tam * 0.6),
              _construirRanura(n.base, sub, cs),
            ],
          ),
          Text('(', style: estilo),
          _construirRanura(n.argumento, nivel, cs),
          Text(')', style: estilo),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _dibujarRaiz(Ranura? indice, Ranura radicando, int nivel, ColorScheme cs) {
    final tam = _tamanoNivel(nivel);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (indice != null)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _construirRanura(indice, nivel + 1, cs),
              SizedBox(height: tam * 0.55),
            ],
          ),
        _Radical(
          tam: tam,
          color: cs.onSurface,
          hijo: _construirRanura(radicando, nivel, cs),
        ),
      ],
    );
  }

  // -------------------------------------------------------------- resultado

  Widget _construirResultado(ColorScheme cs) {
    final mensaje = _error;
    if (mensaje != null) {
      return Text(
        mensaje,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: cs.error,
        ),
      );
    }
    final v = _valor;
    if (v == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: _VistaResultado(presentacion: formatear(v, _modo), color: cs.onSurface),
    );
  }

  Widget _construirBarraInferior(ColorScheme cs) {
    final v = _valor;
    if (v == null) return const SizedBox.shrink();

    final mostrarAproximado = v.esExacto && !v.esEntero && _modo != ModoResultado.decimal;
    final aproximado =
    mostrarAproximado ? '≈ ${formatear(v, ModoResultado.decimal).plano}' : '';

    return Row(
      children: [
        Expanded(
          child: Text(
            aproximado,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ),
        if (widget.alUsarResultado != null)
          FilledButton.tonal(
            onPressed: _usarEnChat,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Usar en el chat'),
          ),
      ],
    );
  }

  // ----------------------------------------------------------------- teclado

  /// Tecla que escribe un texto simple (sin cajitas).
  VoidCallback _ins(String texto, {bool op = false}) {
    return () => _insertar(texto, operador: op);
  }

  /// Tecla que crea una estructura con cajitas (fracción, raíz, log, potencia).
  VoidCallback _est(void Function(EditorExpresion e) accion, {bool op = false}) {
    return () => _aplicar(() => accion(_editor), operador: op);
  }

  Widget _tecla(
      String etiqueta,
      _EstiloTecla estilo,
      VoidCallback alTocar, {
        Widget? contenido,
      }) {
    return _Tecla(
      etiqueta: etiqueta,
      estilo: estilo,
      alTocar: alTocar,
      contenido: contenido,
    );
  }

  Widget _fila(int peso, List<Widget> teclas) {
    return Expanded(
      flex: peso,
      child: Row(
        children: [
          for (final t in teclas) Expanded(child: t),
        ],
      ),
    );
  }

  Widget _construirTeclado(ColorScheme cs) {
    final funcion = _EstiloTecla(cs.surfaceContainerHigh, cs.onSurface, 15, false);
    final numero = _EstiloTecla(cs.surfaceContainerHighest, cs.onSurface, 22, true);
    final operador =
    _EstiloTecla(cs.secondaryContainer, cs.onSecondaryContainer, 22, false);
    final borrar = _EstiloTecla(cs.errorContainer, cs.onErrorContainer, 17, true);
    final igual = _EstiloTecla(cs.primary, cs.onPrimary, 24, true);

    // Color de los íconos con cajitas (el mismo del texto de cada tipo de tecla).
    final cFuncion = cs.onSurface;
    final cOperador = cs.onSecondaryContainer;

    return Column(
      children: [
        // ---- Funciones (mismo orden que la Casio)
        _fila(4, [
          _tecla('Abs', funcion, _ins('abs(')),
          _tecla('x³', funcion, _est((e) => e.insertarPotenciaFija('3'), op: true)),
          _tecla('◀', funcion, () => _mover(-1)),
          _tecla('▶', funcion, () => _mover(1)),
          _tecla('x⁻¹', funcion, _est((e) => e.insertarPotenciaFija('−1'), op: true)),
          _tecla('logₐ', funcion, _est((e) => e.insertarLogBase()),
              contenido: _iconoLogBase(cFuncion)),
        ]),
        _fila(4, [
          _tecla('a/b', operador, _est((e) => e.insertarFraccion(), op: true),
              contenido: _iconoFraccion(cOperador)),
          _tecla('√', funcion, _est((e) => e.insertarRaizCuadrada()),
              contenido: _iconoRaizCuadrada(cFuncion)),
          _tecla('x²', funcion, _est((e) => e.insertarPotenciaFija('2'), op: true)),
          _tecla('x^□', funcion, _est((e) => e.insertarPotencia(), op: true),
              contenido: _iconoPotencia(cFuncion)),
          _tecla('log', funcion, _ins('log(')),
          _tecla('ln', funcion, _ins('ln(')),
        ]),
        _fila(4, [
          _tecla('ⁿ√x', funcion, _est((e) => e.insertarRaizN()),
              contenido: _iconoRaizN(cFuncion)),
          _tecla('(', operador, _ins('(')),
          _tecla(')', operador, _ins(')')),
          _tecla('sin', funcion, _ins('sin(')),
          _tecla('cos', funcion, _ins('cos(')),
          _tecla('tan', funcion, _ins('tan(')),
        ]),
        _fila(4, [
          _tecla('π', funcion, _ins('π')),
          _tecla('e', funcion, _ins('e')),
          _tecla('S⇔D', funcion, _cambiarModo),
          _tecla('sin⁻¹', funcion, _ins('sin⁻¹(')),
          _tecla('cos⁻¹', funcion, _ins('cos⁻¹(')),
          _tecla('tan⁻¹', funcion, _ins('tan⁻¹(')),
        ]),
        _fila(4, [
          _tecla('(−)', funcion, _ins('−')),
          _tecla('n!', funcion, _ins('!', op: true)),
          _tecla('%', funcion, _ins('%', op: true)),
          _tecla('nPr', funcion, _ins('P', op: true)),
          _tecla('nCr', funcion, _ins('C', op: true)),
        ]),
        const SizedBox(height: 4),

        // ---- Teclado principal
        _fila(5, [
          _tecla('7', numero, _ins('7')),
          _tecla('8', numero, _ins('8')),
          _tecla('9', numero, _ins('9')),
          _tecla('DEL', borrar, _borrar),
          _tecla('AC', borrar, _limpiarTodo),
        ]),
        _fila(5, [
          _tecla('4', numero, _ins('4')),
          _tecla('5', numero, _ins('5')),
          _tecla('6', numero, _ins('6')),
          _tecla('×', operador, _ins('×', op: true)),
          _tecla('÷', operador, _ins('÷', op: true)),
        ]),
        _fila(5, [
          _tecla('1', numero, _ins('1')),
          _tecla('2', numero, _ins('2')),
          _tecla('3', numero, _ins('3')),
          _tecla('+', operador, _ins('+', op: true)),
          _tecla('−', operador, _ins('−', op: true)),
        ]),
        _fila(5, [
          _tecla('0', numero, _ins('0')),
          _tecla('.', numero, _ins('.')),
          _tecla('×10ˣ', funcion, _est((e) => e.insertarPorDiezA(), op: true)),
          _tecla('Ans', funcion, _ins('Ans')),
          _tecla('=', igual, _evaluar),
        ]),
      ],
    );
  }
}

// ===========================================================================
// Widgets de apoyo
// ===========================================================================

/// Cursor parpadeante.
class _Cursor extends StatefulWidget {
  const _Cursor({super.key, required this.alto, required this.color});

  final double alto;
  final Color color;

  @override
  State<_Cursor> createState() => _CursorState();
}

class _CursorState extends State<_Cursor> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 530),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.1, end: 1).animate(_anim),
      child: Container(
        width: 2,
        height: widget.alto,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

/// Radical dibujado de un solo trazo: gancho, bajada, subida y línea superior.
/// El tamaño se ajusta solo al contenido que lleva adentro.
class _Radical extends StatelessWidget {
  const _Radical({required this.hijo, required this.color, required this.tam});

  final Widget hijo;
  final Color color;
  final double tam;

  @override
  Widget build(BuildContext context) {
    final anchoSigno = tam * 0.7;
    return CustomPaint(
      painter: _PintorRadical(color: color, anchoSigno: anchoSigno),
      child: Padding(
        padding: EdgeInsets.fromLTRB(anchoSigno + 2, 5, 4, 1),
        child: hijo,
      ),
    );
  }
}

class _PintorRadical extends CustomPainter {
  const _PintorRadical({required this.color, required this.anchoSigno});

  final Color color;
  final double anchoSigno;

  static const double _grosor = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    final a = anchoSigno;
    final w = size.width;
    final h = size.height;
    const arriba = _grosor / 2 + 0.5;
    final abajo = h - _grosor / 2;

    final trazo = Path()
      ..moveTo(0, h * 0.58) // inicio del gancho
      ..lineTo(a * 0.28, h * 0.50) // gancho
      ..lineTo(a * 0.55, abajo) // bajada hasta el vértice
      ..lineTo(a, arriba) // subida larga
      ..lineTo(w, arriba); // línea sobre el radicando

    final pincel = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _grosor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(trazo, pincel);
  }

  @override
  bool shouldRepaint(_PintorRadical viejo) =>
      viejo.color != color || viejo.anchoSigno != anchoSigno;
}

class _EstiloTecla {
  const _EstiloTecla(this.fondo, this.texto, this.tamano, this.negrita);

  final Color fondo;
  final Color texto;
  final double tamano;
  final bool negrita;
}

class _Tecla extends StatelessWidget {
  const _Tecla({
    required this.etiqueta,
    required this.estilo,
    required this.alTocar,
    this.contenido,
  });

  final String etiqueta;
  final _EstiloTecla estilo;
  final VoidCallback alTocar;

  /// Si se da, se dibuja en lugar del texto (íconos con cajitas).
  final Widget? contenido;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.5),
      child: Material(
        color: estilo.fondo,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          canRequestFocus: false,
          onTap: alTocar,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: contenido ??
                    Text(
                      etiqueta,
                      style: TextStyle(
                        fontSize: estilo.tamano,
                        color: estilo.texto,
                        fontWeight:
                        estilo.negrita ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Muestra el resultado: número normal, o fracción con la barra en medio
/// (y con la parte entera a la izquierda si es un número mixto).
class _VistaResultado extends StatelessWidget {
  const _VistaResultado({required this.presentacion, required this.color});

  final Presentacion presentacion;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = presentacion;
    final grande = TextStyle(fontSize: 30, fontWeight: FontWeight.w500, color: color);

    if (!p.esFraccion) {
      final signo = p.negativo ? '−' : '';
      return Text('$signo${p.numerador}', style: grande);
    }

    final chico = TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (p.negativo) Text('−', style: grande),
        if (p.entero != null)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(p.entero!, style: grande),
          ),
        IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(p.numerador, textAlign: TextAlign.center, style: chico),
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: color,
              ),
              Text(p.denominador!, textAlign: TextAlign.center, style: chico),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Íconos de teclas (cajitas como en la Casio)
// ===========================================================================

Widget _caja(Color c, {double lado = 8}) => Container(
  width: lado,
  height: lado,
  decoration: BoxDecoration(
    border: Border.all(color: c, width: 1.3),
    borderRadius: BorderRadius.circular(1.5),
  ),
);

/// Cajita con la rayita de arriba del radical.
Widget _radicando(Color c) => Container(
  margin: const EdgeInsets.only(left: 1),
  padding: const EdgeInsets.only(top: 2),
  decoration: BoxDecoration(
    border: Border(top: BorderSide(color: c, width: 1.3)),
  ),
  child: _caja(c),
);

Widget _iconoFraccion(Color c) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    _caja(c),
    Container(
      width: 16,
      height: 1.4,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: c,
    ),
    _caja(c),
  ],
);

Widget _iconoRaizCuadrada(Color c) => Row(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Text('√', style: TextStyle(fontSize: 22, color: c)),
    _radicando(c),
  ],
);

Widget _iconoRaizN(Color c) => Row(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _caja(c, lado: 5),
    ),
    Text('√', style: TextStyle(fontSize: 22, color: c)),
    _radicando(c),
  ],
);

Widget _iconoPotencia(Color c) => Row(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      'x',
      style: TextStyle(fontSize: 22, fontStyle: FontStyle.italic, color: c),
    ),
    Padding(
      padding: const EdgeInsets.only(left: 1, top: 2),
      child: _caja(c, lado: 7),
    ),
  ],
);

Widget _iconoLogBase(Color c) => Row(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Text('log', style: TextStyle(fontSize: 16, color: c)),
    Padding(
      padding: const EdgeInsets.only(top: 9, left: 1),
      child: _caja(c, lado: 5),
    ),
    const SizedBox(width: 2),
    _caja(c),
  ],
);