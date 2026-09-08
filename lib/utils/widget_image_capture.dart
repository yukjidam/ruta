import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Snapshots an off-screen widget into PNG bytes, for registering as a
/// MapLibre style image (`controller.addImage`) so it can be shown as a
/// native Symbol instead of a screen-pixel-projected Flutter overlay.
///
/// [repaintBoundaryKey] must be the GlobalKey on a `RepaintBoundary` that
/// has already been through at least one real layout/paint pass — usually
/// achieved by building the widget off-screen (e.g. `Positioned(left:
/// -1000, top: -1000, ...)`) and calling this after the first frame, or
/// after the relevant style/controller callback fires, whichever is
/// later. Calling it before that first paint will throw, since there's
/// nothing rendered yet to capture.
///
/// [pixelRatio] should generally be the device's actual pixel ratio
/// (`MediaQuery.of(context).devicePixelRatio`) so the resulting map icon
/// isn't blurry on high-DPI screens.
Future<Uint8List> captureWidgetImage(
  GlobalKey repaintBoundaryKey, {
  required double pixelRatio,
}) async {
  final boundary = repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
