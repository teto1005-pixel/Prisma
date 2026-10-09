// lib/services/motor_calculadora.dart

// Motor de la calculadora científica de secundaria. No depende de Flutter.

import 'dart:math' as math;

/// Error que se muestra en la pantalla de la calculadora.
class ErrorCalculadora implements Exception {
  const ErrorCalculadora(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

ErrorCalculadora _errorSintaxis() => const ErrorCalculadora('Error de sintaxis');
ErrorCalculadora _errorMatematico() => const ErrorCalculadora('Error matemático');

// ===========================================================================
// Enteros grandes: raíces enteras
// ===========================================================================

/// Raíz cuadrada entera: el mayor r tal que r*r <= n.
BigInt _raizEntera(BigInt n) {
  if (n < BigInt.two) return n;
  var x = BigInt.one << ((n.bitLength + 1) ~/ 2);
  while (true) {
    final y = (x + n ~/ x) >> 1;
    if (y >= x) return x;
    x = y;
  }
}

/// Raíz q-ésima entera: el mayor r tal que r^q <= m.
BigInt _raizEnteraQ(BigInt m, int q) {
  if (m < BigInt.two) return m;
  var bajo = BigInt.zero;
  var alto = BigInt.one << (m.bitLength ~/ q + 1);
  while (bajo < alto) {
    final medio = (bajo + alto + BigInt.one) >> 1;
    if (medio.pow(q) <= m) {
      bajo = medio;
    } else {
      alto = medio - BigInt.one;
    }
  }
  return bajo;
}

/// Descompone r = s² · t con t libre de cuadrados.
/// Ejemplo: 50 = 5² · 2  →  (5, 2).
(BigInt, BigInt) _extraerCuadrados(BigInt r) {
  if (r < BigInt.two) return (BigInt.one, r);

  final q0 = _raizEntera(r);
  if (q0 * q0 == r) return (q0, BigInt.one);

  // Para números muy grandes no se intenta simplificar.
  if (r > BigInt.from(1000000000000000)) return (BigInt.one, r);

  final total = r.toInt();
  var restante = total;
  var s = 1;
  var libre = 1;
  var d = 2;
  while (d * d * d <= total) {
    if (restante % d == 0) {
      var exponente = 0;
      while (restante % d == 0) {
        restante ~/= d;
        exponente++;
      }
      for (var k = 0; k < exponente ~/ 2; k++) {
        s *= d;
      }
      if (exponente.isOdd) libre *= d;
    }
    d++;
  }
  // Lo que queda es primo, producto de dos primos, o un cuadrado perfecto.
  var q = math.sqrt(restante.toDouble()).round();
  while (q * q > restante) {
    q--;
  }
  while ((q + 1) * (q + 1) <= restante) {
    q++;
  }
  if (restante > 1 && q * q == restante) {
    s *= q;
    restante = 1;
  }
  return (BigInt.from(s), BigInt.from(libre * restante));
}

// ===========================================================================
// Fracción exacta
// ===========================================================================

class Fraccion {
  factory Fraccion(BigInt n, [BigInt? d]) {
    var den = d ?? BigInt.one;
    if (den == BigInt.zero) throw _errorMatematico();
    var num = n;
    if (den.isNegative) {
      num = -num;
      den = -den;
    }
    final g = num.gcd(den);
    if (g > BigInt.one) {
      num = num ~/ g;
      den = den ~/ g;
    }
    return Fraccion._(num, den);
  }

  const Fraccion._(this.n, this.d);

  final BigInt n;
  final BigInt d;

  static final Fraccion cero = Fraccion(BigInt.zero);
  static final Fraccion uno = Fraccion(BigInt.one);

  bool get esEntero => d == BigInt.one;
  bool get esCero => n == BigInt.zero;
  bool get esNegativo => n.isNegative;

  Fraccion operator +(Fraccion o) => Fraccion(n * o.d + o.n * d, d * o.d);
  Fraccion operator -(Fraccion o) => Fraccion(n * o.d - o.n * d, d * o.d);
  Fraccion operator *(Fraccion o) => Fraccion(n * o.n, d * o.d);
  Fraccion operator /(Fraccion o) => Fraccion(n * o.d, d * o.n);
  Fraccion operator -() => Fraccion._(-n, d);

  double toDouble() => n.toDouble() / d.toDouble();
}

Fraccion _potenciaFraccion(Fraccion f, int p) {
  if (p >= 0) return Fraccion(f.n.pow(p), f.d.pow(p));
  return Fraccion(f.d.pow(-p), f.n.pow(-p));
}

// ===========================================================================
// Valor: número exacto (fracción × √entero) o decimal aproximado
// ===========================================================================

class Valor {
  const Valor._(this.esExacto, this.coef, this.rad, this._aprox, this.deDecimal);

  /// Número exacto: coef · √rad. El radicando se simplifica solo (√12 → 2√3).
  factory Valor.exacto(Fraccion coef, {BigInt? rad, bool deDecimal = false}) {
    final r = rad ?? BigInt.one;
    if (coef.esCero) {
      return Valor._(true, Fraccion.cero, BigInt.one, 0, deDecimal);
    }
    final (s, t) = _extraerCuadrados(r);
    final c = s == BigInt.one ? coef : coef * Fraccion(s);
    return Valor._(true, c, t, 0, deDecimal);
  }

  factory Valor.entero(int v, {bool deDecimal = false}) =>
      Valor.exacto(Fraccion(BigInt.from(v)), deDecimal: deDecimal);

  /// Decimal aproximado. Limpia el ruido de la computadora (0.30000000000000004)
  /// y, si el resultado es un entero, lo vuelve exacto.
  factory Valor.deDouble(double x, {bool deDecimal = false}) {
    if (x.isNaN || x.isInfinite) throw _errorMatematico();
    var v = x;
    if (v.abs() < 1e-12) {
      v = 0;
    } else {
      v = double.parse(v.toStringAsPrecision(14));
    }
    if (v == v.roundToDouble() && v.abs() < 1e15) {
      return Valor.exacto(Fraccion(BigInt.from(v.round())), deDecimal: deDecimal);
    }
    return Valor._(false, Fraccion.cero, BigInt.one, v, deDecimal);
  }

  /// Decimal sin limpiar (para π y e).
  factory Valor.constante(double x) =>
      Valor._(false, Fraccion.cero, BigInt.one, x, false);

  final bool esExacto;
  final Fraccion coef;
  final BigInt rad;
  final double _aprox;

  /// true si en la expresión se escribió algún decimal (0.5); entonces el
  /// resultado se muestra primero como decimal, como en una calculadora.
  final bool deDecimal;

  double get aDouble =>
      esExacto ? coef.toDouble() * math.sqrt(rad.toDouble()) : _aprox;

  bool get esRacional => esExacto && rad == BigInt.one;
  bool get esEntero => esRacional && coef.esEntero;
  bool get esCero => esExacto ? coef.esCero : _aprox == 0;
  bool get esNegativo => esExacto ? coef.esNegativo : _aprox < 0;

  Valor operator -() {
    if (esExacto) return Valor.exacto(-coef, rad: rad, deDecimal: deDecimal);
    return Valor._(false, coef, rad, -_aprox, deDecimal);
  }

  Valor operator +(Valor o) {
    final dec = deDecimal || o.deDecimal;
    if (esExacto && o.esExacto) {
      if (coef.esCero) return Valor.exacto(o.coef, rad: o.rad, deDecimal: dec);
      if (o.coef.esCero) return Valor.exacto(coef, rad: rad, deDecimal: dec);
      if (rad == o.rad) {
        return Valor.exacto(coef + o.coef, rad: rad, deDecimal: dec);
      }
    }
    return Valor.deDouble(aDouble + o.aDouble, deDecimal: dec);
  }

  Valor operator -(Valor o) => this + (-o);

  Valor operator *(Valor o) {
    final dec = deDecimal || o.deDecimal;
    if (esExacto && o.esExacto) {
      return Valor.exacto(coef * o.coef, rad: rad * o.rad, deDecimal: dec);
    }
    return Valor.deDouble(aDouble * o.aDouble, deDecimal: dec);
  }

  Valor operator /(Valor o) {
    if (o.esCero) throw _errorMatematico();
    final dec = deDecimal || o.deDecimal;
    if (esExacto && o.esExacto) {
      // (a√r1) / (b√r2) = a/(b·r2) · √(r1·r2)
      final divisor = o.coef * Fraccion(o.rad);
      return Valor.exacto(coef / divisor, rad: rad * o.rad, deDecimal: dec);
    }
    return Valor.deDouble(aDouble / o.aDouble, deDecimal: dec);
  }
}

// ===========================================================================
// Funciones matemáticas
// ===========================================================================

Valor _raizCuadrada(Valor a) {
  if (a.esCero) return Valor.entero(0);
  if (a.esNegativo) throw _errorMatematico();
  if (a.esRacional) {
    // √(p/q) = √(p·q) / q
    final p = a.coef.n;
    final q = a.coef.d;
    return Valor.exacto(Fraccion(BigInt.one, q), rad: p * q, deDecimal: a.deDecimal);
  }
  return Valor.deDouble(math.sqrt(a.aDouble), deDecimal: a.deDecimal);
}

Valor _potencia(Valor a, Valor b) {
  final dec = a.deDecimal || b.deDecimal;
  final mil = BigInt.from(1000);

  // Exponente entero.
  if (b.esEntero) {
    if (b.coef.n.abs() <= mil) {
      final k = b.coef.n.toInt();
      if (a.esCero) {
        if (k <= 0) throw _errorMatematico();
        return Valor.entero(0);
      }
      if (a.esExacto) {
        var resultado = Valor.entero(1);
        var base = a;
        var n = k.abs();
        while (n > 0) {
          if (n.isOdd) resultado = resultado * base;
          n >>= 1;
          if (n > 0) base = base * base;
        }
        if (k < 0) resultado = Valor.entero(1) / resultado;
        // 10 elevado a un exponente negativo se muestra como decimal (5×10^(−3) = 0.005).
        final diezNegativo = a.esRacional &&
            a.coef.esEntero &&
            a.coef.n == BigInt.from(10) &&
            k < 0;
        return Valor.exacto(
          resultado.coef,
          rad: resultado.rad,
          deDecimal: dec || diezNegativo,
        );
      }
      return Valor.deDouble(math.pow(a.aDouble, k).toDouble(), deDecimal: dec);
    }
    return Valor.deDouble(
      math.pow(a.aDouble, b.aDouble).toDouble(),
      deDecimal: dec,
    );
  }

  // Exponente fraccionario (raíces): 8^(1/3), 4^(3/2)...
  if (b.esRacional && a.esRacional && b.coef.d <= BigInt.from(64)) {
    final p = b.coef.n;
    final q = b.coef.d.toInt();
    final f = a.coef;
    if (f.esNegativo && q.isEven) throw _errorMatematico();
    if (f.esCero) {
      if (p.isNegative) throw _errorMatematico();
      return Valor.entero(0);
    }
    final negativo = f.esNegativo;
    final n = f.n.abs();
    final d = f.d;
    final rn = _raizEnteraQ(n, q);
    final rd = _raizEnteraQ(d, q);
    if (rn.pow(q) == n && rd.pow(q) == d && p.abs() <= mil) {
      var r = _potenciaFraccion(Fraccion(rn, rd), p.toInt());
      if (negativo && p.isOdd) r = -r;
      return Valor.exacto(r, deDecimal: dec);
    }
    var r = math.pow(f.toDouble().abs(), b.coef.toDouble()).toDouble();
    if (negativo && p.isOdd) r = -r;
    return Valor.deDouble(r, deDecimal: dec);
  }

  // Cualquier otro caso: aproximado.
  final x = a.aDouble;
  final y = b.aDouble;
  if (x < 0) throw _errorMatematico();
  if (x == 0 && y <= 0) throw _errorMatematico();
  return Valor.deDouble(math.pow(x, y).toDouble(), deDecimal: dec);
}

/// Raíz enésima: n ˣ√ x.
Valor _raiz(Valor n, Valor x) {
  if (!n.esEntero || n.coef.n < BigInt.one) throw _errorMatematico();
  if (n.coef.n == BigInt.two) return _raizCuadrada(x);
  return _potencia(x, Valor.entero(1) / n);
}

int _enteroNoNegativo(Valor v, {int tope = 200}) {
  if (!v.esEntero || v.coef.esNegativo || v.coef.n > BigInt.from(tope)) {
    throw _errorMatematico();
  }
  return v.coef.n.toInt();
}

Valor _factorial(Valor v) {
  final n = _enteroNoNegativo(v);
  var r = BigInt.one;
  for (var i = 2; i <= n; i++) {
    r *= BigInt.from(i);
  }
  return Valor.exacto(Fraccion(r));
}

BigInt _productoDescendente(int n, int r) {
  var p = BigInt.one;
  for (var i = 0; i < r; i++) {
    p *= BigInt.from(n - i);
  }
  return p;
}

Valor _permutaciones(Valor a, Valor b) {
  final n = _enteroNoNegativo(a);
  final r = _enteroNoNegativo(b);
  if (r > n) throw _errorMatematico();
  return Valor.exacto(Fraccion(_productoDescendente(n, r)));
}

Valor _combinaciones(Valor a, Valor b) {
  final n = _enteroNoNegativo(a);
  final r = _enteroNoNegativo(b);
  if (r > n) throw _errorMatematico();
  var factorialR = BigInt.one;
  for (var i = 2; i <= r; i++) {
    factorialR *= BigInt.from(i);
  }
  return Valor.exacto(Fraccion(_productoDescendente(n, r) ~/ factorialR));
}

// ---- Trigonometría -------------------------------------------------------

Valor? _senoTabla(int grados) {
  final mitad = Fraccion(BigInt.one, BigInt.two);
  if (grados == 0) return Valor.entero(0);
  if (grados == 30) return Valor.exacto(mitad);
  if (grados == 45) return Valor.exacto(mitad, rad: BigInt.two);
  if (grados == 60) return Valor.exacto(mitad, rad: BigInt.from(3));
  if (grados == 90) return Valor.entero(1);
  return null;
}

/// Valor exacto de sin/cos/tan para ángulos enteros en grados que se reducen
/// a 0°, 30°, 45°, 60° o 90°. Devuelve null si no es uno de esos.
Valor? _trigExacta(String fn, Valor v) {
  if (!v.esEntero) return null;
  final g = (v.coef.n % BigInt.from(360)).toInt();
  int r;
  int signoSeno;
  int signoCoseno;
  if (g <= 90) {
    r = g;
    signoSeno = 1;
    signoCoseno = 1;
  } else if (g <= 180) {
    r = 180 - g;
    signoSeno = 1;
    signoCoseno = -1;
  } else if (g <= 270) {
    r = g - 180;
    signoSeno = -1;
    signoCoseno = -1;
  } else {
    r = 360 - g;
    signoSeno = -1;
    signoCoseno = 1;
  }
  final tablaSeno = _senoTabla(r);
  final tablaCoseno = _senoTabla(90 - r);
  if (tablaSeno == null || tablaCoseno == null) return null;
  final s = signoSeno == 1 ? tablaSeno : -tablaSeno;
  final c = signoCoseno == 1 ? tablaCoseno : -tablaCoseno;
  if (fn == 'sin') return s;
  if (fn == 'cos') return c;
  if (c.esCero) throw _errorMatematico();
  return s / c;
}

Valor _trig(String fn, Valor v, bool grados) {
  if (grados) {
    final exacto = _trigExacta(fn, v);
    if (exacto != null) return exacto;
  }
  final rad = grados ? v.aDouble * math.pi / 180 : v.aDouble;
  if (fn == 'sin') return Valor.deDouble(math.sin(rad));
  if (fn == 'cos') return Valor.deDouble(math.cos(rad));
  if (math.cos(rad).abs() < 1e-12) throw _errorMatematico();
  return Valor.deDouble(math.tan(rad));
}

Valor _trigInversa(String fn, Valor v, bool grados) {
  final x = v.aDouble;
  double r;
  if (fn == 'asin') {
    if (x.abs() > 1) throw _errorMatematico();
    r = math.asin(x);
  } else if (fn == 'acos') {
    if (x.abs() > 1) throw _errorMatematico();
    r = math.acos(x);
  } else {
    r = math.atan(x);
  }
  return Valor.deDouble(grados ? r * 180 / math.pi : r);
}

// ===========================================================================
// Tokenizador
// ===========================================================================

enum _T { num, op, fn, constante, lp, rp, coma }

class _Token {
  const _Token(this.tipo, [this.texto = '', this.valor]);

  final _T tipo;
  final String texto;
  final Valor? valor;
}

bool _esDigito(String c) {
  final u = c.codeUnitAt(0);
  return u >= 48 && u <= 57;
}

Valor _valorDeLiteral(String lit) {
  final punto = lit.indexOf('.');
  if (punto < 0) return Valor.exacto(Fraccion(BigInt.parse(lit)));
  final entera = lit.substring(0, punto);
  final decimales = lit.substring(punto + 1);
  final digitos = (entera.isEmpty ? '0' : entera) + decimales;
  final numerador = BigInt.parse(digitos);
  final denominador = BigInt.from(10).pow(decimales.length);
  return Valor.exacto(Fraccion(numerador, denominador), deDecimal: true);
}

List<_Token> _tokenizar(String s) {
  const nombres = ['logb', 'sin', 'cos', 'tan', 'log', 'abs', 'Ans', 'ln', 'e'];
  final tokens = <_Token>[];
  var i = 0;

  while (i < s.length) {
    final c = s[i];

    if (c == ' ') {
      i++;
      continue;
    }

    if (_esDigito(c) || c == '.') {
      var j = i;
      while (j < s.length && (_esDigito(s[j]) || s[j] == '.')) {
        j++;
      }
      final lit = s.substring(i, j);
      if ('.'.allMatches(lit).length > 1 || lit == '.') throw _errorSintaxis();
      tokens.add(_Token(_T.num, lit, _valorDeLiteral(lit)));
      i = j;
      continue;
    }

    if (c == '+') {
      tokens.add(const _Token(_T.op, '+'));
    } else if (c == '−' || c == '-') {
      tokens.add(const _Token(_T.op, '-'));
    } else if (c == '×' || c == '*') {
      tokens.add(const _Token(_T.op, '*'));
    } else if (c == '÷') {
      tokens.add(const _Token(_T.op, '÷'));
    } else if (c == '/') {
      tokens.add(const _Token(_T.op, '/'));
    } else if (c == '^') {
      tokens.add(const _Token(_T.op, '^'));
    } else if (c == 'ˣ' && i + 1 < s.length && s[i + 1] == '√') {
      tokens.add(const _Token(_T.op, 'raiz'));
      i++;
    } else if (c == '√') {
      tokens.add(const _Token(_T.fn, 'sqrt'));
    } else if (c == '∛') {
      tokens.add(const _Token(_T.fn, 'cbrt'));
    } else if (c == '!' || c == '%' || c == 'P' || c == 'C') {
      tokens.add(_Token(_T.op, c));
    } else if (c == '(') {
      tokens.add(const _Token(_T.lp));
    } else if (c == ')') {
      tokens.add(const _Token(_T.rp));
    } else if (c == ',') {
      tokens.add(const _Token(_T.coma));
    } else if (c == 'π') {
      tokens.add(const _Token(_T.constante, 'pi'));
    } else {
      var encontrado = false;
      for (final nombre in nombres) {
        if (s.startsWith(nombre, i)) {
          i += nombre.length;
          if (nombre == 'e') {
            tokens.add(const _Token(_T.constante, 'e'));
          } else if (nombre == 'Ans') {
            tokens.add(const _Token(_T.constante, 'ans'));
          } else {
            var fn = nombre;
            final esTrig = nombre == 'sin' || nombre == 'cos' || nombre == 'tan';
            if (esTrig && s.startsWith('⁻¹', i)) {
              i += 2;
              fn = 'a$nombre';
            }
            tokens.add(_Token(_T.fn, fn));
          }
          encontrado = true;
          break;
        }
      }
      if (!encontrado) throw _errorSintaxis();
      continue;
    }
    i++;
  }
  return tokens;
}

// ===========================================================================
// Analizador (de menor a mayor prioridad):
//   suma/resta  <  × ÷ (y multiplicación implícita)  <  P C
//   <  signo  <  barra de fracción /  <  ^ y ˣ√  <  ! %  <  paréntesis, funciones
// ===========================================================================

class _Analizador {
  _Analizador(this._t, this._ans, this._grados);

  final List<_Token> _t;
  final Valor? _ans;
  final bool _grados;
  int _i = 0;

  _Token? get _actual => _i < _t.length ? _t[_i] : null;
  bool get terminado => _i >= _t.length;

  bool _esOp(String a, [String? b]) {
    final t = _actual;
    if (t == null || t.tipo != _T.op) return false;
    return t.texto == a || t.texto == b;
  }

  bool _iniciaFactor() {
    final t = _actual;
    if (t == null) return false;
    return t.tipo == _T.num ||
        t.tipo == _T.constante ||
        t.tipo == _T.lp ||
        t.tipo == _T.fn;
  }

  Valor expresion() {
    var v = _termino();
    while (_esOp('+', '-')) {
      final op = _t[_i].texto;
      _i++;
      final r = _termino();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  Valor _termino() {
    var v = _combinatoria();
    while (true) {
      if (_esOp('*')) {
        _i++;
        v = v * _combinatoria();
      } else if (_esOp('÷')) {
        _i++;
        v = v / _combinatoria();
      } else if (_iniciaFactor()) {
        v = v * _combinatoria(); // multiplicación implícita: 2π, 3(4+5), 2√3
      } else {
        break;
      }
    }
    return v;
  }

  Valor _combinatoria() {
    var v = _signo();
    while (_esOp('P', 'C')) {
      final op = _t[_i].texto;
      _i++;
      final r = _signo();
      v = op == 'P' ? _permutaciones(v, r) : _combinaciones(v, r);
    }
    return v;
  }

  Valor _signo() {
    if (_esOp('+')) {
      _i++;
      return _signo();
    }
    if (_esOp('-')) {
      _i++;
      return -_signo();
    }
    return _fraccion();
  }

  Valor _fraccion() {
    var v = _potencia();
    while (_esOp('/')) {
      _i++;
      v = v / _signoPotencia();
    }
    return v;
  }

  Valor _signoPotencia() {
    if (_esOp('+')) {
      _i++;
      return _signoPotencia();
    }
    if (_esOp('-')) {
      _i++;
      return -_signoPotencia();
    }
    return _potencia();
  }

  Valor _potencia() {
    final base = _postfijo();
    if (_esOp('^')) {
      _i++;
      return _potenciaValor(base, _signoPotencia());
    }
    if (_esOp('raiz')) {
      _i++;
      return _raiz(base, _signoPotencia());
    }
    return base;
  }

  Valor _potenciaValor(Valor base, Valor exponente) => _potencia2(base, exponente);

  Valor _postfijo() {
    var v = _primario();
    while (_esOp('!', '%')) {
      final op = _t[_i].texto;
      _i++;
      v = op == '!' ? _factorial(v) : v / Valor.entero(100);
    }
    return v;
  }

  Valor _primario() {
    final t = _actual;
    if (t == null) throw _errorSintaxis();
    _i++;
    if (t.tipo == _T.num) return t.valor!;
    if (t.tipo == _T.constante) {
      if (t.texto == 'pi') return Valor.constante(math.pi);
      if (t.texto == 'e') return Valor.constante(math.e);
      return _ans ?? Valor.entero(0);
    }
    if (t.tipo == _T.lp) {
      final v = expresion();
      if (_actual?.tipo != _T.rp) throw _errorSintaxis();
      _i++;
      return v;
    }
    if (t.tipo == _T.fn) return _funcion(t.texto);
    throw _errorSintaxis();
  }

  Valor _funcion(String f) {
    Valor a;
    Valor? b;
    if (_actual?.tipo == _T.lp) {
      _i++;
      a = expresion();
      if (f == 'logb') {
        if (_actual?.tipo != _T.coma) throw _errorSintaxis();
        _i++;
        b = expresion();
      } else if (_actual?.tipo == _T.coma) {
        throw _errorSintaxis();
      }
      if (_actual?.tipo != _T.rp) throw _errorSintaxis();
      _i++;
    } else {
      if (f == 'logb') throw _errorSintaxis();
      a = _postfijo(); // √9, sin30: sin paréntesis
    }
    return _aplicar(f, a, b);
  }

  Valor _aplicar(String f, Valor a, Valor? b) {
    if (f == 'sqrt') return _raizCuadrada(a);
    if (f == 'cbrt') return _raiz(Valor.entero(3), a);
    if (f == 'sin' || f == 'cos' || f == 'tan') return _trig(f, a, _grados);
    if (f == 'asin' || f == 'acos' || f == 'atan') {
      return _trigInversa(f, a, _grados);
    }
    if (f == 'abs') return a.esNegativo ? -a : a;
    if (f == 'ln') {
      if (a.aDouble <= 0) throw _errorMatematico();
      return Valor.deDouble(math.log(a.aDouble));
    }
    if (f == 'log') {
      if (a.aDouble <= 0) throw _errorMatematico();
      return Valor.deDouble(math.log(a.aDouble) / math.ln10);
    }
    if (f == 'logb' && b != null) {
      final base = a.aDouble;
      final x = b.aDouble;
      if (base <= 0 || base == 1 || x <= 0) throw _errorMatematico();
      return Valor.deDouble(math.log(x) / math.log(base));
    }
    throw _errorSintaxis();
  }
}

/// Punto de entrada: evalúa una expresión escrita con las teclas de la calculadora.
class MotorCalculadora {
  const MotorCalculadora._();

  /// [ans] es el resultado anterior (tecla Ans). [grados] elige entre grados
  /// (true) y radianes (false) para la trigonometría.
  /// Lanza [ErrorCalculadora] si la expresión no es válida.
  static Valor evaluar(String expresion, {Valor? ans, bool grados = true}) {
    final tokens = _tokenizar(expresion);

    // Cierra solos los paréntesis que quedaron abiertos: 2×(3+4  →  2×(3+4).
    var abiertos = 0;
    for (final t in tokens) {
      if (t.tipo == _T.lp) abiertos++;
      if (t.tipo == _T.rp) abiertos--;
    }
    if (abiertos < 0) throw _errorSintaxis();
    for (var k = 0; k < abiertos; k++) {
      tokens.add(const _Token(_T.rp));
    }
    if (tokens.isEmpty) throw _errorSintaxis();

    final analizador = _Analizador(tokens, ans, grados);
    final v = analizador.expresion();
    if (!analizador.terminado) throw _errorSintaxis();
    return v;
  }
}

// ===========================================================================
// Presentación del resultado
// ===========================================================================

/// Formas de mostrar un resultado.
enum ModoResultado { exacto, mixto, decimal }

class Presentacion {
  const Presentacion({
    required this.negativo,
    required this.numerador,
    this.entero,
    this.denominador,
  });

  final bool negativo;

  /// Parte entera de un número mixto (el 1 de 1 3/4); null si no es mixto.
  final String? entero;
  final String numerador;

  /// null si el resultado no es una fracción.
  final String? denominador;

  bool get esFraccion => denominador != null;

  /// Texto simple para copiar o enviar al chat: "-3/4", "1 3/4", "2√3", "0.75".
  String get plano {
    final signo = negativo ? '-' : '';
    if (denominador == null) return '$signo$numerador';
    if (entero != null) return '$signo$entero $numerador/$denominador';
    return '$signo$numerador/$denominador';
  }
}

/// Entero en texto; si tiene más de 10 cifras usa notación científica.
String _enteroATexto(BigInt n) {
  final digitos = n.abs().toString();
  if (digitos.length <= 10) return digitos;
  var m = '${digitos[0]}.${digitos.substring(1, 10)}';
  m = m.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return '$m×10^${digitos.length - 1}';
}

/// Decimal con 10 cifras significativas, sin ceros sobrantes.
String _decimalATexto(double x) {
  if (x == 0) return '0';
  final a = x.abs();
  if (a >= 1e10 || a < 1e-6) {
    final partes = a.toStringAsExponential(9).split('e');
    var m = partes[0];
    if (m.contains('.')) {
      m = m.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return '$m×10^${int.parse(partes[1])}';
  }
  var s = a.toStringAsPrecision(10);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s;
}

/// Modos entre los que puede alternar la tecla S⇔D para este valor.
List<ModoResultado> modosDisponibles(Valor v) {
  if (!v.esExacto) return [ModoResultado.decimal];
  if (v.esEntero) return [ModoResultado.exacto];
  final modos = <ModoResultado>[ModoResultado.exacto];
  if (v.esRacional && v.coef.n.abs() > v.coef.d) modos.add(ModoResultado.mixto);
  modos.add(ModoResultado.decimal);
  return modos;
}

/// Modo con el que se muestra primero: decimal si se escribieron decimales.
ModoResultado modoInicial(Valor v) {
  final modos = modosDisponibles(v);
  if (v.deDecimal && modos.contains(ModoResultado.decimal)) {
    return ModoResultado.decimal;
  }
  return modos.first;
}

Presentacion formatear(Valor v, ModoResultado modo) {
  if (!v.esExacto || modo == ModoResultado.decimal) {
    final x = v.aDouble;
    return Presentacion(negativo: x < 0, numerador: _decimalATexto(x));
  }

  final n = v.coef.n;
  final d = v.coef.d;
  final negativo = n.isNegative;
  final an = n.abs();

  if (modo == ModoResultado.mixto && v.esRacional && an > d) {
    return Presentacion(
      negativo: negativo,
      entero: (an ~/ d).toString(),
      numerador: (an % d).toString(),
      denominador: d.toString(),
    );
  }

  String numerador;
  if (v.rad == BigInt.one) {
    numerador = _enteroATexto(an);
  } else {
    final coeficiente = an == BigInt.one ? '' : _enteroATexto(an);
    numerador = '$coeficiente√${v.rad}';
  }
  return Presentacion(
    negativo: negativo,
    numerador: numerador,
    denominador: d == BigInt.one ? null : _enteroATexto(d),
  );
}