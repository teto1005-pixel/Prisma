// lib/services/gestor_claves_gemini.dart

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'cliente_gemini.dart';

/// Tipo de falla al llamar a Gemini con una clave.
enum TipoFalla {
  /// Se agotó la cuota de la clave (por minuto o por día).
  cuota,

  /// La clave no existe, expiró o no tiene permiso.
  claveInvalida,

  /// El modelo está saturado (503 "alta demanda", 5xx), tardó demasiado o
  /// cortó la conexión. Es del modelo, no de la clave: se prueba otro modelo.
  servidor,

  /// Error que no se reconoce: se prueba una clave más por si era de esa clave.
  desconocida,

  /// Red, contenido bloqueado, modelo inexistente...: cambiar de clave no ayuda.
  otra,
}

class FallaClave {
  const FallaClave(this.tipo, this.espera);

  final TipoFalla tipo;

  /// Cuánto tiempo conviene no usar la clave después de esta falla.
  final Duration espera;

  /// Si tiene sentido reintentar el mismo mensaje con otra clave.
  bool get rotar =>
      tipo == TipoFalla.cuota ||
          tipo == TipoFalla.claveInvalida ||
          tipo == TipoFalla.servidor ||
          tipo == TipoFalla.desconocida;
}

class _EstadoClave {
  _EstadoClave(this.clave);

  final String clave;
  bool deshabilitada = false;
  DateTime? libreDesde;

  /// Fallos no reconocidos seguidos (se reinicia al tener éxito).
  int fallosSeguidos = 0;
  final List<DateTime> _usos = [];

  void _depurar(DateTime ahora) {
    _usos.removeWhere(
          (u) => ahora.difference(u) >= GestorClavesGemini._ventana,
    );
  }

  bool disponible(DateTime ahora) {
    if (deshabilitada) return false;
    final hasta = libreDesde;
    if (hasta != null && ahora.isBefore(hasta)) return false;
    _depurar(ahora);
    return _usos.length < GestorClavesGemini._maxSolicitudesPorMinuto;
  }

  void registrarUso(DateTime ahora) => _usos.add(ahora);

  Duration esperaRestante(DateTime ahora) {
    if (deshabilitada) return const Duration(days: 365);
    var espera = Duration.zero;
    final hasta = libreDesde;
    if (hasta != null && ahora.isBefore(hasta)) {
      espera = hasta.difference(ahora);
    }
    _depurar(ahora);
    const tope = GestorClavesGemini._maxSolicitudesPorMinuto;
    if (_usos.length >= tope) {
      final liberar = _usos[_usos.length - tope]
          .add(GestorClavesGemini._ventana)
          .difference(ahora);
      if (liberar > espera) espera = liberar;
    }
    return espera;
  }
}

/// Reparte las solicitudes entre varias claves de Gemini priorizando SIEMPRE la clave #1.
///
/// Es un singleton: el estado de cada clave (en pausa, deshabilitada) se
/// comparte entre todas las pantallas de chat mientras la app esté abierta.
class GestorClavesGemini {
  GestorClavesGemini._(List<String> claves)
      : _estados = [for (final c in claves) _EstadoClave(c)] {
    if (kDebugMode) {
      debugPrint('[Gemini] ${_estados.length} clave(s) cargada(s) (Prioridad: Clave #1)');
    }
  }

  static final GestorClavesGemini instancia =
  GestorClavesGemini._(ApiConfig.apiKeys);

  /// Margen prudente para solicitudes por minuto por clave.
  static const int _maxSolicitudesPorMinuto = 14;
  static const Duration _ventana = Duration(minutes: 1);

  /// Cuánto tiempo se evita un modelo después de responder "alta demanda".
  static const Duration _pausaModeloSaturado = Duration(seconds: 15);

  final List<_EstadoClave> _estados;
  final Map<String, DateTime> _modeloLibreDesde = {};

  bool get hayClaves => _estados.isNotEmpty;

  /// Número (desde 1) de una clave, solo para mensajes de depuración.
  int numeroDe(String clave) => _estados.indexWhere((e) => e.clave == clave) + 1;
  int get cantidad => _estados.length;

