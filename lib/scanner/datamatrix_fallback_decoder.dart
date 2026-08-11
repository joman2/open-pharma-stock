import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

const MethodChannel _channel = MethodChannel('datamatrix_fallback_decoder');

const int _upscaleFactor = 4;
const double _padRatio = 0.15;
const int _blurRadius = 2;

Future<List<Uint8List>?> preprocessForDataMatrix(Uint8List bytes, {Rect? roi}) {
  final roiData = roi == null
      ? null
      : <double>[roi.left, roi.top, roi.right, roi.bottom];
  return Isolate.run(() {
    return _preprocessVariantsToPng(bytes, roiData: roiData);
  });
}

Future<String?> decodePreprocessedOnAndroid(
  Uint8List preprocessedPngBytes, {
  required int variant,
}) async {
  try {
    final result = await _channel.invokeMethod<String>(
      'decode',
      <String, Object>{'imageBytes': preprocessedPngBytes, 'variant': variant},
    );
    if (result == null || result.isEmpty) {
      return null;
    }
    return result;
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}

Future<String?> decodeDataMatrixFallback(Uint8List bytes, {Rect? roi}) async {
  _debugLog('[FALLBACK] variants pipeline active');
  final variants = await preprocessForDataMatrix(bytes, roi: roi);
  if (variants == null || variants.isEmpty) {
    return null;
  }
  for (var i = 0; i < variants.length; i++) {
    _debugLog('[FALLBACK_TRY] variant=$i bytes=${variants[i].length}');
    final result = await decodePreprocessedOnAndroid(variants[i], variant: i);
    if (result != null && result.isNotEmpty) {
      _debugLog('[FALLBACK_OK] variant=$i len=${result.length}');
      return result;
    }
  }
  _debugLog('[FALLBACK_FAIL_ALL]');
  return null;
}

void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

List<Uint8List>? _preprocessVariantsToPng(
  Uint8List bytes, {
  required List<double>? roiData,
}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return null;
  }

  final roi = _resolveRoi(roiData, decoded.width, decoded.height);
  final cropped = roi == null
      ? decoded
      : img.copyCrop(decoded, roi.x, roi.y, roi.width, roi.height);

  final gray = img.grayscale(cropped);
  final variantA = _upscaleAndPad(gray);
  final variantB = _upscaleAndPad(img.invert(gray.clone()));

  final blurred = img.gaussianBlur(gray.clone(), _blurRadius);
  final variantC = _upscaleAndPad(blurred);
  final variantD = _upscaleAndPad(img.invert(blurred.clone()));

  return <Uint8List>[
    _encodePng(variantA),
    _encodePng(variantB),
    _encodePng(variantC),
    _encodePng(variantD),
  ];
}

img.Image _upscaleAndPad(img.Image input) {
  final scaled = img.copyResize(
    input,
    width: input.width * _upscaleFactor,
    height: input.height * _upscaleFactor,
    interpolation: img.Interpolation.nearest,
  );
  final pad = (math.min(scaled.width, scaled.height) * _padRatio).round();
  final padded = img.Image(scaled.width + pad * 2, scaled.height + pad * 2);
  img.fill(padded, img.getColor(255, 255, 255));
  img.copyInto(padded, scaled, dstX: pad, dstY: pad);
  return padded;
}

Uint8List _encodePng(img.Image image) {
  return Uint8List.fromList(img.encodePng(image));
}

_Roi? _resolveRoi(List<double>? roiData, int width, int height) {
  if (roiData == null || roiData.length != 4) {
    return null;
  }
  final raw = Rect.fromLTRB(roiData[0], roiData[1], roiData[2], roiData[3]);
  final isNormalized = raw.right <= 1.0 && raw.bottom <= 1.0;
  final left = isNormalized ? raw.left * width : raw.left;
  final top = isNormalized ? raw.top * height : raw.top;
  final right = isNormalized ? raw.right * width : raw.right;
  final bottom = isNormalized ? raw.bottom * height : raw.bottom;

  var x = left.floor();
  var y = top.floor();
  var w = (right - left).ceil();
  var h = (bottom - top).ceil();

  if (w <= 0 || h <= 0) {
    return null;
  }

  if (x < 0) {
    w += x;
    x = 0;
  }
  if (y < 0) {
    h += y;
    y = 0;
  }
  if (x >= width || y >= height) {
    return null;
  }

  if (x + w > width) {
    w = width - x;
  }
  if (y + h > height) {
    h = height - y;
  }
  if (w <= 0 || h <= 0) {
    return null;
  }
  return _Roi(x, y, w, h);
}

class _Roi {
  const _Roi(this.x, this.y, this.width, this.height);

  final int x;
  final int y;
  final int width;
  final int height;
}
