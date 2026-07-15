import 'dart:typed_data';
import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:convert';
import 'package:archive/archive.dart';

// --- Global EXR Configuration Constants ---
const int NO_COMPRESSION = 0;
const int ZIPS_COMPRESSION = 2;
const int ZIP_COMPRESSION = 3;

class EXRExporter {
  EXRExporter();

  /// Primary entry-point for exporting EXR high-dynamic-range files.
  /// Accepts either a DataTexture with options or a WebGLRenderer with a RenderTarget.
  Future<Uint8List> parse(dynamic arg1, [dynamic arg2, Map<String, dynamic>? arg3]) async {
    if (arg1 == null || !(arg1 is Renderer || arg1 is DataTexture)) {
      throw Exception('EXRExporter.parse: Unsupported first parameter, expected instance of WebGLRenderer or DataTexture.');
    } 
    
    // Branch A: Handling WebGLRenderer + WebGLRenderTarget workflow
    else if (arg1 is Renderer) {
      final Renderer renderer = arg1;
      if (arg2 == null || arg2 is! RenderTarget) {
        throw Exception('EXRExporter.parse: Unsupported second parameter, expected instance of WebGLRenderTarget.');
      }
      final RenderTarget renderTarget = arg2;
      final Map<String, dynamic> options = arg3 ?? {};

      _supportedRTT(renderTarget);

      final Map<String, dynamic> info = _buildInfoRTT(renderTarget, options);
      final TypedDataList dataBuffer = await _getPixelData(renderer, renderTarget, info);
      final TypedDataList rawContentBuffer = _reorganizeDataBuffer(dataBuffer, info);
      final Map<String, dynamic> chunks = _compressData(rawContentBuffer, info);

      return _fillData(chunks, info);
    } 
    
    // Branch B: Handling individual standalone DataTexture asset workflow
    else {
      final DataTexture texture = arg1;
      final Map<String, dynamic> options = (arg2 is Map<String, dynamic>) ? arg2 : {};

      _supportedDT(texture);

      final Map<String, dynamic> info = _buildInfoDT(texture, options);
      final TypedDataList dataBuffer = texture.image.data;
      final TypedDataList rawContentBuffer = _reorganizeDataBuffer(dataBuffer, info);
      final Map<String, dynamic> chunks = _compressData(rawContentBuffer, info);

      return _fillData(chunks, info);
    }
  }

  void _supportedRTT(RenderTarget renderTarget) {
    if (renderTarget is CubeRenderTarget == true) {
      throw Exception('EXRExporter.parse: Unsupported render target type, expected instance of WebGLRenderTarget.');
    }

    final int textureType = renderTarget.texture.type;
    if (textureType != FloatType && textureType != HalfFloatType) {
      throw Exception('EXRExporter.parse: Unsupported WebGLRenderTarget texture type.');
    }

    if (renderTarget.texture.format != RGBAFormat) {
      throw Exception('EXRExporter.parse: Unsupported WebGLRenderTarget texture format, expected RGBAFormat.');
    }
  }

  void _supportedDT(DataTexture texture) {
    final int textureType = texture.type;
    if (textureType != FloatType && textureType != HalfFloatType) {
      throw Exception('EXRExporter.parse: Unsupported DataTexture texture type.');
    }

    if (texture.format != RGBAFormat) {
      throw Exception('EXRExporter.parse: Unsupported DataTexture texture format, expected RGBAFormat.');
    }

    if (texture.image.data == null) {
      throw Exception('EXRExporter.parse: Invalid DataTexture image data.');
    }

    // Fix: Replaced JS constructor name matching string checks with explicit native typed checks
    if (textureType == FloatType && texture.image.data is! Float32List) {
      throw Exception("EXRExporter.parse: DataTexture image data doesn't match type, expected 'Float32List'.");
    }

    if (textureType == HalfFloatType && texture.image.data is! Uint16List) {
      throw Exception("EXRExporter.parse: DataTexture image data doesn't match type, expected 'Uint16List'.");
    }
  }

