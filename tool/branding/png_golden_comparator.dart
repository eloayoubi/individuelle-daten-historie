import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Golden-Vergleich wie [LocalFileComparator], schreibt bei `--update-goldens` aber PNGs ohne
/// Alphakanal, sobald das Bild voll deckend ist: Der App Store lehnt das 1024er-Icon mit Alpha ab,
/// und Screenshots sollen „flattened“ sein. Bilder mit Transparenz (Adaptive-Icon-Vordergrund,
/// Splash-Logo) bleiben RGBA.
///
/// Einbinden im Test: `useOpaquePngGoldens();` am Anfang von `main()`.
class OpaquePngGoldenComparator extends LocalFileComparator {
  OpaquePngGoldenComparator(super.testFile);

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final file = File.fromUri(basedir.resolveUri(golden));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(await reencodePng(imageBytes), flush: true);
  }
}

/// Ersetzt den Standard-Vergleich durch [OpaquePngGoldenComparator] mit demselben Ordner.
void useOpaquePngGoldens() {
  final current = goldenFileComparator;
  if (current is LocalFileComparator && current is! OpaquePngGoldenComparator) {
    goldenFileComparator = OpaquePngGoldenComparator(current.basedir.resolve('golden_test.dart'));
  }
}

/// Liest ein PNG und schreibt es neu: RGB bei voll deckenden Bildern, sonst RGBA.
Future<Uint8List> reencodePng(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
  final bytes = encodePng(data!.buffer.asUint8List(), image.width, image.height);
  image.dispose();
  codec.dispose();
  return bytes;
}

/// Minimaler PNG-Encoder (8 Bit, RGB oder RGBA, Zeilenfilter je Zeile nach kleinster Summe).
Uint8List encodePng(Uint8List rgba, int width, int height) {
  var opaque = true;
  for (var i = 3; i < rgba.length; i += 4) {
    if (rgba[i] != 255) {
      opaque = false;
      break;
    }
  }
  final bpp = opaque ? 3 : 4;
  final stride = width * bpp;
  final raw = Uint8List(height * (stride + 1));
  var previous = Uint8List(stride);
  var current = Uint8List(stride);
  final filtered = List.generate(5, (_) => Uint8List(stride));

  for (var y = 0; y < height; y++) {
    for (var x = 0, s = y * width * 4, d = 0; x < width; x++, s += 4, d += bpp) {
      current[d] = rgba[s];
      current[d + 1] = rgba[s + 1];
      current[d + 2] = rgba[s + 2];
      if (!opaque) current[d + 3] = rgba[s + 3];
    }
    var best = 0;
    var bestScore = -1;
    for (var f = 0; f < 5; f++) {
      final out = filtered[f];
      var score = 0;
      for (var i = 0; i < stride; i++) {
        final a = i >= bpp ? current[i - bpp] : 0;
        final b = previous[i];
        final c = i >= bpp ? previous[i - bpp] : 0;
        final predictor = switch (f) {
          0 => 0,
          1 => a,
          2 => b,
          3 => (a + b) >> 1,
          _ => _paeth(a, b, c),
        };
        final v = (current[i] - predictor) & 0xFF;
        out[i] = v;
        score += v < 128 ? v : 256 - v;
      }
      if (bestScore < 0 || score < bestScore) {
        best = f;
        bestScore = score;
      }
    }
    final offset = y * (stride + 1);
    raw[offset] = best;
    raw.setRange(offset + 1, offset + 1 + stride, filtered[best]);
    final swap = previous;
    previous = current;
    current = swap;
  }

  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, opaque ? 2 : 6);
  final out = BytesBuilder(copy: false)
    ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    ..add(_chunk('IHDR', header.buffer.asUint8List()))
    // sRGB, Wiedergabe „perceptual“ – so liest jedes Programm die Farben wie Flutter sie zeichnet.
    ..add(_chunk('sRGB', Uint8List.fromList(const [0])))
    ..add(_chunk('IDAT', Uint8List.fromList(ZLibCodec(level: 9).encode(raw))))
    ..add(_chunk('IEND', Uint8List(0)));
  return out.takeBytes();
}

int _paeth(int a, int b, int c) {
  final p = a + b - c;
  final pa = (p - a).abs(), pb = (p - b).abs(), pc = (p - c).abs();
  if (pa <= pb && pa <= pc) return a;
  return pb <= pc ? b : c;
}

Uint8List _chunk(String type, Uint8List data) {
  final typeBytes = Uint8List.fromList(type.codeUnits);
  final chunk = ByteData(12 + data.length)..setUint32(0, data.length);
  final bytes = chunk.buffer.asUint8List()
    ..setRange(4, 8, typeBytes)
    ..setRange(8, 8 + data.length, data);
  chunk.setUint32(8 + data.length, _crc32(bytes, 4, 8 + data.length));
  return bytes;
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(Uint8List bytes, int start, int end) {
  var crc = 0xFFFFFFFF;
  for (var i = start; i < end; i++) {
    crc = _crcTable[(crc ^ bytes[i]) & 0xFF] ^ (crc >> 8);
  }
  return crc ^ 0xFFFFFFFF;
}
