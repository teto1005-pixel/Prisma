// lib/services/editor_expresion.dart
//
// Editor de expresiones en dos dimensiones, al estilo Photomath / Casio:
// fracciones, raíces, logaritmos y potencias con "cajitas" donde se escribe.
// No depende de Flutter. Convierte lo escrito al texto que ya entiende
// MotorCalculadora.evaluar (el motor no necesita cambios).

// ===========================================================================
// Estructura de la expresión
// ===========================================================================

/// Una "cajita": la lista de nodos que hay escritos dentro de ella.
class Ranura {
  final List<Nodo> nodos = [];

  bool get vacia => nodos.isEmpty;
}

abstract class Nodo {
  /// Las cajitas que tiene este nodo (vacío si es una tecla simple).
  List<Ranura> get ranuras;
}

/// Una tecla simple: '7', '+', 'sin(', 'π', 'Ans'... Se borra de una sola vez.
class Simbolo extends Nodo {
  Simbolo(this.texto);

  final String texto;

  @override
  List<Ranura> get ranuras => const [];
}

class NodoFraccion extends Nodo {
  final Ranura numerador = Ranura();
  final Ranura denominador = Ranura();

  @override
  List<Ranura> get ranuras => [numerador, denominador];
}

/// Exponente (la base es lo que está escrito justo antes).
class NodoPotencia extends Nodo {
  final Ranura exponente = Ranura();

  @override
  List<Ranura> get ranuras => [exponente];
}

/// Potencia con la base en su propia cajita: □ⁿ. Se usa cuando antes del
/// cursor no hay nada que sirva de base.
class NodoPotenciaCaja extends Nodo {
  final Ranura base = Ranura();
  final Ranura exponente = Ranura();

  @override
  List<Ranura> get ranuras => [base, exponente];
}

class NodoRaizCuadrada extends Nodo {
  final Ranura radicando = Ranura();

  @override
  List<Ranura> get ranuras => [radicando];
}

/// Raíz n-ésima: índice arriba a la izquierda y radicando debajo del radical.
class NodoRaizN extends Nodo {
  final Ranura indice = Ranura();
  final Ranura radicando = Ranura();

  @override
  List<Ranura> get ranuras => [indice, radicando];
}

/// Logaritmo de base cualquiera: log□(□).
class NodoLogBase extends Nodo {
  final Ranura base = Ranura();
  final Ranura argumento = Ranura();

  @override
  List<Ranura> get ranuras => [base, argumento];
}

// ===========================================================================
// Editor con cursor
// ===========================================================================

class EditorExpresion {
  /// La expresión completa (la cajita de más afuera).
  final Ranura raiz = Ranura();

  /// Camino desde [raiz] hasta la cajita donde está el cursor:
  /// (nodo, número de cajita dentro de ese nodo).
  final List<(Nodo, int)> _ruta = [];

  /// Posición del cursor dentro de [actual].
  int pos = 0;

  /// Cajita donde está el cursor.
  Ranura get actual =>
      _ruta.isEmpty ? raiz : _ruta.last.$1.ranuras[_ruta.last.$2];

  bool get vacio => raiz.vacia;

  void limpiar() {
    raiz.nodos.clear();
    _ruta.clear();
    pos = 0;
  }

  // ------------------------------------------------------------ insertar

  void insertarSimbolo(String texto) {
    actual.nodos.insert(pos, Simbolo(texto));
    pos++;
  }

  /// Inserta [n] y deja el cursor al inicio de su cajita número [ranura].
  void _insertarYEntrar(Nodo n, int ranura) {
    actual.nodos.insert(pos, n);
    _ruta.add((n, ranura));
    pos = 0;
  }

  static final RegExp _parteDeNumero = RegExp(r'^(\d|\.|Ans|π|e)$');

