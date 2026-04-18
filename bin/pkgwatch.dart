import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

import 'package:pkgwatch/src/diff.dart';
import 'package:pkgwatch/src/pubspec.dart';
import 'package:pkgwatch/src/registry.dart';

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption('path', defaultsTo: './pubspec.yaml', help: 'pubspec.yaml path')
    ..addFlag('json', defaultsTo: false, negatable: false, help: 'emit json')
    ..addFlag('quiet', abbr: 'q', defaultsTo: false, negatable: false,
        help: 'only print packages that are behind')
    ..addFlag('help', abbr: 'h', defaultsTo: false, negatable: false);

  late ArgResults args;
  try {
    args = parser.parse(argv);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(parser.usage);
    exit(64);
  }

  if (args['help'] as bool) {
    stdout.writeln('pkgwatch — see which dart packages are behind pub.dev');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final path = args['path'] as String;
  final jsonOut = args['json'] as bool;
  final quiet = args['quiet'] as bool;

  final Pubspec spec;
  try {
    spec = await loadPubspec(path);
  } catch (e) {
    stderr.writeln('could not read $path: $e');
    exit(1);
  }

  if (spec.deps.isEmpty) {
    if (!jsonOut) stdout.writeln('no dependencies found in $path');
    exit(0);
  }

  final client = http.Client();
  final registry = Registry(client);
  if (!jsonOut && !quiet) {
    stdout.writeln('checking ${spec.deps.length} packages against pub.dev...');
  }
  final latest = await registry.latestAll(
    spec.deps.map((d) => d.name).toList(),
  );
  client.close();

  final results = <DiffResult>[];
  for (final d in spec.deps) {
    results.add(diff(d.name, d.constraint, latest[d.name]));
  }

  final behind = results.where((r) => r.behind).toList();

  if (jsonOut) {
    stdout.writeln(jsonEncode({
      'pubspec': spec.name,
      'checked': results.length,
      'updates': behind.length,
      'packages': [
        for (final r in results)
          {
            'name': r.name,
            'current': r.current,
            'latest': r.latest,
            'bump': r.bump.name,
          },
      ],
    }));
  } else {
    for (final r in results) {
      if (quiet && !r.behind) continue;
      _printRow(r);
    }
    if (behind.isEmpty) {
      if (!quiet) stdout.writeln('all good. nothing behind.');
    } else {
      stdout.writeln(
          '${behind.length} update${behind.length == 1 ? '' : 's'} available. '
          'run `dart pub upgrade` to take them.');
    }
  }

  exit(behind.isEmpty ? 0 : 2);
}

void _printRow(DiffResult r) {
  final name = r.name.padRight(20);
  final cur = (r.current ?? '?').padRight(8);
  final lat = (r.latest ?? '?').padRight(8);
  switch (r.bump) {
    case Bump.major:
      stdout.writeln('  ^ $name $cur ->  $lat major behind');
      break;
    case Bump.minor:
      stdout.writeln('  ^ $name $cur ->  $lat minor behind');
      break;
    case Bump.patch:
      stdout.writeln('  ^ $name $cur ->  $lat patch behind');
      break;
    case Bump.none:
      stdout.writeln('  . $name ${r.current ?? '?'} up to date');
      break;
    case Bump.unknown:
      stdout.writeln('  ? $name ${r.current ?? '?'} unknown');
      break;
  }
}
