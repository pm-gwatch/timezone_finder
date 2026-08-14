/// The one decoded container this isolate uses, and how it got there.
///
/// Knows nothing about coordinates, quantization or `package:timezone`.
library;

import 'dart:typed_data';

import 'boundary_index.dart';
import 'load_container.dart'
    if (dart.library.js_interop) 'load_container_web.dart'
    as container;

BoundaryIndex? _installed;
int _decodes = 0;

/// Installs packed boundary bytes as the isolate-wide shared index.
///
/// Primary web API — reach it through `package:timezone_finder/browser.dart`.
/// Corrupt bytes throw [IndexFormatException]. Same
/// [BoundaryIndex.dataVersion] again still validates and counts, but does not
/// replace the index.
void installBoundaries(Uint8List bytes) {
  final index = decodeIndex(() => bytes);
  final existing = _installed;
  if (existing != null && existing.dataVersion == index.dataVersion) {
    return;
  }
  _installed = index;
}

/// Isolate-wide index: installed `.bin`, or VM chunks via load_container.
///
/// On web, throws until [installBoundaries] has run.
BoundaryIndex get sharedIndex {
  final existing = _installed;
  if (existing != null) return existing;
  installBoundaries(container.loadContainer());
  return _installed!;
}

/// Decodes [bytes] and bumps [indexDecodeCount].
///
/// Every store parse routes through here so the counter cannot be bypassed.
BoundaryIndex decodeIndex(Uint8List Function() bytes) {
  _decodes++;
  return BoundaryIndex.fromBytes(bytes());
}

/// How many indexes this isolate has decoded. Test-only.
int get indexDecodeCount => _decodes;
