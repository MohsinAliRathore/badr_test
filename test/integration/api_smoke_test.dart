import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://sandbox.badrgo.com',
  );

  test('sign-in + /api/me against sandbox', () async {
    final client = HttpClient();
    try {
      final signIn = await client.postUrl(Uri.parse('$base/api/auth/sign-in/email'));
      signIn.headers.contentType = ContentType.json;
      signIn.write(
        jsonEncode({
          'email': 'viewer.doha@demo.test',
          'password': 'Demo@12345',
        }),
      );
      final signInRes = await signIn.close().timeout(const Duration(seconds: 10));
      final signInBody = await signInRes.transform(utf8.decoder).join();
      if (signInRes.statusCode >= 500) {

        print('Sandbox unavailable (${signInRes.statusCode}); skipping');
        return;
      }
      expect(signInRes.statusCode, 200);
      final token = (jsonDecode(signInBody) as Map)['token'] as String;

      final meReq = await client.getUrl(Uri.parse('$base/api/me'));
      meReq.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      final meRes = await meReq.close().timeout(const Duration(seconds: 10));
      final meBody = await meRes.transform(utf8.decoder).join();
      expect(meRes.statusCode, 200);
      final me = jsonDecode(meBody) as Map<String, dynamic>;
      expect(me['permissions'], isA<Map>());
      expect(me['role'], isNotEmpty);
    } on SocketException {

      print('No network; skipping live API smoke test');
    } on HttpException {

      print('HTTP failure; skipping live API smoke test');
    } finally {
      client.close(force: true);
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}
