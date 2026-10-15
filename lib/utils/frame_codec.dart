import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

class FrameCodec {
  static Uint8List encode(String data) {
    final bytes = utf8.encode(data);
    final frame = Uint8List(4 + bytes.length);
    final buffer = ByteData.sublistView(frame);
    buffer.setUint32(0, bytes.length, Endian.little);
    frame.setRange(4, frame.length, bytes);
    return frame;
  }
}

class FrameDecoder {
  final BytesBuilder _builder = BytesBuilder();

  List<String> decode(Uint8List data) {
    final results = <String>[];
    _builder.add(data);

    final Uint8List buffer = _builder.takeBytes();
    int offset = 0;

    try {
      while (buffer.length - offset >= 4) {
        final view = ByteData.view(buffer.buffer, buffer.offsetInBytes + offset, 4);
        final length = view.getUint32(0, Endian.little);

        if (length > 10 * 1024 * 1024 || length < 0) {
          throw FormatException('Invalid or too large frame length: $length');
        }

        if (buffer.length - offset < 4 + length) {
          break;
        }

        final frame = Uint8List.view(
          buffer.buffer,
          buffer.offsetInBytes + offset + 4,
          length,
        );
        results.add(utf8.decode(frame));
        offset += 4 + length;
      }

      if (offset < buffer.length) {
        _builder.add(Uint8List.view(
          buffer.buffer,
          buffer.offsetInBytes + offset,
          buffer.length - offset,
        ));
      }
    } catch (e) {
      _builder.clear();
      rethrow;
    }

    return results;
  }

  void reset() {
    _builder.clear();
  }
}

class FrameDecoderTransformer extends StreamTransformerBase<Uint8List, String> {
  @override
  Stream<String> bind(Stream<Uint8List> stream) {
    final decoder = FrameDecoder();
    return stream.expand((data) => decoder.decode(data));
  }
}