  /// Devuelve la primera clave disponible en orden estricto de prioridad (Clave 1 primero).
  /// Si está en [excluir] o no disponible, toma la siguiente de respaldo.
  String? tomar({Set<String> excluir = const {}}) {
    final ahora = DateTime.now();
    for (var i = 0; i < _estados.length; i++) {
      final estado = _estados[i];
      if (excluir.contains(estado.clave) || !estado.disponible(ahora)) continue;
      estado.registrarUso(ahora);
      return estado.clave;
    }
    return null;
  }

  /// Elige el modelo a usar: el primero de la lista (principal y luego los de
  /// respaldo) que no esté en [excluir] ni saturado.
  String? elegirModelo({Set<String> excluir = const {}}) {
    final ahora = DateTime.now();
    final candidatos =
    ApiConfig.todosLosModelos.where((m) => !excluir.contains(m)).toList();
    if (candidatos.isEmpty) return null;

    for (final m in candidatos) {
      final hasta = _modeloLibreDesde[m];
      if (hasta == null || !ahora.isBefore(hasta)) return m;
    }
    candidatos.sort(
          (a, b) => _modeloLibreDesde[a]!.compareTo(_modeloLibreDesde[b]!),
    );
    return candidatos.first;
  }

  /// Anota que un modelo respondió "alta demanda": se evita por un rato.
  void marcarModeloSaturado(String modelo, [Duration? pausa]) {
    final espera = pausa ?? _pausaModeloSaturado;
    _modeloLibreDesde[modelo] = DateTime.now().add(espera);
    if (kDebugMode) {
      debugPrint('[Gemini] modelo $modelo saturado: se evita ${espera.inSeconds}s');
    }
  }

  /// Anota la falla de una clave: la pone en pausa o la deshabilita.
  void registrarFalla(String clave, FallaClave falla) {
    final indice = _estados.indexWhere((e) => e.clave == clave);
    if (indice < 0) return;
    final estado = _estados[indice];

    var espera = falla.espera;
    switch (falla.tipo) {
      case TipoFalla.claveInvalida:
        estado.deshabilitada = true;
      case TipoFalla.desconocida:
        estado.fallosSeguidos++;
        espera = falla.espera * (1 << min(estado.fallosSeguidos - 1, 6));
        if (espera > const Duration(minutes: 10)) {
          espera = const Duration(minutes: 10);
        }
        estado.libreDesde = DateTime.now().add(espera);
      case TipoFalla.cuota:
        estado.libreDesde = DateTime.now().add(espera);
      case TipoFalla.servidor:
      case TipoFalla.otra:
        break;
    }

    if (kDebugMode) {
      debugPrint(
        '[Gemini] clave #${indice + 1} de ${_estados.length}: '
            '${falla.tipo.name}, pausa ${espera.inSeconds}s',
      );
    }
  }

  /// Anota que una clave y un modelo respondieron bien.
  void registrarExito(String clave, String modelo) {
    final indice = _estados.indexWhere((e) => e.clave == clave);
    if (indice >= 0) _estados[indice].fallosSeguidos = 0;
    _modeloLibreDesde.remove(modelo);
  }

