abstract final class ApiConfig {
  /// API ASP.NET publicada no MonsterASP.NET.
  static const cloudBaseUrl = 'https://agendaifisio.runasp.net';

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Para usar o backend local, informe a origem sem alterar o código:
  /// `--dart-define=API_BASE_URL=http://127.0.0.1:5048` (iPhone/desktop) ou
  /// `--dart-define=API_BASE_URL=http://10.0.2.2:5048` (emulador Android).
  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _withoutTrailingSlash(_configuredBaseUrl);
    }
    return cloudBaseUrl;
  }

  static String _withoutTrailingSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
