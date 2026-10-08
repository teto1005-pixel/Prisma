import '../models/estructura_academica.dart';

Grado _grado({
  required String id,
  required String nombre,
  required String descripcion,
  required List<(String, List<String>)> unidades,
}) {
  final int color = switch (id) {
    '7mo' => 0xFF4338CA,
    '8vo' => 0xFF6366F1,
    '9no' => 0xFF7C3AED,
    '10mo' => 0xFF8B5CF6,
    '11mo' => 0xFF4F46E5,
    _ => 0xFF4338CA,
  };

  return Grado(
    id: id,
    nombre: nombre,
    alias: descripcion,
    descripcion: descripcion,
    colorHex: color,
    unidades: [
      for (final (i, (titulo, secciones)) in unidades.indexed)
        Unidad(
          id: 'u${i + 1}_$id',
          numero: i + 1,
          titulo: 'Unidad ${i + 1}: $titulo',
          asignatura: 'Matemáticas',
          icono: switch (id) {
            '7mo' => 'calculate',
            '8vo' => 'functions',
            '9no' => 'calculate',
            '10mo' => 'change_history',
            '11mo' => 'show_chart',
            _ => 'calculate',
          },
          secciones: [
            for (final (j, seccion) in secciones.indexed)
              Seccion(
                id: 's${j + 1}_u${i + 1}_$id',
                titulo: 'Sección ${j + 1}: $seccion',
                descripcionCorta: seccion,
                conceptosClave: [seccion],
                preguntasSugeridas: [
                  'Explícame paso a paso el tema: $seccion',
                  '¿Cuáles son las reglas o fórmulas clave de: $seccion?',
                  'Ponme un ejercicio práctico de: $seccion para resolver',
                ],
              ),
          ],
        ),
    ],
  );
}

