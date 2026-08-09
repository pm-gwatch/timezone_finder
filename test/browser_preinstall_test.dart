/// Chrome behaviour *before* boundaries are installed.
///
///     dart test -p chrome test/browser_preinstall_test.dart
///
/// Deliberately its own suite: `browser_parity_test` installs in `setUpAll`,
/// so the uninstalled state it leaves behind is unobservable there. The shared
/// index is per-isolate, and each test file is its own isolate, so nothing
/// here may install — the first install would make every later test vacuous.
@TestOn('chrome')
library;

import 'package:test/test.dart';
import 'package:timezone_finder/browser.dart';
import 'package:timezone_finder/src/finder.dart' show findLocationName;

void main() {
  test('a lookup before install throws, naming the fix', () {
    // embedded_web.dart throws this: on web the base64 chunks are not linked,
    // so there is nothing to fall back to. The message is the only thing
    // standing between a developer and a blank page.
    expect(
      () => findLocationName(2.3522, 48.8566),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('installBoundaries'), contains('browser.dart')),
        ),
      ),
    );
  });

  test('ensurePreloaded before install throws the same way', () {
    // Documented as failing exactly like a lookup. It is the call a server or
    // app makes at startup, so it must not appear to succeed and defer the
    // failure to the first real request.
    expect(ensurePreloaded(), throwsA(isA<StateError>()));
  });

  test('ianaDatabaseVersion before install throws rather than guessing', () {
    expect(() => ianaDatabaseVersion, throwsA(isA<StateError>()));
  });
}