  Map<String, dynamic> _buildInfoRTT(RenderTarget renderTarget, Map<String, dynamic> options) {
    final Map<int, int> compressionSizes = {0: 1, 2: 1, 3: 16};
    
    final int width = renderTarget.width.toInt();
    final int height = renderTarget.height.toInt();
    final int type = renderTarget.texture.type;
    final int format = renderTarget.texture.format;
    
    final int compression = options['compression'] ?? ZIP_COMPRESSION;
    final int exporterType = options['type'] ?? HalfFloatType;
    final int outType = (exporterType == FloatType) ? 2 : 1;
    final int compressionSize = compressionSizes[compression] ?? 1;

    return {
      'width': width,
      'height': height,
      'type': type,
      'format': format,
      'compression': compression,
      'blockLines': compressionSize,
      'dataType': outType,
      'dataSize': 2 * outType,
      'numBlocks': (height / compressionSize).ceil(),
      'numInputChannels': 4,
      'numOutputChannels': 4,
    };
  }

  Map<String, dynamic> _buildInfoDT(DataTexture texture, Map<String, dynamic> options) {
    final Map<int, int> compressionSizes = {0: 1, 2: 1, 3: 16};
    
    final int width = texture.image.width.toInt();
    final int height = texture.image.height.toInt();
    final int type = texture.type;
    final int format = texture.format;
    
    final int compression = options['compression'] ?? ZIP_COMPRESSION;
    final int exporterType = options['type'] ?? HalfFloatType;
    final int outType = (exporterType == FloatType) ? 2 : 1;
    final int compressionSize = compressionSizes[compression] ?? 1;

    return {
      'width': width,
      'height': height,
      'type': type,
      'format': format,
      'compression': compression,
      'blockLines': compressionSize,
      'dataType': outType,
      'dataSize': 2 * outType,
      'numBlocks': (height / compressionSize).ceil(),
      'numInputChannels': 4,
      'numOutputChannels': 4,
    };
  }

  /// Fetches raw pixel arrays asynchronously from the target WebGL context layers
  Future<TypedDataList> _getPixelData(Renderer renderer, RenderTarget rtt, Map<String, dynamic> info) async {
    final int width = info['width'];
    final int height = info['height'];
    final int numInputChannels = info['numInputChannels'];
    final int totalSize = width * height * numInputChannels;
    
    TypedDataList dataBuffer;

    if (info['type'] == FloatType) {
      dataBuffer = Float32List(totalSize);
    } else {
      dataBuffer = Uint16List(totalSize);
    }

    // In three_js, pull pixels via readRenderTargetPixelsAsync
    renderer.readRenderTargetPixels(rtt, 0, 0, width, height, dataBuffer);
    return dataBuffer;
  }

  /// Reorders color channels and transforms half/full float layouts into canonical EXR scanlines
  Uint8List _reorganizeDataBuffer(TypedDataList inBuffer, Map<String, dynamic> info) {
    final int w = info['width'];
    final int h = info['height'];
    final int numOutputChannels = info['numOutputChannels'];
    final int dataSize = info['dataSize'];
    final int dataType = info['dataType'];

    final int cOffset = (numOutputChannels == 4) ? 1 : 0;
    final bool isInputFloat32 = info['type'] == FloatType;
    final bool isOutputFloat16 = dataType == 1;

    final Uint8List outBuffer = Uint8List(w * h * numOutputChannels * dataSize);
    final ByteData dv = ByteData.view(outBuffer.buffer);

    // Instantiated once inside the method to track dynamic parsing structures
    final Map<String, double> dec = {'r': 0.0, 'g': 0.0, 'b': 0.0, 'a': 0.0};
    final _OffsetWrapper offset = _OffsetWrapper(0);

    // Floating point readers/writers extracted to simple conditional bindings
    double getValue(TypedDataList buf, int index) => isInputFloat32 ? _getFloat32(buf, index) : _getFloat16(buf, index);
    void setValue(ByteData view, double val, _OffsetWrapper off) => isOutputFloat16 ? _setFloat16(view, val, off) : _setFloat32(view, val, off);

    for (int y = 0; y < h; ++y) {
      for (int x = 0; x < w; ++x) {
        final int i = y * w * 4 + x * 4;
        
        final double r = getValue(inBuffer, i);
        final double g = getValue(inBuffer, i + 1);
        final double b = getValue(inBuffer, i + 2);
        final double a = getValue(inBuffer, i + 3);

        final int line = (h - y - 1) * w * (3 + cOffset) * dataSize;
        _decodeLinear(dec, r, g, b, a);

        offset.value = line + x * dataSize;
        setValue(dv, dec['a']!, offset);

        offset.value = line + (cOffset) * w * dataSize + x * dataSize;
        setValue(dv, dec['b']!, offset);

        offset.value = line + (1 + cOffset) * w * dataSize + x * dataSize;
        setValue(dv, dec['g']!, offset);

        offset.value = line + (2 + cOffset) * w * dataSize + x * dataSize;
        setValue(dv, dec['r']!, offset);
      }
    }

    return outBuffer;
  }

