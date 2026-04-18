import 'package:pkgwatch/src/pubspec.dart';
import 'package:test/test.dart';

void main() {
  group('parsePubspec', () {
    test('pulls name and plain deps', () {
      final p = parsePubspec('''
name: demo
dependencies:
  http: ^1.2.0
  path: 1.8.0
''');
      expect(p.name, 'demo');
      expect(p.deps.length, 2);
      expect(p.deps.map((d) => d.name), containsAll(['http', 'path']));
    });

    test('handles dev_dependencies too', () {
      final p = parsePubspec('''
name: demo
dependencies:
  http: ^1.2.0
dev_dependencies:
  test: ^1.25.0
''');
      expect(p.deps.map((d) => d.name), containsAll(['http', 'test']));
    });

    test('skips git/path/sdk refs', () {
      final p = parsePubspec('''
name: demo
dependencies:
  flutter:
    sdk: flutter
  local_pkg:
    path: ../local
  gitdep:
    git: https://github.com/x/y
  http: ^1.2.0
''');
      expect(p.deps.map((d) => d.name).toList(), ['http']);
    });

    test('reads map-form version', () {
      final p = parsePubspec('''
name: demo
dependencies:
  foo:
    version: ^2.0.0
    hosted: https://pub.dev
''');
      expect(p.deps.single.name, 'foo');
      expect(p.deps.single.constraint, '^2.0.0');
    });

    test('throws on non-map root', () {
      expect(() => parsePubspec('- not a map'), throwsFormatException);
    });
  });
}
