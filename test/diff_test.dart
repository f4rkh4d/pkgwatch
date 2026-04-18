import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pkgwatch/src/diff.dart';
import 'package:pkgwatch/src/registry.dart';
import 'package:test/test.dart';

void main() {
  group('extractPinned', () {
    test('strips caret', () {
      expect(extractPinned('^1.2.3').toString(), '1.2.3');
    });
    test('handles range', () {
      expect(extractPinned('>=1.2.3 <2.0.0').toString(), '1.2.3');
    });
    test('returns null for any / null', () {
      expect(extractPinned('any'), isNull);
      expect(extractPinned(null), isNull);
    });
  });

  group('classify', () {
    test('major bump', () {
      final r = diff('http', '^0.13.6', '1.2.0');
      expect(r.bump, Bump.major);
      expect(r.behind, isTrue);
    });
    test('minor bump', () {
      final r = diff('path', '^1.8.0', '1.9.1');
      expect(r.bump, Bump.minor);
    });
    test('patch bump', () {
      final r = diff('args', '^2.4.0', '2.4.2');
      expect(r.bump, Bump.patch);
    });
    test('up to date', () {
      final r = diff('meta', '^1.11.0', '1.11.0');
      expect(r.bump, Bump.none);
      expect(r.behind, isFalse);
    });
    test('unknown when latest missing', () {
      final r = diff('x', '^1.0.0', null);
      expect(r.bump, Bump.unknown);
    });
  });

  group('Registry (mocked)', () {
    test('parses latest from pub.dev-shaped response', () async {
      final mock = MockClient((req) async {
        expect(req.url.path, contains('/api/packages/http'));
        return http.Response(
          jsonEncode({
            'name': 'http',
            'latest': {'version': '1.2.0'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final reg = Registry(mock);
      expect(await reg.latestVersion('http'), '1.2.0');
    });

    test('returns null on 404', () async {
      final mock = MockClient((req) async => http.Response('{}', 404));
      final reg = Registry(mock);
      expect(await reg.latestVersion('nope'), isNull);
    });

    test('latestAll fetches many with pool', () async {
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({'latest': {'version': '9.9.9'}}),
          200,
        );
      });
      final reg = Registry(mock);
      final out = await reg.latestAll(['a', 'b', 'c'], poolSize: 2);
      expect(out, {'a': '9.9.9', 'b': '9.9.9', 'c': '9.9.9'});
    });
  });
}