  /// Dispatches raw buffers into designated chunks wrapped with EXR pipeline compressions
  Map<String, dynamic> _compressData(TypedDataList inBuffer, Map<String, dynamic> info) {
    int sum = 0;
    final List<Map<String, dynamic>> dataChunks = [];
    final int size = info['width'] * info['numOutputChannels'] * info['blockLines'] * info['dataSize'];

    Uint8List? tmpBuffer;
    if (info['compression'] != 0) {
      tmpBuffer = Uint8List(size);
    }

    for (int i = 0; i < info['numBlocks']; ++i) {
      // Replaces JS .subarray() layout tracking slices safely
      final int start = size * i;
      final int end = math.min(size * (i + 1), inBuffer.length);
      final Uint8List arr = Uint8List.sublistView(inBuffer, start, end);

      Uint8List block;
      if (info['compression'] == 0) {
        block = arr; // compressNONE
      } else {
        block = _compressZIP(arr, tmpBuffer!);
      }

      sum += block.length;
      dataChunks.add({'dataChunk': block, 'size': block.length});
    }

    return {
      'data': dataChunks,
      'totalSize': sum
    };
  }

  /// Applies interleave reordering, bitwise predictors, and pure-Dart Zlib/Deflate compression blocks
  Uint8List _compressZIP(Uint8List data, Uint8List tmpBuffer) {
    // 1. Reorder the pixel data bytes
    int t1 = 0;
    int t2 = ((data.length + 1) / 2).floor();
    int s = 0;
    final int stop = data.length - 1;

    while (true) {
      if (s > stop) break;
      tmpBuffer[t1++] = data[s++];
      if (s > stop) break;
      tmpBuffer[t2++] = data[s++];
    }

    // 2. High density predictor transform loop
    int p = tmpBuffer[0];
    for (int t = 1; t < tmpBuffer.length; t++) {
      final int d = tmpBuffer[t] - p + (128 + 256);
      p = tmpBuffer[t];
      tmpBuffer[t] = d & 0xFF; // Constrain mathematically to explicit 8-bit unsigned boundaries
    }

    // 3. Replaces fflate.zlibSync using standard pure Dart package:archive encoder tools
    final List<int> compressed = ZLibEncoder().encode(tmpBuffer);
    return Uint8List.fromList(compressed);
  }

  double _getFloat32(TypedData buffer, int index) {
    if (buffer is Float32List) return buffer[index];
    if (buffer is Uint16List) return HalfFloatUtils.fromHalfFloat(buffer[index]);
    return 0.0;
  }

  void _setFloat16(ByteData dv, double val, _OffsetWrapper offset) {
    // Leverage three_js DataUtils half-float conversions natively
    final int half = HalfFloatUtils.toHalfFloat(val);
    dv.setUint16(offset.value, half, Endian.little);
  }

  void _decodeLinear(Map<String, double> dec, double r, double g, double b, double a) {
    dec['r'] = r;
    dec['g'] = g;
    dec['b'] = b;
    dec['a'] = a;
  }


