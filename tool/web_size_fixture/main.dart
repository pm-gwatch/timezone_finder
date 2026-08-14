/// Minimal web entry used by [web_compile_size_test].
///
/// Imports the default library only — if base64 chunks leak onto the web
/// graph, dart2js output balloons and the size test fails.
library;

import 'package:timezone_finder/timezone_finder.dart';

void main() {
  // Touch the public API so the linker keeps the library. Lookups throw
  // StateError until installBoundaries runs; that is expected here.
  print(findLocation);
  print(ensurePreloaded);
  print(boundaryDataVersion);
}
