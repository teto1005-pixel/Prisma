// lib/services/cliente_gemini.dart

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ErrorHttpGemini implements Exception {
  const ErrorHttpGemini(this.codigo, this.estado, this.mensaje);

  final int codigo;
  final String estado;
  final String mensaje;

  @override
  String toString() {
    final prefijo = estado.isEmpty ? '' : '$estado: ';
    return 'HTTP $codigo $prefijo$mensaje';
  }
}

/// La pregunta o la respuesta fueron bloqueadas por los filtros de seguridad.
class ContenidoBloqueadoGemini implements Exception {
  const ContenidoBloqueadoGemini(this.motivo);

  final String motivo;

  @override
  String toString() => 'Contenido bloqueado: $motivo';
}

/// La transmisión SSE se cerró antes de emitir cualquier contenido visible.
class RespuestaIncompletaGemini implements Exception {
  const RespuestaIncompletaGemini([this.motivo = 'Stream finalizado sin contenido']);

  final String motivo;

  @override
  String toString() => 'Respuesta incompleta: $motivo';
}

/// La respuesta llegó pero sin cierre normal (sin señal STOP o cortada por
/// límite de tokens). Se lanza DESPUÉS de haber entregado todo el texto.
class RespuestaCortadaGemini implements Exception {
  const RespuestaCortadaGemini(this.motivo);

  final String motivo;

  @override
  String toString() => 'Respuesta cortada: $motivo';
}

class ClienteGemini {
  ClienteGemini._();

  /// Ruta base del endpoint de modelos de Google AI Studio.
  static const String _base =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Mensaje del estudiante en el formato de la API.
  static Map<String, dynamic> mensajeUsuario(String texto) => {
    'role': 'user',
    'parts': [
      {'text': texto},
    ],
  };

  /// Respuesta del tutor en el formato de la API.
  static Map<String, dynamic> mensajeModelo(String texto) => {
    'role': 'model',
    'parts': [
      {'text': texto},
    ],
  };

  /// Envía la conversación y devuelve el texto de la respuesta por trozos SSE.
  /// Lanza [ErrorHttpGemini] si la API responde con error,
  /// [ContenidoBloqueadoGemini] si el filtro de seguridad bloquea la pregunta y
  /// [RespuestaIncompletaGemini] si la conexión se cierra sin haber enviado ningún texto y
  /// [RespuestaCortadaGemini] si el texto llegó pero sin cierre normal (STOP).
  static Stream<String> transmitir({
    required String clave,
    required String modelo,
    required String instruccion,
    required List<Map<String, dynamic>> contenidos,
  }) async* {
    final cliente = http.Client();
    var emitioTexto = false;
    String? motivoCierre;

    try {
      final peticion = http.Request(
        'POST',
        Uri.parse('$_base/$modelo:streamGenerateContent?alt=sse'),
      );
      peticion.headers['Content-Type'] = 'application/json';
      peticion.headers['x-goog-api-key'] = clave;
      peticion.bodyBytes = utf8.encode(jsonEncode(_cuerpo(instruccion, contenidos)));

      final respuesta = await cliente.send(peticion);

      if (respuesta.statusCode != 200) {
        final cuerpo = await respuesta.stream.bytesToString();
        throw _errorHttp(respuesta.statusCode, cuerpo);
      }

      final lineas = respuesta.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final linea in lineas) {
        if (!linea.startsWith('data:')) continue;
        final datos = linea.substring(5).trim();
        if (datos.isEmpty || datos == '[DONE]') continue;

        final json = jsonDecode(datos);
        if (json is! Map<String, dynamic>) continue;

        // 1. Verificación de seguridad
        final retroalimentacion = json['promptFeedback'];
        if (retroalimentacion is Map<String, dynamic> &&
            retroalimentacion['blockReason'] != null) {
          throw ContenidoBloqueadoGemini('${retroalimentacion['blockReason']}');
        }

        // 2. Anotar el motivo de cierre (STOP, MAX_TOKENS...) cuando llegue
        final cierre = _extraerMotivoCierre(json);
        if (cierre != null) motivoCierre = cierre;

        // 3. Extraer y emitir texto visible
        final texto = _extraerTexto(json);
        if (texto.isNotEmpty) {
          emitioTexto = true;
          yield texto;
        }
      }

      // Solo lanzamos excepción si la respuesta se cerró habiendo enviado 0 caracteres
      if (!emitioTexto) {
        throw const RespuestaIncompletaGemini(
          'El servidor cerró la conexión sin enviar contenido.',
        );
      }

      // El texto ya se entregó; si no hubo cierre normal, se avisa al final.
      if (motivoCierre != 'STOP') {
        throw RespuestaCortadaGemini(motivoCierre ?? 'sin señal de cierre');
      }
    } finally {
      cliente.close();
    }
  }

  static Map<String, dynamic> _cuerpo(
      String instruccion,
      List<Map<String, dynamic>> contenidos,
      ) {
    final config = <String, dynamic>{'maxOutputTokens': ApiConfig.maxOutputTokens};
    if (ApiConfig.thinkingLevel.isNotEmpty) {
      config['thinkingConfig'] = {'thinkingLevel': ApiConfig.thinkingLevel};
    }
    return {
      'systemInstruction': {
        'parts': [
          {'text': instruccion},
        ],
      },
      'contents': contenidos,
      'generationConfig': config,
    };
  }

  /// Motivo de cierre de la respuesta (STOP, MAX_TOKENS, SAFETY...), si ya llegó.
  static String? _extraerMotivoCierre(Map<String, dynamic> json) {
    final candidatos = json['candidates'];
    if (candidatos is! List || candidatos.isEmpty) return null;
    final primero = candidatos.first;
    if (primero is! Map<String, dynamic>) return null;
    final motivo = primero['finishReason'];
    return motivo is String ? motivo : null;
  }

  /// Junta el texto de la respuesta, ignorando las partes de "pensamiento".
  static String _extraerTexto(Map<String, dynamic> json) {
    final candidatos = json['candidates'];
    if (candidatos is! List || candidatos.isEmpty) return '';
    final primero = candidatos.first;
    if (primero is! Map<String, dynamic>) return '';
    final contenido = primero['content'];
    if (contenido is! Map<String, dynamic>) return '';
    final partes = contenido['parts'];
    if (partes is! List) return '';

    final buffer = StringBuffer();
    for (final parte in partes) {
      if (parte is Map<String, dynamic> && parte['thought'] != true) {
        final texto = parte['text'];
        if (texto is String) buffer.write(texto);
      }
    }
    return buffer.toString();
  }

  static ErrorHttpGemini _errorHttp(int codigo, String cuerpo) {
    var estado = '';
    var mensaje = cuerpo;
    try {
      var json = jsonDecode(cuerpo);
      if (json is List && json.isNotEmpty) json = json.first;
      final error = json is Map ? json['error'] : null;
      if (error is Map) {
        estado = '${error['status'] ?? ''}';
        mensaje = '${error['message'] ?? cuerpo}';
      }
    } catch (_) {
      // Si el cuerpo no es JSON se usa tal cual.
    }
    return ErrorHttpGemini(codigo, estado, mensaje);
  }
}