  void _fillHeader(Uint8List outBuffer, Map<String, dynamic> chunks, Map<String, dynamic> info) {
    final _OffsetWrapper offset = _OffsetWrapper(0);
    final ByteData dv = ByteData.view(outBuffer.buffer);

    _setUint32(dv, 20000630, offset); // Magic number
    _setUint32(dv, 2, offset);        // Layout single part mask version

    // === HEADER ATTRIBUTES ===
    _setString(dv, 'compression', offset);
    _setString(dv, 'compression', offset);
    _setUint32(dv, 1, offset);
    _setUint8(dv, info['compression'], offset);

    _setString(dv, 'screenWindowCenter', offset);
    _setString(dv, 'v2f', offset);
    _setUint32(dv, 8, offset);
    _setUint32(dv, 0, offset);
    _setUint32(dv, 0, offset);

    _setString(dv, 'screenWindowWidth', offset);
    _setString(dv, 'float', offset);
    _setUint32(dv, 4, offset);
    _setFloat32(dv, 1.0, offset);

    _setString(dv, 'pixelAspectRatio', offset);
    _setString(dv, 'float', offset);
    _setUint32(dv, 4, offset);
    _setFloat32(dv, 1.0, offset);

    _setString(dv, 'lineOrder', offset);
    _setString(dv, 'lineOrder', offset);
    _setUint32(dv, 1, offset);
    _setUint8(dv, 0, offset);

    _setString(dv, 'dataWindow', offset);
    _setString(dv, 'box2i', offset);
    _setUint32(dv, 16, offset);
    _setUint32(dv, 0, offset);
    _setUint32(dv, 0, offset);
    _setUint32(dv, info['width'] - 1, offset);
    _setUint32(dv, info['height'] - 1, offset);

    _setString(dv, 'displayWindow', offset);
    _setString(dv, 'box2i', offset);
    _setUint32(dv, 16, offset);
    _setUint32(dv, 0, offset);
    _setUint32(dv, 0, offset);
    _setUint32(dv, info['width'] - 1, offset);
    _setUint32(dv, info['height'] - 1, offset);

    _setString(dv, 'channels', offset);
    _setString(dv, 'chlist', offset);
    _setUint32(dv, (info['numOutputChannels'] as int) * 18 + 1, offset);

    // Define active output channels sequentially
    _setString(dv, 'A', offset);
    _setUint32(dv, info['dataType'], offset);
    offset.value += 4;
    _setUint32(dv, 1, offset);
    _setUint32(dv, 1, offset);

    _setString(dv, 'B', offset);
    _setUint32(dv, info['dataType'], offset);
    offset.value += 4;
    _setUint32(dv, 1, offset);
    _setUint32(dv, 1, offset);

    _setString(dv, 'G', offset);
    _setUint32(dv, info['dataType'], offset);
    offset.value += 4;
    _setUint32(dv, 1, offset);
    _setUint32(dv, 1, offset);

    _setString(dv, 'R', offset);
    _setUint32(dv, info['dataType'], offset);
    offset.value += 4;
    _setUint32(dv, 1, offset);
    _setUint32(dv, 1, offset);

    _setUint8(dv, 0, offset); // Null terminator byte for attribute list string block
    _setUint8(dv, 0, offset); // Null terminator byte for complete header packet block

    // === EXR CHUNK SCANLINE OFFSET TABLE ===
    final List chunksDataList = chunks['data'];
    int sum = offset.value + (info['numBlocks'] as int) * 8;

    for (int i = 0; i < chunksDataList.length; ++i) {
      _setUint64(dv, sum, offset);
      sum += (chunksDataList[i]['size'] as int) + 8;
    }
  }

  /// Packs generated binary chunk streams flush alongside their OpenEXR data layout descriptor headers
  Uint8List _fillData(Map<String, dynamic> chunks, Map<String, dynamic> info) {
    final int numBlocks = info['numBlocks'];
    final int numOutputChannels = info['numOutputChannels'];
    final int blockLines = info['blockLines'];
    final int totalSize = chunks['totalSize'];

    final int tableSize = numBlocks * 8;
    final int headerSize = 259 + (18 * numOutputChannels);

    final _OffsetWrapper offset = _OffsetWrapper(headerSize + tableSize);
    final int outputBufferAllocationSize = headerSize + tableSize + totalSize + (numBlocks * 8);

    final Uint8List outBuffer = Uint8List(outputBufferAllocationSize);
    final ByteData dv = ByteData.view(outBuffer.buffer);

    // 1. Compile file descriptions and structural location indices
    _fillHeader(outBuffer, chunks, info);

    // 2. Map blocks sequentially out to the destination byte layout array
    final List chunksDataList = chunks['data'];
    for (int i = 0; i < chunksDataList.length; ++i) {
      final Uint8List data = chunksDataList[i]['dataChunk'];
      final int size = chunksDataList[i]['size'];

      _setUint32(dv, i * blockLines, offset);
      _setUint32(dv, size, offset);

      // Replaces JavaScript's outBuffer.set(data, offset.value) cleanly in memory
      outBuffer.setRange(offset.value, offset.value + size, data);
      offset.value += size;
    }

    return outBuffer;
  }

