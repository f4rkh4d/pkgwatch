import 'package:pub_semver/pub_semver.dart';

enum Bump { none, patch, minor, major, unknown }

class DiffResult {
  final String name;
  final String? current; // what's pinned in the pubspec
  final String? latest;  // what pub.dev says is newest
  final Bump bump;
  DiffResult(this.name, this.current, this.latest, this.bump);

  bool get behind => bump == Bump.patch || bump == Bump.minor || bump == Bump.major;
}

/// pulls a concrete version out of a constraint like `^1.2.3` or `>=1.2.3 <2.0.0`.
/// returns null if we can't tell (e.g. `any`).
Version? extractPinned(String? constraint) {
  if (constraint == null || constraint.trim().isEmpty) return null;
  final c = constraint.trim();
  if (c == 'any') return null;
  // strip common prefixes
  final stripped = c
      .replaceAll('^', '')
      .replaceAll('~', '')
      .replaceAll('>=', ' ')
      .replaceAll('<=', ' ')
      .replaceAll('>', ' ')
      .replaceAll('<', ' ')
      .trim();
  final first = stripped.split(RegExp(r'\s+')).first;
  try {
    return Version.parse(first);
  } catch (_) {
    return null;
  }
}

Bump classify(Version? current, Version? latest) {
  if (current == null || latest == null) return Bump.unknown;
  if (latest <= current) return Bump.none;
  if (latest.major != current.major) return Bump.major;
  if (latest.minor != current.minor) return Bump.minor;
  if (latest.patch != current.patch) return Bump.patch;
  return Bump.none;
}

DiffResult diff(String name, String? constraint, String? latestStr) {
  final cur = extractPinned(constraint);
  Version? latest;
  if (latestStr != null) {
    try {
      latest = Version.parse(latestStr);
    } catch (_) {
      latest = null;
    }
  }
  return DiffResult(
    name,
    cur?.toString(),
    latest?.toString(),
    classify(cur, latest),
  );
}