  /// SOLO PARA DEPURAR: prueba cada clave con una solicitud mínima.
  Future<void> diagnosticar() async {
    if (!kDebugMode) return;
    debugPrint(
      '[Gemini] diagnóstico: ${_estados.length} clave(s), modelo ${ApiConfig.modelName}',
    );

    for (var i = 0; i < _estados.length; i++) {
      final reloj = Stopwatch()..start();
      try {
        await ClienteGemini.transmitir(
          clave: _estados[i].clave,
          modelo: 'gemini-3.7-flash',
          instruccion: 'Responde de forma muy breve.',
          contenidos: [ClienteGemini.mensajeUsuario('Responde solo con la palabra: ok')],
        ).join().timeout(const Duration(seconds: 30));
        debugPrint(
          '[Gemini] diagnóstico clave #${i + 1}: OK en ${reloj.elapsedMilliseconds} ms',
        );
      } catch (e) {
        var detalle = ocultarClaves(e.toString());
        if (detalle.length > 400) detalle = '${detalle.substring(0, 400)}...';
        debugPrint(
          '[Gemini] diagnóstico clave #${i + 1}: FALLA (${e.runtimeType}) '
              'en ${reloj.elapsedMilliseconds} ms: $detalle',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    debugPrint('[Gemini] diagnóstico terminado');
  }

  /// Mensaje para el estudiante cuando no queda ninguna clave utilizable.
  String mensajeSinClaves() {
    final ahora = DateTime.now();
    final activas = _estados.where((e) => !e.deshabilitada).toList();
    if (activas.isEmpty) {
      return 'La app no está configurada correctamente. '
          'Avisa a tu docente o al desarrollador.';
    }
    final espera = activas
        .map((e) => e.esperaRestante(ahora))
        .reduce((a, b) => a < b ? a : b);
    if (espera > const Duration(minutes: 3)) {
      return 'El tutor está muy ocupado en este momento. Intenta de nuevo más tarde.';
    }
    final segundos = max(espera.inSeconds, 1) + 1;
    return 'El tutor está muy ocupado en este momento. '
        'Intenta de nuevo en unos $segundos segundos.';
  }

  /// Decide qué tipo de falla es y cuánto conviene esperar.
  static FallaClave clasificar(Object e) {
    if (e is SocketException || e is http.ClientException) {
      return const FallaClave(TipoFalla.otra, Duration.zero);
    }
    if (e is TimeoutException) {
      return const FallaClave(TipoFalla.servidor, Duration(seconds: 30));
    }
    if (e is RespuestaIncompletaGemini || e is RespuestaCortadaGemini) {
      return const FallaClave(TipoFalla.servidor, Duration(seconds: 5));
    }
    if (e is ContenidoBloqueadoGemini) {
      return const FallaClave(TipoFalla.otra, Duration.zero);
    }
    if (e is ErrorHttpGemini) return _clasificarHttp(e);

    return const FallaClave(TipoFalla.desconocida, Duration(seconds: 10));
  }

  static FallaClave _clasificarHttp(ErrorHttpGemini e) {
    final m = e.mensaje.toLowerCase();
    final estado = e.estado.toUpperCase();

    if (e.codigo == 429 || estado == 'RESOURCE_EXHAUSTED' || m.contains('quota')) {
      final diaria =
          m.contains('perday') || m.contains('per day') || m.contains('daily');
      return FallaClave(
        TipoFalla.cuota,
        diaria ? const Duration(hours: 1) : const Duration(seconds: 65),
      );
    }

    if (e.codigo == 401 ||
        e.codigo == 403 ||
        estado == 'PERMISSION_DENIED' ||
        estado == 'UNAUTHENTICATED' ||
        m.contains('api key not valid') ||
        m.contains('api key expired')) {
      return const FallaClave(TipoFalla.claveInvalida, Duration.zero);
    }

    if (e.codigo == 400 || e.codigo == 404) {
      return const FallaClave(TipoFalla.otra, Duration.zero);
    }

    if (e.codigo >= 500 ||
        estado == 'UNAVAILABLE' ||
        estado == 'INTERNAL' ||
        estado == 'DEADLINE_EXCEEDED' ||
        m.contains('overloaded') ||
        m.contains('high demand')) {
      return const FallaClave(TipoFalla.servidor, Duration(seconds: 15));
    }

    return const FallaClave(TipoFalla.desconocida, Duration(seconds: 10));
  }

  /// Texto seguro para la consola: reemplaza cualquier clave por ***.
  String ocultarClaves(String texto) {
    var limpio = texto;
    for (final e in _estados) {
      limpio = limpio.replaceAll(e.clave, '***');
    }
    limpio = limpio.replaceAll(RegExp(r'AQ\.[A-Za-z0-9_\-]{20,}'), '***');
    limpio = limpio.replaceAll(RegExp(r'AIza[0-9A-Za-z_\-]{30,}'), '***');
    return limpio;
  }
}