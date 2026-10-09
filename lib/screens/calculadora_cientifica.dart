// lib/screens/calculadora_cientifica.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/motor_calculadora.dart';

/// Abre la calculadora como una hoja que sube desde abajo.
///
/// Si se pasa [alUsarResultado], aparece el botón "Usar en el chat": cierra la
/// calculadora y entrega el resultado como texto (por ejemplo "3/4" o "2√3").
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
  /// Textos de varias letras que se borran o se saltan de una sola vez.
  static const List<String> _tokensLargos = [
    'sin⁻¹(',
    'cos⁻¹(',
    'tan⁻¹(',
    'logb(',
    'sin(',
    'cos(',
    'tan(',
    'log(',
    'abs(',
    'ln(',
    'Ans',
    'ˣ√',
  ];

  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _foco = FocusNode();

  bool _grados = true;
  Valor? _ans;
  Valor? _valor;
  String? _error;
  List<ModoResultado> _modos = const [];
  int _modoIdx = 0;

  /// true justo después de "=": la siguiente tecla empieza una cuenta nueva
  /// (o continúa con Ans si es un operador).
  bool _trasResultado = false;

  ModoResultado get _modo =>
      _modos.isEmpty ? ModoResultado.decimal : _modos[_modoIdx];

  @override
  void dispose() {
    _ctrl.dispose();
    _foco.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- acciones

  int _longitudAntes(String texto, int pos) {
    for (final t in _tokensLargos) {
      if (pos >= t.length && texto.substring(pos - t.length, pos) == t) {
        return t.length;
      }
    }
    return 1;
  }

  int _longitudDespues(String texto, int pos) {
    for (final t in _tokensLargos) {
      if (pos + t.length <= texto.length &&
          texto.substring(pos, pos + t.length) == t) {
        return t.length;
      }
    }
    return 1;
  }

  void _insertar(String texto, {bool operador = false}) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_trasResultado) {
        _trasResultado = false;
        if (operador) {
          _ctrl.value = const TextEditingValue(
            text: 'Ans',
            selection: TextSelection.collapsed(offset: 3),
          );
        } else {
          _ctrl.value = const TextEditingValue(
            selection: TextSelection.collapsed(offset: 0),
          );
        }
      }
      _valor = null;
      _error = null;

      final actual = _ctrl.text;
      final sel = _ctrl.selection;
      final inicio = sel.isValid ? sel.start : actual.length;
      final fin = sel.isValid ? sel.end : actual.length;
      final nuevo = actual.replaceRange(inicio, fin, texto);
      _ctrl.value = TextEditingValue(
        text: nuevo,
        selection: TextSelection.collapsed(offset: inicio + texto.length),
      );
    });
    _foco.requestFocus();
  }

  void _borrar() {
    HapticFeedback.selectionClick();
    setState(() {
      _trasResultado = false;
      _valor = null;
      _error = null;

      final texto = _ctrl.text;
      final sel = _ctrl.selection;
      if (!sel.isValid) return;
      if (!sel.isCollapsed) {
        _ctrl.value = TextEditingValue(
          text: texto.replaceRange(sel.start, sel.end, ''),
          selection: TextSelection.collapsed(offset: sel.start),
        );
        return;
      }
      if (sel.start == 0) return;
      final inicio = sel.start - _longitudAntes(texto, sel.start);
      _ctrl.value = TextEditingValue(
        text: texto.replaceRange(inicio, sel.start, ''),
        selection: TextSelection.collapsed(offset: inicio),
      );
    });
    _foco.requestFocus();
  }

  void _limpiarTodo() {
    HapticFeedback.selectionClick();
    setState(() {
      _ctrl.value = const TextEditingValue();
      _valor = null;
      _error = null;
      _trasResultado = false;
    });
    _foco.requestFocus();
  }

  void _mover(int direccion) {
    HapticFeedback.selectionClick();
    _trasResultado = false;
    final texto = _ctrl.text;
    final pos = _ctrl.selection.isValid ? _ctrl.selection.baseOffset : texto.length;
    var nueva = pos;
    if (direccion < 0) {
      if (pos > 0) nueva = pos - _longitudAntes(texto, pos);
    } else {
      if (pos < texto.length) nueva = pos + _longitudDespues(texto, pos);
    }
    _ctrl.selection = TextSelection.collapsed(offset: nueva);
    _foco.requestFocus();
  }

  void _evaluar() {
    final texto = _ctrl.text;
    if (texto.trim().isEmpty) return;
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
    _foco.requestFocus();
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
          TextField(
            controller: _ctrl,
            focusNode: _foco,
            autofocus: true,
            readOnly: true,
            showCursor: true,
            keyboardType: TextInputType.none,
            maxLines: 1,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '0',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
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
        if (_modos.length > 1)
          TextButton(
            onPressed: _cambiarModo,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('S⇔D'),
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

  VoidCallback _ins(String texto, {bool op = false}) {
    return () => _insertar(texto, operador: op);
  }

  Widget _tecla(String etiqueta, _EstiloTecla estilo, VoidCallback alTocar) {
    return _Tecla(etiqueta: etiqueta, estilo: estilo, alTocar: alTocar);
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

    return Column(
      children: [
        // ---- Funciones científicas
        _fila(4, [
          _tecla('x²', funcion, _ins('^2', op: true)),
          _tecla('x^y', funcion, _ins('^', op: true)),
          _tecla('√', funcion, _ins('√(')),
          _tecla('ˣ√', funcion, _ins('ˣ√', op: true)),
          _tecla('x⁻¹', funcion, _ins('^(−1)', op: true)),
        ]),
        _fila(4, [
          _tecla('sin', funcion, _ins('sin(')),
          _tecla('cos', funcion, _ins('cos(')),
          _tecla('tan', funcion, _ins('tan(')),
          _tecla('π', funcion, _ins('π')),
          _tecla('e', funcion, _ins('e')),
        ]),
        _fila(4, [
          _tecla('sin⁻¹', funcion, _ins('sin⁻¹(')),
          _tecla('cos⁻¹', funcion, _ins('cos⁻¹(')),
          _tecla('tan⁻¹', funcion, _ins('tan⁻¹(')),
          _tecla('log', funcion, _ins('log(')),
          _tecla('ln', funcion, _ins('ln(')),
        ]),
        _fila(4, [
          _tecla('n!', funcion, _ins('!', op: true)),
          _tecla('nPr', funcion, _ins('P', op: true)),
          _tecla('nCr', funcion, _ins('C', op: true)),
          _tecla('logₐ', funcion, _ins('logb(')),
          _tecla('|x|', funcion, _ins('abs(')),
        ]),
        _fila(4, [
          _tecla(',', funcion, _ins(',')),
          _tecla('%', funcion, _ins('%', op: true)),
          _tecla('x³', funcion, _ins('^3', op: true)),
          _tecla('∛', funcion, _ins('∛(')),
          _tecla(_grados ? 'DEG' : 'RAD', funcion, _alternarAngulo),
        ]),
        const SizedBox(height: 4),

        // ---- Teclado principal
        _fila(5, [
          _tecla('(', operador, _ins('(')),
          _tecla(')', operador, _ins(')')),
          _tecla('a/b', operador, _ins('/', op: true)),
          _tecla('◀', funcion, () => _mover(-1)),
          _tecla('▶', funcion, () => _mover(1)),
        ]),
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
          _tecla('×10ˣ', funcion, _ins('×10^(', op: true)),
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
  });

  final String etiqueta;
  final _EstiloTecla estilo;
  final VoidCallback alTocar;

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
                child: Text(
                  etiqueta,
                  style: TextStyle(
                    fontSize: estilo.tamano,
                    color: estilo.texto,
                    fontWeight: estilo.negrita ? FontWeight.bold : FontWeight.w500,
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