  // --- Binary Parsing Setter Hooks (Modifies ByteData Stream Elements) ---

  void _setUint8(ByteData dv, int value, _OffsetWrapper offset) {
    dv.setUint8(offset.value, value);
    offset.value += 1;
  }

  void _setUint32(ByteData dv, int value, _OffsetWrapper offset) {
    dv.setUint32(offset.value, value, Endian.little);
    offset.value += 4;
  }

  void _setFloat32(ByteData dv, double value, _OffsetWrapper offset) {
    dv.setFloat32(offset.value, value, Endian.little);
    offset.value += 4;
  }

  void _setUint64(ByteData dv, int value, _OffsetWrapper offset) {
    // Dart supports native 64-bit integer values out of the box
    dv.setUint64(offset.value, value, Endian.little);
    offset.value += 8;
  }

  void _setString(ByteData dv, String string, _OffsetWrapper offset) {
    // Convert standard character maps cleanly using local utf8 codecs
    final List<int> encodedBytes = utf8.encode('$string\x00');
    for (int i = 0; i < encodedBytes.length; ++i) {
      _setUint8(dv, encodedBytes[i], offset);
    }
  }

  // --- Dynamic Numeric Reading Parsers ---

  double _decodeFloat16(int binary) {
    final int exponent = (binary & 0x7C00) >> 10;
    final int fraction = binary & 0x03FF;
    
    if (binary >> 15 != 0) { // Sign Bit Check
      if (exponent == 0x1F) {
        return fraction != 0 ? double.nan : double.negativeInfinity;
      }
      return -(exponent != 0 ? math.pow(2, exponent - 15) * (1 + fraction / 0x400) : 6.103515625e-5 * (fraction / 0x400));
    } else {
      if (exponent == 0x1F) {
        return fraction != 0 ? double.nan : double.infinity;
      }
      return exponent != 0 ? math.pow(2, exponent - 15) * (1 + fraction / 0x400) : 6.103515625e-5 * (fraction / 0x400);
    }
  }

  double _getFloat16(TypedDataList arr, int i) {
    return _decodeFloat16(arr[i]);
  }
}

class _OffsetWrapper {
  int value;
  _OffsetWrapper(this.value);
}

class HalfFloatUtils {
  static final Float32List _floatView = Float32List(1);
  static final Int32List _intView = Int32List.view(_floatView.buffer);

  /// Converts a standard Dart double (32-bit single precision) to a 16-bit half-precision float integer.
  static int toHalfFloat(double value) {
    _floatView[0] = value;
    int f = _intView[0];

    int sign = (f >> 16) & 0x8000;
    int exponent = ((f >> 23) & 0xFF) - 127;
    int mantissa = f & 0x007FFFFF;

    if (exponent == 128) { // NaN or Infinity
      return sign | 0x7C00 | (mantissa != 0 ? 1 : 0);
    }
    if (exponent > 15) { // Overflow -> Infinity
      return sign | 0x7C00;
    }
    if (exponent > -15) { // Normalized value
      return sign | ((exponent + 15) << 10) | (mantissa >> 13);
    }
    if (exponent > -25) { // Denormalized value
      mantissa |= 0x00800000;
      return sign | (mantissa >> (-14 - exponent));
    }
    
    return sign; // Underflow -> Zero
  }

  /// Converts a 16-bit half-precision float integer back into a standard Dart double.
  static double fromHalfFloat(int half) {
    int sign = (half & 0x8000) << 16;
    int exponent = (half & 0x7C00) >> 10;
    int mantissa = half & 0x03FF;

    if (exponent == 0x1F) { // NaN or Infinity
      _intView[0] = sign | 0x7F800000 | (mantissa << 13);
      return _floatView[0];
    }
    if (exponent == 0) {
      if (mantissa == 0) { // Plus/Minus Zero
        _intView[0] = sign;
        return _floatView[0];
      }
      // Denormalized values
      while ((mantissa & 0x0400) == 0) {
        mantissa <<= 1;
        exponent -= 1;
      }
      exponent += 1;
      mantissa &= ~0x0400;
    }

    _intView[0] = sign | ((exponent + 112) << 23) | (mantissa << 13);
    return _floatView[0];
  }
}
