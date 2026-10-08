// lib/data/paginas_libros.dart

/// Páginas de un tramo del libro (ambas incluidas, empezando en 1).
class RangoPaginas {
  const RangoPaginas(this.inicio, this.fin);

  final int inicio;
  final int fin;

  int get cantidad => fin - inicio + 1;

  /// Texto para mostrar: "pág. 8" o "págs. 8-13".
  String get etiqueta => inicio == fin ? 'pág. $inicio' : 'págs. $inicio-$fin';
}

/// PDF de cada grado (las claves son los ids de `Grado`).
/// Copia los archivos a assets/pdf/ con estos nombres (o cambia los nombres aquí).
const Map<String, String> pdfPorGrado = {
  '7mo': 'assets/pdf/Lmatematicas7mo.pdf',
  '8vo': 'assets/pdf/Lmatematicas8vo_unlocked.pdf',
  '9no': 'assets/pdf/Lmatematicas9no_unlocked.pdf',
  '10mo': 'assets/pdf/Lmatematicas10mo_unlocked.pdf',
  '11mo': 'assets/pdf/Lmatematicas11mo_unlocked.pdf',
};

/// Páginas de cada sección (las claves son los ids de `Seccion`).
const Map<String, RangoPaginas> paginasPorSeccion = {
  // ---- 7mo (186 páginas)
  's1_u1_7mo': RangoPaginas(8, 13),
  's2_u1_7mo': RangoPaginas(14, 21),
  's1_u2_7mo': RangoPaginas(22, 30),
  's2_u2_7mo': RangoPaginas(31, 43),
  's3_u2_7mo': RangoPaginas(44, 53),
  's4_u2_7mo': RangoPaginas(54, 61),
  's1_u3_7mo': RangoPaginas(62, 70),
  's2_u3_7mo': RangoPaginas(71, 79),
  's1_u4_7mo': RangoPaginas(80, 84),
  's2_u4_7mo': RangoPaginas(85, 93),
  's1_u5_7mo': RangoPaginas(94, 113),
  's2_u5_7mo': RangoPaginas(114, 122),
  's3_u5_7mo': RangoPaginas(123, 131),
  's1_u6_7mo': RangoPaginas(132, 141),
  's2_u6_7mo': RangoPaginas(142, 153),
  's1_u7_7mo': RangoPaginas(154, 158),
  's2_u7_7mo': RangoPaginas(159, 165),
  's3_u7_7mo': RangoPaginas(166, 186),
  // ---- 8vo (168 páginas)
  's1_u1_8vo': RangoPaginas(8, 12),
  's2_u1_8vo': RangoPaginas(13, 18),
  's3_u1_8vo': RangoPaginas(19, 23),
  's1_u2_8vo': RangoPaginas(24, 29),
  's2_u2_8vo': RangoPaginas(30, 31),
  's3_u2_8vo': RangoPaginas(32, 37),
  's4_u2_8vo': RangoPaginas(38, 41),
  's5_u2_8vo': RangoPaginas(42, 47),
  's1_u3_8vo': RangoPaginas(48, 51),
  's2_u3_8vo': RangoPaginas(52, 60),
  's3_u3_8vo': RangoPaginas(61, 64),
  's4_u3_8vo': RangoPaginas(65, 70),
  's5_u3_8vo': RangoPaginas(71, 77),
  's1_u4_8vo': RangoPaginas(78, 84),
  's2_u4_8vo': RangoPaginas(85, 95),
  's1_u5_8vo': RangoPaginas(96, 98),
  's2_u5_8vo': RangoPaginas(99, 105),
  's3_u5_8vo': RangoPaginas(106, 111),
  's1_u6_8vo': RangoPaginas(112, 118),
  's2_u6_8vo': RangoPaginas(119, 121),
  's3_u6_8vo': RangoPaginas(122, 126),
  's4_u6_8vo': RangoPaginas(127, 131),
  's1_u7_8vo': RangoPaginas(132, 135),
  's2_u7_8vo': RangoPaginas(136, 139),
  's3_u7_8vo': RangoPaginas(140, 145),
  's1_u8_8vo': RangoPaginas(146, 152),
  's2_u8_8vo': RangoPaginas(153, 168),
  // ---- 9no (175 páginas)
  's1_u1_9no': RangoPaginas(8, 12),
  's2_u1_9no': RangoPaginas(13, 25),
  's3_u1_9no': RangoPaginas(26, 39),
  's1_u2_9no': RangoPaginas(40, 45),
  's2_u2_9no': RangoPaginas(46, 55),
  's3_u2_9no': RangoPaginas(56, 63),
  's1_u3_9no': RangoPaginas(64, 72),
  's2_u3_9no': RangoPaginas(73, 82),
  's3_u3_9no': RangoPaginas(83, 91),
  's1_u4_9no': RangoPaginas(92, 95),
  's2_u4_9no': RangoPaginas(96, 101),
  's1_u5_9no': RangoPaginas(102, 109),
  's2_u5_9no': RangoPaginas(110, 129),
  's1_u6_9no': RangoPaginas(130, 134),
  's2_u6_9no': RangoPaginas(135, 141),
  's1_u7_9no': RangoPaginas(142, 147),
  's2_u7_9no': RangoPaginas(148, 155),
  's1_u8_9no': RangoPaginas(156, 175),
  // ---- 10mo (168 páginas)
  's1_u1_10mo': RangoPaginas(8, 13),
  's2_u1_10mo': RangoPaginas(14, 19),
  's1_u2_10mo': RangoPaginas(20, 29),
  's2_u2_10mo': RangoPaginas(30, 34),
  's3_u2_10mo': RangoPaginas(35, 45),
  's1_u3_10mo': RangoPaginas(46, 53),
  's2_u3_10mo': RangoPaginas(54, 65),
  's1_u4_10mo': RangoPaginas(66, 71),
  's2_u4_10mo': RangoPaginas(72, 75),
  's3_u4_10mo': RangoPaginas(76, 83),
  's1_u5_10mo': RangoPaginas(84, 89),
  's2_u5_10mo': RangoPaginas(90, 91),
  's3_u5_10mo': RangoPaginas(92, 95),
  's4_u5_10mo': RangoPaginas(96, 101),
  's1_u6_10mo': RangoPaginas(102, 110),
  's2_u6_10mo': RangoPaginas(111, 114),
  's3_u6_10mo': RangoPaginas(115, 120),
  's4_u6_10mo': RangoPaginas(121, 131),
  's1_u7_10mo': RangoPaginas(132, 137),
  's2_u7_10mo': RangoPaginas(138, 143),
  's1_u8_10mo': RangoPaginas(144, 155),
  's2_u8_10mo': RangoPaginas(156, 168),
  // ---- 11mo (156 páginas)
  's1_u1_11mo': RangoPaginas(8, 10),
  's2_u1_11mo': RangoPaginas(11, 20),
  's3_u1_11mo': RangoPaginas(21, 28),
  's4_u1_11mo': RangoPaginas(29, 35),
  's1_u2_11mo': RangoPaginas(36, 47),
  's2_u2_11mo': RangoPaginas(48, 57),
  's1_u3_11mo': RangoPaginas(58, 65),
  's2_u3_11mo': RangoPaginas(66, 75),
  's1_u4_11mo': RangoPaginas(76, 83),
  's2_u4_11mo': RangoPaginas(84, 94),
  's3_u4_11mo': RangoPaginas(95, 103),
  's1_u5_11mo': RangoPaginas(104, 109),
  's2_u5_11mo': RangoPaginas(110, 115),
  's3_u5_11mo': RangoPaginas(116, 123),
  's1_u6_11mo': RangoPaginas(124, 135),
  's2_u6_11mo': RangoPaginas(136, 156),
};