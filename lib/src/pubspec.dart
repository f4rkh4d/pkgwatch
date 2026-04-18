import 'dart:io';
import 'package:yaml/yaml.dart';

class PubDep {
  final String name;
  final String? constraint;
  PubDep(this.name, this.constraint);
}

class Pubspec {
  final String name;
  final List<PubDep> deps;
  Pubspec(this.name, this.deps);
}

/// parses a pubspec.yaml file and extracts the deps + dev_deps that are
/// hosted on pub.dev (skips git/path/sdk refs, skips the `flutter` sdk one).
Pubspec parsePubspec(String source) {
  final doc = loadYaml(source);
  if (doc is! Map) {
    throw FormatException('pubspec root is not a map');
  }
  final name = (doc['name'] ?? 'unknown').toString();
  final deps = <PubDep>[];
  for (final key in const ['dependencies', 'dev_dependencies']) {
    final section = doc[key];
    if (section is! Map) continue;
    section.forEach((k, v) {
      final depName = k.toString();
      if (v == null || v is String) {
        // plain version constraint (or `any`)
        deps.add(PubDep(depName, v?.toString()));
      } else if (v is Map) {
        // skip git/path/sdk refs, they aren't on pub.dev
        if (v.containsKey('git') || v.containsKey('path') || v.containsKey('sdk')) {
          return;
        }
        final ver = v['version'];
        deps.add(PubDep(depName, ver?.toString()));
      }
    });
  }
  return Pubspec(name, deps);
}

Future<Pubspec> loadPubspec(String path) async {
  final f = File(path);
  if (!await f.exists()) {
    throw StateError('no pubspec at $path');
  }
  return parsePubspec(await f.readAsString());
}