  /// Saca de la cajita actual el número que está justo antes del cursor
  /// (ej. el 3 de "3" + tecla de fracción) para meterlo en la nueva estructura.
  List<Nodo> _tomarPrevio() {
    final lista = actual.nodos;
    var inicio = pos;
    while (inicio > 0) {
      final n = lista[inicio - 1];
      if (n is Simbolo && _parteDeNumero.hasMatch(n.texto)) {
        inicio--;
      } else {
        break;
      }
    }
    final tomados = lista.sublist(inicio, pos);
    lista.removeRange(inicio, pos);
    pos = inicio;
    return tomados;
  }

  /// Fracción con dos cajitas. Si había un número escrito antes, pasa al
  /// numerador y el cursor queda en el denominador.
  void insertarFraccion() {
    final f = NodoFraccion();
    final tomados = _tomarPrevio();
    f.numerador.nodos.addAll(tomados);
    _insertarYEntrar(f, tomados.isEmpty ? 0 : 1);
  }

  /// Raíz n-ésima. Si había un número escrito antes, pasa al índice
  /// (3 + tecla ⁿ√ = raíz cúbica) y el cursor queda en el radicando.
  void insertarRaizN() {
    final r = NodoRaizN();
    final tomados = _tomarPrevio();
    r.indice.nodos.addAll(tomados);
    _insertarYEntrar(r, tomados.isEmpty ? 0 : 1);
  }

  void insertarRaizCuadrada() => _insertarYEntrar(NodoRaizCuadrada(), 0);

  void insertarLogBase() => _insertarYEntrar(NodoLogBase(), 0);

  static final RegExp _terminaBase = RegExp(r'^(\d|\.|\)|π|e|Ans|!|%)$');

  /// true si lo que está justo antes del cursor puede ser la base de una
  /// potencia (un número, un paréntesis que cierra, una fracción, una raíz...).
  bool get _hayBase {
    if (pos == 0) return false;
    final previo = actual.nodos[pos - 1];
    return previo is! Simbolo || _terminaBase.hasMatch(previo.texto);
  }

  /// Potencia: si hay base antes, el cursor entra al exponente; si no, entra
  /// a una cajita para la base.
  void insertarPotencia() {
    if (_hayBase) {
      _insertarYEntrar(NodoPotencia(), 0);
    } else {
      _insertarYEntrar(NodoPotenciaCaja(), 0);
    }
  }

  /// Tecla x²: exponente ya escrito. Si hay base, el cursor queda afuera; si
  /// no, el cursor entra a la cajita de la base.
  void insertarPotenciaFija(String exponente) {
    if (_hayBase) {
      final p = NodoPotencia();
      p.exponente.nodos.add(Simbolo(exponente));
      actual.nodos.insert(pos, p);
      pos++;
    } else {
      final p = NodoPotenciaCaja();
      p.exponente.nodos.add(Simbolo(exponente));
      _insertarYEntrar(p, 0);
    }
  }

  /// Tecla ×10ˣ: escribe ×10 y abre el exponente.
  void insertarPorDiezA() {
    insertarSimbolo('×');
    insertarSimbolo('1');
    insertarSimbolo('0');
    insertarPotencia();
  }

  // ------------------------------------------------------------- cursor

  void mover(int direccion) {
    if (direccion > 0) {
      _derecha();
    } else {
      _izquierda();
    }
  }

  void _derecha() {
    final lista = actual.nodos;
    if (pos < lista.length) {
      final siguiente = lista[pos];
      if (siguiente.ranuras.isNotEmpty) {
        _ruta.add((siguiente, 0));
        pos = 0;
      } else {
        pos++;
      }
      return;
    }
    if (_ruta.isEmpty) return;
    final (dueno, i) = _ruta.last;
    if (i + 1 < dueno.ranuras.length) {
      _ruta[_ruta.length - 1] = (dueno, i + 1);
      pos = 0;
    } else {
      _ruta.removeLast();
      pos = actual.nodos.indexOf(dueno) + 1;
    }
  }

  void _izquierda() {
    final lista = actual.nodos;
    if (pos > 0) {
      final previo = lista[pos - 1];
      if (previo.ranuras.isNotEmpty) {
        _ruta.add((previo, previo.ranuras.length - 1));
        pos = actual.nodos.length;
      } else {
        pos--;
      }
      return;
    }
    if (_ruta.isEmpty) return;
    final (dueno, i) = _ruta.last;
    if (i > 0) {
      _ruta[_ruta.length - 1] = (dueno, i - 1);
      pos = actual.nodos.length;
    } else {
      _ruta.removeLast();
      pos = actual.nodos.indexOf(dueno);
    }
  }

