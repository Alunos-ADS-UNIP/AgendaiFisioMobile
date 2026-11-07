/// Normaliza nomes somente para comparação e busca.
///
/// A grafia recebida da API nunca é alterada por esta função.
String normalizeSpecialtyName(String value) {
  const replacements = {
    'á': 'a',
    'à': 'a',
    'ã': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'õ': 'o',
    'ô': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  final lower = value.trim().toLowerCase();
  final withoutAccents = lower.split('').map((character) {
    return replacements[character] ?? character;
  }).join();
  return withoutAccents.replaceAll(RegExp(r'\s+'), ' ');
}
