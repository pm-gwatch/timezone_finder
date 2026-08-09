/// Fetches boundary bytes on web via `package:web`.
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

import 'boundaries_bin.dart';
import 'install.dart';

/// Fetches the packed index from [url] and installs it.
///
/// The length check below is deliberate and strict: a host that answers
/// `packages/…` with an HTML 404 returns a 200 with a body, and without this
/// the page would reach the container decoder as garbage. `browser.dart`
/// documents the constraint it places on a self-hosted [url].
Future<void> initializeBoundaries([String url = boundariesDefaultUrl]) async {
  try {
    final response = await window.fetch(url.toJS).toDart;
    if (!response.ok) {
      throw BoundariesInitException(
        'Request failed with status: ${response.status}',
      );
    }
    final jsBytes = await response.bytes().toDart;
    final bytes = Uint8List.fromList(jsBytes.toDart);
    if (bytes.length != boundariesBinLength) {
      throw BoundariesInitException(
        'Fetched ${bytes.length} bytes from $url, expected '
        '$boundariesBinLength ($boundariesBinName)',
      );
    }
    installBoundaries(bytes);
  } on BoundariesInitException {
    rethrow;
  } on IndexFormatException {
    rethrow;
  } catch (e) {
    throw BoundariesInitException(e.toString());
  }
}