final List<Grado> listaGrados = [
  // ---------------------------------------------------------------- 7mo
  _grado(
    id: '7mo',
    nombre: '7mo Año',
    descripcion: '1er Año de Secundaria',
    unidades: [
      ('Operaciones con Números Naturales, Fracciones y Decimales', [
        'Operaciones con números naturales',
        'Operaciones con fracciones y decimales',
      ]),
      ('Números Positivos y Negativos', [
        'Los números positivos, negativos y el cero',
        'Adición y sustracción con números positivos y negativos',
        'Multiplicación con números positivos y negativos',
        'Operaciones combinadas',
      ]),
      ('Álgebra', [
        'Expresiones algebraicas',
        'Operaciones con expresiones algebraicas',
      ]),
      ('Ecuaciones de Primer Grado', [
        'Ecuaciones de primer grado',
        'Solución de ecuaciones de primer grado',
      ]),
      ('Proporcionalidad', [
        'Proporcionalidad directa',
        'Proporcionalidad inversa',
        'Aplicaciones de proporcionalidad directa e inversa',
      ]),
      ('Introducción a la Geometría', [
        'Nociones básicas de geometría',
        'Construcciones con regla y compás',
      ]),
      ('Medidas de Figuras Geométricas', [
        'Perímetro de polígonos',
        'Área de triángulos y cuadriláteros',
        'Círculo y sector circular',
      ]),
    ],
  ),

  // ---------------------------------------------------------------- 8vo
  _grado(
    id: '8vo',
    nombre: '8vo Año',
    descripcion: '2do Año de Secundaria',
    unidades: [
      ('Operaciones con Polinomios', [
        'Adición y sustracción de polinomios',
        'Multiplicación de polinomios',
        'División de polinomios',
      ]),
      ('Sistemas de Ecuaciones de Primer Grado', [
        'Ecuaciones de primer grado',
        'Método de sustitución',
        'Método de reducción',
        'Sistemas de dos ecuaciones con paréntesis, fracciones y decimales',
        'Aplicaciones de los sistemas de dos ecuaciones de primer grado',
      ]),
      ('Funciones de Primer Grado', [
        'Función de primer grado',
        'Gráfica de la función de primer grado',
        'Expresión de la función de primer grado utilizando la pendiente',
        'Gráfica de ecuaciones de primer grado con dos variables',
        'Aplicaciones de la función de primer grado',
      ]),
      ('Radicales', [
        'Raíz cuadrada',
        'Operaciones con raíces cuadradas',
      ]),
      ('Paralelismo', [
        'Resta de ángulos',
        'Ángulos entre rectas cortadas por una transversal',
        'Ángulos internos y externos de un triángulo',
      ]),
      ('Congruencia', [
        'Criterios de congruencia de triángulos',
        'Introducción a la demostración',
        'Triángulo isósceles',
        'Congruencia de triángulos rectángulos',
      ]),
      ('Paralelogramos', [
        'Propiedades de los paralelogramos',
        'Condiciones para ser paralelogramo',
        'Paralelogramos especiales',
      ]),
      ('Sólidos', [
        'Poliedros',
        'Cuerpos redondos',
      ]),
    ],
  ),

  // ---------------------------------------------------------------- 9no
  _grado(
    id: '9no',
    nombre: '9no Año',
    descripcion: '3er Año de Secundaria',
    unidades: [
      ('Productos Notables y Factorización', [
        'Multiplicación de polinomios',
        'Productos notables',
        'Factorización',
      ]),
      ('Ecuaciones de Segundo Grado', [
        'Introducción a las ecuaciones de segundo grado',
        'Solución de ecuaciones de segundo grado',
        'Aplicación de las ecuaciones de segundo grado',
      ]),
      ('Funciones de Segundo Grado', [
        'Introducción a las funciones de segundo grado',
        'Función de segundo grado',
        'Valor máximo o mínimo de una función de segundo grado y su aplicación',
      ]),
      ('Proporcionalidad Entre Segmentos', [
        'Razón entre segmentos',
        'División de un segmento',
      ]),
      ('Semejanza', [
        'Criterios de semejanza de triángulos',
        'Semejanza de triángulos rectángulos y paralelismos',
      ]),
      ('Teorema de Pitágoras', [
        'Teorema de Pitágoras',
        'Aplicaciones del Teorema de Pitágoras en geometría',
      ]),
      ('Circunferencia', [
        'Ángulos inscritos',
        'Aplicaciones de ángulos inscritos',
      ]),
      ('Estadística', [
        'Presentación de tablas y gráficas',
      ]),
    ],
  ),

  // --------------------------------------------------------------- 10mo
  _grado(
    id: '10mo',
    nombre: '10mo Año',
    descripcion: '4to Año de Secundaria',
    unidades: [
      ('Conjuntos e Intervalos Numéricos', [
        'Conjuntos',
        'Intervalos numéricos',
      ]),
      ('Inecuaciones de Primer y Segundo Grado', [
        'Inecuaciones de primer grado',
        'Inecuaciones de primer grado con valor absoluto',
        'Inecuaciones de segundo grado',
      ]),
      ('Fracciones Algebraicas', [
        'Simplificación, multiplicación y división de fracciones algebraicas',
        'Adición y sustracción de fracciones algebraicas',
      ]),
      ('Ecuaciones de Tercer Grado', [
        'División sintética',
        'Teorema del residuo y teorema del factor',
        'Factorización de polinomios de tercer grado y resolución de ecuaciones de tercer grado',
      ]),
      ('Introducción a la Trigonometría', [
        'Funciones trigonométricas de ángulos agudos en triángulos rectángulos',
        'Valores de las funciones trigonométricas de ángulos agudos',
        'Resolución de triángulos rectángulos',
        'Relaciones entre seno, coseno y tangente',
      ]),
      ('Funciones Trigonométricas', [
        'Funciones trigonométricas de un ángulo cualquiera',
        'Relación entre seno, coseno y tangente',
        'Relación entre las funciones trigonométricas',
        'Gráficas de las funciones trigonométricas',
      ]),
      ('Trigonometría Analítica', [
        'Ley del seno',
        'Ley del coseno',
      ]),
      ('Estadística', [
        'Medidas de tendencia central y representación gráfica de datos',
        'Medidas de posición y dispersión',
      ]),
    ],
  ),

  // --------------------------------------------------------------- 11mo
  _grado(
    id: '11mo',
    nombre: '11mo Año',
    descripcion: '5to Año de Secundaria',
    unidades: [
      ('Sucesiones', [
        'Sucesiones, notación y término general',
        'Sucesiones aritméticas',
        'Sucesiones geométricas',
        'Notación de sumatoria',
      ]),
      ('Potenciación y Funciones Exponenciales', [
        'Potenciación y radicación',
        'Funciones exponenciales',
      ]),
      ('Logaritmo y Funciones Logarítmicas', [
        'Logaritmo',
        'Funciones logarítmicas',
      ]),
      ('Geometría Analítica', [
        'Punto y segmento',
        'La recta',
        'La circunferencia',
      ]),
      ('Cónicas', [
        'La parábola',
        'La elipse',
        'La hipérbola',
      ]),
      ('Técnicas de Conteo y Probabilidades', [
        'Técnicas de conteo',
        'Probabilidades',
      ]),
    ],
  ),
];

/// Clase contenedora para mantener compatibilidad con las pantallas del proyecto.
class DatosCurriculo {
  static List<Grado> get grados => listaGrados;

  static Grado? obtenerGradoPorId(String id) {
    try {
      return listaGrados.firstWhere((g) => g.id == id);
    } catch (_) {
      return listaGrados.isNotEmpty ? listaGrados.first : null;
    }
  }

  static Unidad? obtenerUnidadPorId(String gradoId, String unidadId) {
    final grado = obtenerGradoPorId(gradoId);
    if (grado == null) return null;
    try {
      return grado.unidades.firstWhere((u) => u.id == unidadId);
    } catch (_) {
      return null;
    }
  }

  static Seccion? obtenerSeccionPorId(String gradoId, String unidadId, String seccionId) {
    final unidad = obtenerUnidadPorId(gradoId, unidadId);
    if (unidad == null) return null;
    try {
      return unidad.secciones.firstWhere((s) => s.id == seccionId);
    } catch (_) {
      return null;
    }
  }
}