// test/motor_calculadora_test.dart
//
// Pruebas del motor de la calculadora. Ejecútalas con:
//   flutter test test/motor_calculadora_test.dart

import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports
import '../lib/services/motor_calculadora.dart';

String _calc(String expresion, {bool grados = true}) {
  try {
    final v = MotorCalculadora.evaluar(expresion, grados: grados);
    return formatear(v, modoInicial(v)).plano;
  } on ErrorCalculadora catch (e) {
    return 'ERROR: ${e.mensaje}';
  }
}

void main() {
  const casos = <String, String>{
    '1/2+1/3': '5/6',
    '3/4÷1/2': '3/2',
    '0.5+0.25': '0.75',
    '1/3×3': '1',
    '2^10': '1024',
    '2^−2': '1/4',
    '(1/4)^(1/2)': '1/2',
    '8^(1/3)': '2',
    '√12': '2√3',
    '√(1/4)': '1/2',
    '1/√2': '√2/2',
    '√2×√2': '2',
    '√8+√2': '3√2',
    '√3+√2': '3.14626437',
    '2√3': '2√3',
    '√(3+4)': '√7',
    'sin(30)': '1/2',
    'cos(60)': '1/2',
    'sin(45)': '√2/2',
    'tan(45)': '1',
    'tan(60)': '√3',
    'sin(150)': '1/2',
    'cos(120)': '-1/2',
    'sin(10)': '0.1736481777',
    '5!': '120',
    '5P2': '20',
    '5C2': '10',
    '10C3': '120',
    '0!': '1',
    'log(1000)': '3',
    'ln(e)': '1',
    'logb(2,8)': '3',
    '3ˣ√27': '3',
    '−2^2': '-4',
    '(−2)^2': '4',
    '(−8)^(1/3)': '-2',
    '50%': '1/2',
    '200×15%': '30',
    '2(3+4)': '14',
    '2π': '6.283185307',
    '2×(3+4': '14',
    '−3/4': '-3/4',
    '2−3/4': '5/4',
    '1/2π': '1.570796327',
    '5×10^(−3)': '0.005',
    '2^3^2': '512',
    '2^−1': '1/2',
    'sin⁻¹(0.5)': '30',
    '7/4': '7/4',
    '1/3+0.5': '0.8333333333',
    '3sin(30)': '3/2',
    '(1+2)/(3+4)': '3/7',
    'cos⁻¹(0)': '90',
    'tan⁻¹(1)': '45',
    'abs(−3/4)': '3/4',
    '∛(27)': '3',
    '∛8': '2',
    '√9': '3',
    '√(2)^2': '2',
    '2×−3': '-6',
    '1/−2': '-1/2',
    '12/16': '3/4',
    '(2/3)^2': '4/9',
    '(2/3)^(−2)': '9/4',
    '100000000000': '1×10^11',
    '20!': '2.432902008×10^18',
    '1/8^(1/3)': '1/2',
    '√50': '5√2',
    '√72': '6√2',
    '√48': '4√3',
    '√(12/25)': '2√3/5',
    '√45': '3√5',
    '√98': '7√2',
    '√1': '1',
    '√180': '6√5',
    '3√8': '6√2',
    '√2/2': '√2/2',
    '4/√2': '2√2',
  };

  group('resultados', () {
    casos.forEach((expresion, esperado) {
      test('$expresion = $esperado', () {
        expect(_calc(expresion), esperado);
      });
    });
  });

  group('errores', () {
    const matematicos = ['1/0', '√(−1)', '0^0', 'tan(90)', '5C7', '(−8)^(1/2)', 'log(0)'];
    const deSintaxis = ['2+', '()', '3..2', 'abc'];

    for (final e in matematicos) {
      test('$e es error matemático', () {
        expect(_calc(e), 'ERROR: Error matemático');
      });
    }
    for (final e in deSintaxis) {
      test('$e es error de sintaxis', () {
        expect(_calc(e), 'ERROR: Error de sintaxis');
      });
    }
  });

  group('formas de mostrar', () {
    test('7/4 en número mixto', () {
      final v = MotorCalculadora.evaluar('7/4');
      expect(formatear(v, ModoResultado.mixto).plano, '1 3/4');
      expect(formatear(v, ModoResultado.decimal).plano, '1.75');
    });

    test('−7/4 en número mixto', () {
      final v = MotorCalculadora.evaluar('−7/4');
      expect(formatear(v, ModoResultado.mixto).plano, '-1 3/4');
    });

    test('radianes: sin(π) es 0', () {
      final v = MotorCalculadora.evaluar('sin(π)', grados: false);
      expect(formatear(v, modoInicial(v)).plano, '0');
    });

    test('Ans usa el resultado anterior', () {
      final anterior = MotorCalculadora.evaluar('3/4');
      final v = MotorCalculadora.evaluar('Ans×2', ans: anterior);
      expect(formatear(v, modoInicial(v)).plano, '3/2');
    });
  });
}