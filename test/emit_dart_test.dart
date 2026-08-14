// Dart-source emitter. Chunk boundaries on 4-char base64 groups. Synthetic
// container; no boundary data.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import '../tool/src/emit_dart.dart';

Directory _scratch() =>
    Directory.systemTemp.createTempSync('timezone_finder_emit');

Uint8List _container(int length) =>
    Uint8List.fromList(<int>[for (var i = 0; i < length; i++) (i * 31) & 0xff]);

void main() {
  group('emitDartData', () {
    test('rejects a chunk size that would break per-chunk decoding', () {
      // base64 packs three bytes into four characters, so a boundary off a
      // four-character group cannot be decoded alone — which would force the
      // loader back to joining every chunk into one enormous string, the
      // 37.5 MB intermediate that cost a quarter of peak memory.
      final directory = _scratch();
      addTearDown(() => directory.deleteSync(recursive: true));
      // Every one of these leaves a remainder mod 4. (100 does not, which
      // this test asserted until it failed.)
      for (final bad in <int>[1, 2, 3, 5, 6, 7, 101, 1023]) {
        expect(
          () => emitDartData(
            directory: directory,
            name: 'probe',
            container: _container(600),
            dataVersion: '2026c',
            chunkBase64Chars: bad,
          ),
          throwsArgumentError,
          reason: '$bad is not a multiple of 4',
        );
      }
    });

    test('every emitted chunk decodes on its own', () {
      // The property the guard exists to protect, asserted directly rather
      // than inferred from the guard's presence.
      final directory = _scratch();
      addTearDown(() => directory.deleteSync(recursive: true));
      final container = _container(5000);
      final result = emitDartData(
        directory: directory,
        name: 'probe',
        container: container,
        dataVersion: '2026c',
        chunkBase64Chars: 64,
      );
      expect(result.chunks, greaterThan(1));

      final rebuilt = BytesBuilder();
      for (var i = 0; i < result.chunks; i++) {
        final source = File(
          '${directory.path}/probe_${i.toString().padLeft(3, '0')}.dart',
        ).readAsStringSync();
        final literal = RegExp(
          r"const String chunk = '([^']*)';",
        ).firstMatch(source)!.group(1)!;
        rebuilt.add(base64.decode(literal));
      }
      expect(rebuilt.toBytes(), container);
    });

    test('generated files carry the ODbL notice', () {
      // Required by the licence, and easy to lose in a refactor of the
      // emitter — at which point every generated file loses it at once.
      final directory = _scratch();
      addTearDown(() => directory.deleteSync(recursive: true));
      emitDartData(
        directory: directory,
        name: 'probe',
        container: _container(600),
        dataVersion: '2026c',
        chunkBase64Chars: 64,
      );
      final files = directory.listSync().whereType<File>();
      expect(files, isNotEmpty);
      for (final file in files) {
        final text = file.readAsStringSync();
        expect(
          text,
          contains('Open Database License'),
          reason: '${file.path} has no ODbL notice',
        );
        expect(text, contains('GENERATED FILE'));
      }
    });

    test('does not delete another emit whose name it prefixes', () {
      // `boundaries` is a prefix of `boundaries_unsimplified`. A substring
      // test for stale files had the shorter emit delete every chunk of the
      // longer one, which is how 36 generated files disappeared silently.
      final directory = _scratch();
      addTearDown(() => directory.deleteSync(recursive: true));
      emitDartData(
        directory: directory,
        name: 'boundaries_unsimplified',
        container: _container(4000),
        dataVersion: '2026c',
        chunkBase64Chars: 64,
      );
      final before = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('boundaries_unsimplified'))
          .length;
      expect(before, greaterThan(1));

      emitDartData(
        directory: directory,
        name: 'boundaries',
        container: _container(400),
        dataVersion: '2026c',
        chunkBase64Chars: 64,
      );
      final after = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('boundaries_unsimplified'))
          .length;
      expect(after, before, reason: 'the shorter emit deleted the longer one');
    });

    test('replaces stale chunks rather than leaving them behind', () {
      // A release with fewer chunks than the last must not leave the extra
      // files on disk, or the loader would read a container spliced from two
      // different datasets.
      final directory = _scratch();
      addTearDown(() => directory.deleteSync(recursive: true));
      final many = emitDartData(
        directory: directory,
        name: 'probe',
        container: _container(4000),
        dataVersion: '2026c',
        chunkBase64Chars: 64,
      );
      final few = emitDartData(
        directory: directory,
        name: 'probe',
        container: _container(400),
        dataVersion: '2026c',
        chunkBase64Chars: 64,
      );
      expect(few.chunks, lessThan(many.chunks));
      final chunkFiles = directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('probe_'))
          .length;
      expect(chunkFiles, few.chunks, reason: 'stale chunk files remain');
    });
  });
}
