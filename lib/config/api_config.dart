class ApiConfig {
  ApiConfig._();

  static const String apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const String _apiKeysCrudo = String.fromEnvironment('GEMINI_API_KEYS');

  static List<String> get apiKeys {
    final claves = <String>{};
    for (final c in [..._apiKeysCrudo.split(','), apiKey]) {
      // Tolera el formato de lista en env.json: ["a", "b"] llega como "[a, b]",
      // así que se quitan corchetes, comillas y espacios (las claves no los usan).
      final limpia = c.replaceAll(RegExp(r'''[\[\]"'\s]'''), '');
      if (limpia.isNotEmpty && limpia != 'TU_API_KEY_AQUI') claves.add(limpia);
    }
    return claves.toList();
  }

  static const String modelName = 'gemini-3.8-flash';

  static const String thinkingLevel = 'LOW';

  static const int maxOutputTokens = 8192;

  static const List<String> modelosAlternos = [
    'gemini-3.7-flash',
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-3.8-flash-lite',
    'gemini-3.5-flash-lite',
  ];

  static List<String> get todosLosModelos => [modelName, ...modelosAlternos];
}