  /// Pone el cursor al final de la cajita [objetivo] (para cuando se toca).
  bool irAlFinalDe(Ranura objetivo) {
    final nueva = <(Nodo, int)>[];
    if (!_buscar(raiz, objetivo, nueva)) return false;
    _ruta
      ..clear()
      ..addAll(nueva);
    pos = objetivo.nodos.length;
    return true;
  }

  bool _buscar(Ranura desde, Ranura objetivo, List<(Nodo, int)> camino) {
    if (identical(desde, objetivo)) return true;
    for (final n in desde.nodos) {
      for (var i = 0; i < n.ranuras.length; i++) {
        camino.add((n, i));
        if (_buscar(n.ranuras[i], objetivo, camino)) return true;
        camino.removeLast();
      }
    }
    return false;
  }

  // -------------------------------------------------------------- borrar

  bool _todasVacias(Nodo n) => n.ranuras.every((r) => r.vacia);

  /// DEL: borra una tecla simple de una vez; una fracción/raíz/log con
  /// contenido primero se "abre" (el cursor entra) y se borra por dentro;
  /// una estructura vacía se borra completa.
  void borrar() {
    if (pos > 0) {
      final previo = actual.nodos[pos - 1];
      if (_todasVacias(previo)) {
        // Incluye a los Simbolo, que no tienen cajitas.
        actual.nodos.removeAt(pos - 1);
        pos--;
      } else {
        _izquierda();
      }
      return;
    }
    if (_ruta.isEmpty) return;
    final (dueno, _) = _ruta.last;
    if (_todasVacias(dueno)) {
      _ruta.removeLast();
      final i = actual.nodos.indexOf(dueno);
      actual.nodos.removeAt(i);
      pos = i;
    } else {
      _izquierda();
    }
  }

  // -------------------------------------------------- texto para el motor

  /// Texto que entiende MotorCalculadora.evaluar. Las cajitas vacías generan
  /// "()" y el motor responde "Error de sintaxis".
  String aTexto() => _ranuraATexto(raiz);

  static String _ranuraATexto(Ranura r) {
    final sb = StringBuffer();
    for (final n in r.nodos) {
      sb.write(_nodoATexto(n));
    }
    return _equilibrar(sb.toString());
  }

  static String _nodoATexto(Nodo n) {
    if (n is Simbolo) return n.texto;
    if (n is NodoFraccion) {
      return '((${_ranuraATexto(n.numerador)})/(${_ranuraATexto(n.denominador)}))';
    }
    if (n is NodoPotencia) return '^(${_ranuraATexto(n.exponente)})';
    if (n is NodoPotenciaCaja) {
      return '((${_ranuraATexto(n.base)})^(${_ranuraATexto(n.exponente)}))';
    }
    if (n is NodoRaizCuadrada) return '√(${_ranuraATexto(n.radicando)})';
    if (n is NodoRaizN) {
      return '((${_ranuraATexto(n.indice)})ˣ√(${_ranuraATexto(n.radicando)}))';
    }
    if (n is NodoLogBase) {
      return 'logb(${_ranuraATexto(n.base)},${_ranuraATexto(n.argumento)})';
    }
    return '';
  }

  /// Cierra los paréntesis abiertos dentro de una cajita para que no se
  /// mezclen con los de afuera. Un ")" sobrante se cambia por '#', que el
  /// tokenizador del motor rechaza como error de sintaxis.
  static String _equilibrar(String s) {
    final sb = StringBuffer();
    var abiertos = 0;
    for (final c in s.split('')) {
      if (c == '(') abiertos++;
      if (c == ')') {
        if (abiertos == 0) {
          sb.write('#');
          continue;
        }
        abiertos--;
      }
      sb.write(c);
    }
    sb.write(')' * abiertos);
    return sb.toString();
  }
}