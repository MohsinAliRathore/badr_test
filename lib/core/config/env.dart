/// Runtime configuration. Override with:
/// `flutter run -d chrome --dart-define=API_URL=https://sandbox.badrgo.com`
class Env {
  Env._();

  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://sandbox.badrgo.com',
  );

  static Uri get baseUri => Uri.parse(apiUrl);

  static Uri get wsUri {
    final http = baseUri;
    final scheme = http.scheme == 'https' ? 'wss' : 'ws';
    return http.replace(scheme: scheme, path: '/ws');
  }
}
