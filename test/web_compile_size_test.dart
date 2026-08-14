/// dart2js of timezone_finder.dart (not browser.dart) must not link chunks.
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'dart2js output does not link boundary chunks',
    () async {
      final fixture = File('tool/web_size_fixture/main.dart');
      expect(fixture.existsSync(), isTrue);

      final outDir = await Directory.systemTemp.createTemp('tzf_web_size_');
      addTearDown(() => outDir.deleteSync(recursive: true));
      final outJs = File('${outDir.path}/out.js');

      final result = await Process.run('dart', <String>[
        'compile',
        'js',
        '--packages=${Directory.current.path}/.dart_tool/package_config.json',
        '-O2',
        '-o',
        outJs.path,
        fixture.path,
      ]);
      expect(
        result.exitCode,
        0,
        reason: 'dart2js failed:\n${result.stdout}\n${result.stderr}',
      );

      final js = outJs.readAsStringSync();
      expect(
        js.contains('boundaries_000'),
        isFalse,
        reason: 'compiled JS must not reference base64 chunk libraries',
      );
      expect(
        js.contains("const String chunk = '"),
        isFalse,
        reason: 'compiled JS must not embed chunk string literals',
      );
      // Chunks alone are ~5.6 MB of base64. A clean build without them is well
      // under 2 MB even with the rest of the library.
      const maxBytes = 2 * 1024 * 1024;
      expect(
        js.length,
        lessThan(maxBytes),
        reason:
            'compiled JS is ${js.length} bytes — chunks likely linked '
            '(threshold $maxBytes)',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
