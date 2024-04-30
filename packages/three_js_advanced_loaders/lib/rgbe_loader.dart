import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'data_texture_loader.dart';
import 'dart:math' as math;

// https://github.com/mrdoob/three.js/issues/5552
// http://en.wikipedia.org/wiki/RGBE_image_format

class RGBELoader extends DataTextureLoader {
  late final FileLoader _loader;
  int type = HalfFloatType;

  RGBELoader([super.manager]){
    _loader = FileLoader(manager);
  }

  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
  }
  
  void _init(){
    _loader.setResponseType('arraybuffer');
    _loader.setRequestHeader(requestHeader);
    _loader.setPath(path);
    _loader.setWithCredentials(withCredentials);
  }

  @override
  Future<DataTexture?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return _parse(super.parse(_parseData(tf?.data)));
  }
  @override
  Future<DataTexture?> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(super.parse(_parseData(tf.data)));
  }
  @override
  Future<DataTexture?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return _parse(super.parse(_parseData(tf?.data)));
  }
  @override
  Future<DataTexture?> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(super.parse(_parseData(tf.data)));
  }
  @override
  Future<DataTexture?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset, package: package);
    return _parse(super.parse(_parseData(tf?.data)));
  }
  @override
  Future<DataTexture?> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(super.parse(_parseData(tf.data)));
  }

  DataTexture? _parse(DataTexture? texture){
    if(texture == null) return null;
    switch (texture.type) {
      case UnsignedByteType:
        texture.encoding = RGBEEncoding;
        texture.minFilter = NearestFilter;
        texture.magFilter = NearestFilter;
        texture.generateMipmaps = false;
        texture.flipY = true;
        break;

      case FloatType:
        texture.encoding = LinearEncoding;
        texture.minFilter = LinearFilter;
        texture.magFilter = LinearFilter;
        texture.generateMipmaps = false;
        texture.flipY = true;
        break;

      case HalfFloatType:
        texture.encoding = LinearEncoding;
        texture.minFilter = LinearFilter;
        texture.magFilter = LinearFilter;
        texture.generateMipmaps = false;
        texture.flipY = true;
        break;
    }

    return texture;
  }

  // adapted from http://www.graphics.cornell.edu/~bjw/rgbe.html
  Map<String,dynamic>? _parseData(Uint8List? buffer) {
    if(buffer == null) return null;
    int byteArrayPos = 0;

    const rgbeRETURNFAILURE = -1,
      rgbeReadError = 1,
      rgbeWriteError = 2,
      rgbeFormatError = 3,
      rgbeMemoryError = 4;

    rgbeError(rgbeErrorCode, msg) {
      switch (rgbeErrorCode) {
        case rgbeReadError:
          console.error('RGBELoader Read Error: ${msg ?? ""}');
          break;
        case rgbeWriteError:
          console.error('RGBELoader Write Error: ${msg ?? ""}');
          break;
        case rgbeFormatError:
          console.error('RGBELoader Bad File Format: ${msg ?? ""}');
          break;
        case rgbeMemoryError:
          console.error('RGBELoader: Error: ${msg ?? ""}');
          break;
        default:
      }

      return rgbeRETURNFAILURE;
    }

    /* offsets to red, green, and blue components in a data (float) pixel */
    //RGBE_DATA_RED = 0,
    //RGBE_DATA_GREEN = 1,
    //RGBE_DATA_BLUE = 2,

    /* number of floats per pixel, use 4 since stored in rgba image format */
    //RGBE_DATA_SIZE = 4,

    /* flags indicating which fields in an rgbe_header_info are valid */
    const rgbeVALIDPROGRAMTYPE = 1,
        rgbeVALIDFORMAT = 2,
        rgbeVALIDDIMENSIONS = 4;

    const newLine = '\n';

    fgets(Uint8List buffer, [lineLimit, consume]) {
      const chunkSize = 128;

      lineLimit = lineLimit ?? 1024;
      int p = byteArrayPos;
      int i = -1;
      int len = 0;
      String s = '';
      String chunk = String.fromCharCodes(buffer.sublist(p, p + chunkSize));

      while ((0 > (i = chunk.indexOf(newLine))) &&
          (len < lineLimit) &&
          (p < buffer.lengthInBytes)) {
        s += chunk;
        len += chunk.length;
        p += chunkSize;
        chunk += String.fromCharCodes(buffer.sublist(p, p + chunkSize));
      }

      if (-1 < i) {
        /*for (i=l-1; i>=0; i--) {
						byteCode = m.charCodeAt(i);
						if (byteCode > 0x7f && byteCode <= 0x7ff) byteLen++;
						else if (byteCode > 0x7ff && byteCode <= 0xffff) byteLen += 2;
						if (byteCode >= 0xDC00 && byteCode <= 0xDFFF) i--; //trail surrogate
					}*/
        if (false != consume) byteArrayPos += len + i + 1;
        return s + chunk.substring(0, i);
      }

      return null;
    }

    /* minimal header reading.  modify if you want to parse more information */
    rgbeReadHeader(buffer) {
      // regexes to parse header info fields
      final magicTokenRe = RegExp(r"^#\?(\S+)"),
          gammaRe = RegExp(r"^\s*GAMMA\s*=\s*(\d+(\.\d+)?)\s*$"),
          exposureRe = RegExp(r"^\s*EXPOSURE\s*=\s*(\d+(\.\d+)?)\s*$"),
          formatRe = RegExp(r"^\s*FORMAT=(\S+)\s*$"),
          dimensionsRe = RegExp(r"^\s*\-Y\s+(\d+)\s+\+X\s+(\d+)\s*$");

      // RGBE format header struct
      Map<String, dynamic> header = {
        "valid": 0,
        /* indicate which fields are valid */

        "string": '',
        /* the actual header string */

        "comments": '',
        /* comments found in header */

        "programtype": 'RGBE',
        /* listed at beginning of file to identify it after "#?". defaults to "RGBE" */

        "format": '',
        /* RGBE format, default 32-bit_rle_rgbe */

        "gamma": 1.0,
        /* image has already been gamma corrected with given gamma. defaults to 1.0 (no correction) */

        "exposure": 1.0,
        /* a value of 1.0 in an image corresponds to <exposure> watts/steradian/m^2. defaults to 1.0 */

        "width": 0,
        "height": 0 /* image dimensions, width/height */
      };

      RegExpMatch? match;

      String? line = fgets(buffer, null, null);

      if (byteArrayPos >= buffer.lengthInBytes || line == null) {
        return rgbeError(rgbeReadError, 'no header found');
      }

      /* if you want to require the magic token then uncomment the next line */
      if (!(magicTokenRe.hasMatch(line))) {
        return rgbeError(rgbeFormatError, 'bad initial token');
      }

      match = magicTokenRe.firstMatch(line);

      int valid = header["valid"]!;

      valid |= rgbeVALIDPROGRAMTYPE;
      header["valid"] = valid;

      header["programtype"] = match?[1];
      header["string"] += 'line\n';

      while (true) {
        line = fgets(buffer);
        if (null == line) break;
        header["string"] += 'line\n';

        if (line.isNotEmpty && '#' == line[0]) {
          header["comments"] += 'line\n';
          continue; // comment line

        }

        if (gammaRe.hasMatch(line)) {
          match = gammaRe.firstMatch(line);

          header["gamma"] = double.parse(match![1]!);
        }

        if (exposureRe.hasMatch(line)) {
          match = exposureRe.firstMatch(line);

          header["exposure"] = double.parse(match![1]!);
        }

        if (formatRe.hasMatch(line)) {
          match = formatRe.firstMatch(line);

          header["valid"] |= rgbeVALIDFORMAT;
          header["format"] = match?[1]; //'32-bit_rle_rgbe';

        }

        if (dimensionsRe.hasMatch(line)) {
          match = dimensionsRe.firstMatch(line);

          header["valid"] |= rgbeVALIDDIMENSIONS;
          header["height"] = int.parse(match![1]!);
          header["width"] = int.parse(match[2]!);
        }

        if ((header["valid"] & rgbeVALIDFORMAT) == 1 &&
            (header["valid"] & rgbeVALIDDIMENSIONS) == 1) break;
      }

      if ((header["valid"] & rgbeVALIDFORMAT) == 0) {
        return rgbeError(rgbeFormatError, 'missing format specifier');
      }

      if ((header["valid"] & rgbeVALIDDIMENSIONS) == 0) {
        return rgbeError(rgbeFormatError, 'missing image size specifier');
      }

      return header;
    }

    rgbeReadPixelsRLE(Uint8List buffer, int w, int h) {
      int scanlineWidth = w;

      if (
          // run length encoding is not allowed so read flat
          ((scanlineWidth < 8) || (scanlineWidth > 0x7fff)) ||
              // this file is not run length encoded
              ((2 != buffer[0]) ||
                  (2 != buffer[1]) ||
                  ((buffer[2] & 0x80) != 0))) {
        // return the flat buffer
        return buffer;
      }

      if (scanlineWidth != ((buffer[2] << 8) | buffer[3])) {
        return rgbeError(rgbeFormatError, 'wrong scanline width');
      }

      final dataRgba = Uint8List(4 * w * h);

      if (dataRgba.isEmpty) {
        return rgbeError(rgbeMemoryError, 'unable to allocate buffer space');
      }

      int offset = 0, pos = 0;

      final ptrEnd = 4 * scanlineWidth;
      final rgbeStart = Uint8List(4);
      final scanlineBuffer = Uint8List(ptrEnd);
      int numScanlines = h;

      // read in each successive scanline
      while ((numScanlines > 0) && (pos < buffer.lengthInBytes)) {
        if (pos + 4 > buffer.lengthInBytes) {
          return rgbeError(rgbeReadError, null);
        }

        rgbeStart[0] = buffer[pos++];
        rgbeStart[1] = buffer[pos++];
        rgbeStart[2] = buffer[pos++];
        rgbeStart[3] = buffer[pos++];

        if ((2 != rgbeStart[0]) ||
            (2 != rgbeStart[1]) ||
            (((rgbeStart[2] << 8) | rgbeStart[3]) != scanlineWidth)) {
          return rgbeError(rgbeFormatError, 'bad rgbe scanline format');
        }

        // read each of the four channels for the scanline into the buffer
        // first red, then green, then blue, then exponent
        int ptr = 0;
        int count;

        while ((ptr < ptrEnd) && (pos < buffer.lengthInBytes)) {
          count = buffer[pos++];
          final isEncodedRun = count > 128;
          if (isEncodedRun) count -= 128;

          if ((0 == count) || (ptr + count > ptrEnd)) {
            return rgbeError(rgbeFormatError, 'bad scanline data');
          }

          if (isEncodedRun) {
            // a (encoded) run of the same value
            final byteValue = buffer[pos++];
            for (int i = 0; i < count; i++) {
              scanlineBuffer[ptr++] = byteValue;
            }
            //ptr += count;

          } else {
            // a literal-run
            scanlineBuffer.setAll(ptr, buffer.sublist(pos, pos + count));
            ptr += count;
            pos += count;
          }
        }

        // now convert data from buffer into rgba
        // first red, then green, then blue, then exponent (alpha)
        final l = scanlineWidth; //scanline_buffer.lengthInBytes;
        for (int i = 0; i < l; i++) {
          int off = 0;
          dataRgba[offset] = scanlineBuffer[i + off];
          off += scanlineWidth; //1;
          dataRgba[offset + 1] = scanlineBuffer[i + off];
          off += scanlineWidth; //1;
          dataRgba[offset + 2] = scanlineBuffer[i + off];
          off += scanlineWidth; //1;
          dataRgba[offset + 3] = scanlineBuffer[i + off];
          offset += 4;
        }

        numScanlines--;
      }

      return dataRgba;
    }

    rgbeByteToRGBFloat(sourceArray, sourceOffset, destArray, destOffset) {
      final e = sourceArray[sourceOffset + 3];
      final scale = math.pow(2.0, e - 128.0) / 255.0;

      destArray[destOffset + 0] = sourceArray[sourceOffset + 0] * scale;
      destArray[destOffset + 1] = sourceArray[sourceOffset + 1] * scale;
      destArray[destOffset + 2] = sourceArray[sourceOffset + 2] * scale;
      destArray[destOffset + 3] = 1;
    }

    rgbeByteToRGBHalf(sourceArray, sourceOffset, destArray, destOffset) {
      final e = sourceArray[sourceOffset + 3];
      final scale = math.pow(2.0, e - 128.0) / 255.0;

      // clamping to 65504, the maximum representable value in float16
      destArray[destOffset + 0] = MathUtils.toHalfFloat(
          math.min<double>(sourceArray[sourceOffset + 0] * scale, 65504));
      destArray[destOffset + 1] = MathUtils.toHalfFloat(
          math.min<double>(sourceArray[sourceOffset + 1] * scale, 65504));
      destArray[destOffset + 2] = MathUtils.toHalfFloat(
          math.min<double>(sourceArray[sourceOffset + 2] * scale, 65504));
      destArray[destOffset + 3] = MathUtils.toHalfFloat(1.0);
    }

    // final byteArray = Uint8Array( buffer );
    // byteArray.pos = 0;
    final byteArray = buffer;

    Map<String, dynamic> rgbeHeaderInfo = rgbeReadHeader(byteArray) as Map<String, dynamic>;

    if (rgbeHeaderInfo.isNotEmpty) {
      rgbeHeaderInfo = rgbeHeaderInfo;

      final w = rgbeHeaderInfo["width"], h = rgbeHeaderInfo["height"];

      Uint8List imageRgbaData = rgbeReadPixelsRLE(byteArray.sublist(byteArrayPos), w, h) as Uint8List;
      
      if (imageRgbaData.isNotEmpty) {
        dynamic data;
        dynamic format;
        dynamic type;
        int numElements;

        switch (this.type) {

          // case UnsignedByteType:

          // 	data = image_rgba_data;
          // 	format = RGBEFormat; // handled as THREE.RGBAFormat in shaders
          // 	type = UnsignedByteType;
          // 	break;

          case FloatType:
            numElements = imageRgbaData.length ~/ 4;
            final floatArray = Float32Array(numElements * 4);

            for (int j = 0; j < numElements; j++) {
              rgbeByteToRGBFloat(imageRgbaData, j * 4, floatArray, j * 4);
            }

            data = floatArray;
            type = FloatType;
            break;

          case HalfFloatType:
            numElements = imageRgbaData.length ~/ 4;
            final halfArray = Uint16Array(numElements * 4);

            for (int j = 0; j < numElements; j++) {
              rgbeByteToRGBHalf(imageRgbaData, j * 4, halfArray, j * 4);
            }

            data = halfArray;
            type = HalfFloatType;
            break;

          default:
            console.warning('RGBELoader: unsupported type: ${this.type}');
            break;
        }

        return TextureLoaderData(
          width: w,
          height: h,
          data: data,
          header: rgbeHeaderInfo["string"],
          gamma: rgbeHeaderInfo["gamma"],
          exposure: rgbeHeaderInfo["exposure"],
          format: format,
          type: type
        ).json;
      }
    }

    return null;
  }

  RGBELoader setDataType(int value) {
    type = value;
    return this;
  }
}
