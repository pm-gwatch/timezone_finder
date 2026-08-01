/// Downloading and caching of timezone-boundary-builder release data.
///
/// The source GeoJSON is ~51 MB compressed and ~170 MB expanded, so it is
/// never committed. It is cached under `.dart_tool/`, which is gitignored and
/// is the conventional place for tool-generated artifacts.
///
/// This is used by the reference oracle in `test/reference/` and
/// by `tool/refresh.dart`. Nothing under `lib/` may import it.
library;

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;

/// The tzbb release this package currently targets.
const String defaultRelease = '2026c';

/// The land-only, full-fidelity release asset. See the README for why this
/// variant rather than `with-oceans` or the `1970`/`now` merges.
const String _assetName = 'timezones.geojson.zip';

/// The single file inside [_assetName].
const String _memberName = 'combined.json';

/// Sanity bounds on the download, so a truncated transfer or an HTML error
/// page cannot silently become the oracle's ground truth.
const int _minPlausibleZipBytes = 40 * 1024 * 1024;
const int _minPlausibleJsonBytes = 120 * 1024 * 1024;

/// Where [release]'s expanded GeoJSON lives once fetched.
///
/// Pure path computation — performs no I/O, so tests can call it to decide
/// whether to skip.
File cachedGeoJsonFile(String release, {Directory? packageRoot}) {
  final root = packageRoot ?? Directory.current;
  return File(
    '${root.path}/.dart_tool/timezone_finder/tzbb-$release/$_memberName',
  );
}

/// The URL of the release asset for [release].
Uri releaseAssetUrl(String release) => Uri.https(
  'github.com',
  '/evansiroky/timezone-boundary-builder/releases/download/'
      '$release/$_assetName',
);

/// Ensures [release]'s GeoJSON is present in the cache, downloading it if not.
///
/// Returns the cached file. Idempotent: a second call with the data already
/// cached performs no network access.
Future<File> ensureGeoJson({
  String release = defaultRelease,
  Directory? packageRoot,
  void Function(String message)? log,
}) async {
  final report = log ?? (_) {};
  final target = cachedGeoJsonFile(release, packageRoot: packageRoot);

  if (await target.exists()) {
    final size = await target.length();
    if (size >= _minPlausibleJsonBytes) {
      report('Using cached ${target.path} (${_mb(size)}).');
      return target;
    }
    report('Cached file is implausibly small (${_mb(size)}); refetching.');
    await target.delete();
  }

  await target.parent.create(recursive: true);
  final zipFile = File('${target.parent.path}/$_assetName');

  final url = releaseAssetUrl(release);
  report('Downloading $url …');
  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw StateError('Download failed: HTTP ${response.statusCode} for $url');
  }
  final bytes = response.bodyBytes;
  if (bytes.length < _minPlausibleZipBytes) {
    throw StateError(
      'Downloaded ${_mb(bytes.length)} from $url, which is far smaller than '
      'the expected ~51 MB. Refusing to use it as ground truth.',
    );
  }
  await zipFile.writeAsBytes(bytes, flush: true);
  report('Downloaded ${_mb(bytes.length)}.');

  report('Extracting $_memberName …');
  final input = InputFileStream(zipFile.path);
  try {
    final archive = ZipDecoder().decodeStream(input);
    final member = archive.files
        .where((f) => f.name == _memberName)
        .firstOrNull;
    if (member == null) {
      throw StateError(
        'Archive from $url does not contain $_memberName. '
        'Found: ${archive.files.map((f) => f.name).join(', ')}',
      );
    }
    final output = OutputFileStream(target.path);
    try {
      member.writeContent(output);
    } finally {
      await output.close();
    }
  } finally {
    await input.close();
  }
  await zipFile.delete();

  final size = await target.length();
  if (size < _minPlausibleJsonBytes) {
    await target.delete();
    throw StateError(
      'Extracted only ${_mb(size)}, expected ~170 MB. Cache not written.',
    );
  }
  report('Cached ${target.path} (${_mb(size)}).');
  return target;
}

String _mb(int bytes) => '${(bytes / 1e6).toStringAsFixed(1)} MB';
