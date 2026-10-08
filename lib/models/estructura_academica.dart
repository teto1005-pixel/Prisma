/// Representa una sección o sub-tema específico dentro de una unidad donde se lleva a cabo la tutoría.
class Seccion {
  final String id;
  final String titulo;
  final String descripcionCorta;
  final List<String> conceptosClave;
  final List<String> preguntasSugeridas;

  const Seccion({
    required this.id,
    required this.titulo,
    required this.descripcionCorta,
    required this.conceptosClave,
    required this.preguntasSugeridas,
  });

  String get nombre => titulo; // Alias para compatibilidad
}

/// Representa una unidad temática dentro del currículo de un grado específico.
class Unidad {
  final String id;
  final int numero;
  final String titulo;
  final String asignatura; // Ej: Matemáticas, Lengua y Literatura, Ciencias Naturales, etc.
  final String icono; // Identificador del icono para la interfaz
  final List<Seccion> secciones;

  const Unidad({
    required this.id,
    required this.numero,
    required this.titulo,
    required this.asignatura,
    required this.icono,
    required this.secciones,
  });

  String get nombre => titulo; // Alias para compatibilidad
}

/// Representa un grado académico de educación secundaria en Nicaragua (del 7mo al 11mo Año).
class Grado {
  final String id;
  final String nombre;
  final String alias;
  final String descripcion;
  final int colorHex;
  final List<Unidad> unidades;

  const Grado({
    required this.id,
    required this.nombre,
    required this.alias,
    required this.descripcion,
    required this.colorHex,
    required this.unidades,
  });
}