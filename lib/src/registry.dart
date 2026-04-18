import 'dart:convert';
import 'package:http/http.dart' as http;

/// fetches the latest version string for a package from pub.dev.
/// returns null if the package doesn't exist or the response is weird.
class Registry {
  final http.Client client;
  final Uri Function(String name) urlFor;

  Registry(this.client, {Uri Function(String)? urlFor})
      : urlFor = urlFor ?? _defaultUrl;

  static Uri _defaultUrl(String name) =>
      Uri.parse('https://pub.dev/api/packages/$name');

  Future<String?> latestVersion(String name) async {
    final resp = await client.get(urlFor(name), headers: {
      'Accept': 'application/vnd.pub.v2+json',
    });
    if (resp.statusCode != 200) return null;
    final body = jsonDecode(resp.body);
    if (body is! Map) return null;
    final latest = body['latest'];
    if (latest is! Map) return null;
    final ver = latest['version'];
    return ver is String ? ver : null;
  }

  /// run fetches in parallel with a small pool to keep pub.dev happy.
  Future<Map<String, String?>> latestAll(List<String> names,
      {int poolSize = 8}) async {
    final out = <String, String?>{};
    var i = 0;
    Future<void> worker() async {
      while (true) {
        final idx = i++;
        if (idx >= names.length) return;
        final n = names[idx];
        try {
          out[n] = await latestVersion(n);
        } catch (_) {
          out[n] = null;
        }
      }
    }

    final workers = List.generate(
      poolSize.clamp(1, names.isEmpty ? 1 : names.length),
      (_) => worker(),
    );
    await Future.wait(workers);
    return out;
  }
}
