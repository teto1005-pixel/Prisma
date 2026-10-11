// lib/models/perfil_estudiante.dart

/// Estilos de aprendizaje preferidos por el estudiante para adaptar pedagógicamente las explicaciones.
enum EstiloAprendizaje {
  pasoAPaso,
  simplificado,
  explicativo,
}

extension EstiloAprendizajeExtension on EstiloAprendizaje {
  String get nombreLegible {
    switch (this) {
      case EstiloAprendizaje.pasoAPaso:
        return 'Paso a paso';
      case EstiloAprendizaje.simplificado:
        return 'Simplificado';
      case EstiloAprendizaje.explicativo:
        return 'Explicativo';
    }
  }

  String get descripcion {
    switch (this) {
      case EstiloAprendizaje.pasoAPaso:
        return 'Procedimientos ordenados y secuenciales (Paso 1, Paso 2...).';
      case EstiloAprendizaje.simplificado:
        return 'Conceptos directos, resúmenes sin rodeos técnicos innecesarios.';
      case EstiloAprendizaje.explicativo:
        return 'Profundidad teórica, origen de las fórmulas y ejemplos de la vida real.';
    }
  }

  String get instruccionPedagogica {
    switch (this) {
      case EstiloAprendizaje.pasoAPaso:
        return 'Estructura toda la explicación en pasos numerados estrictos (Paso 1, Paso 2, etc.), sin saltarte ningún procedimiento intermedio.';
      case EstiloAprendizaje.simplificado:
        return 'Sé conciso, directo al grano y utiliza un lenguaje sumamente claro, evitando vocabulario excesivamente rebuscado.';
      case EstiloAprendizaje.explicativo:
        return 'Profundiza en los fundamentos teóricos, el contexto histórico del descubrimiento o concepto y su utilidad práctica cotidiana.';
    }
  }
}

/// Modelo de datos que almacena el perfil y las preferencias académicas del estudiante de secundaria.
class PerfilEstudiante {
  final String nombre;
  final String gradoId;
  final EstiloAprendizaje estiloAprendizaje;

  PerfilEstudiante({
    required this.nombre,
    required this.gradoId,
    required this.estiloAprendizaje,
  });

  bool get estaCompletado => nombre.trim().isNotEmpty;

  PerfilEstudiante copyWith({
    String? nombre,
    String? gradoId,
    EstiloAprendizaje? estiloAprendizaje,
  }) {
    return PerfilEstudiante(
      nombre: nombre ?? this.nombre,
      gradoId: gradoId ?? this.gradoId,
      estiloAprendizaje: estiloAprendizaje ?? this.estiloAprendizaje,
    );
  }
}