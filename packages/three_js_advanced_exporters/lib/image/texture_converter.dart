import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;
import 'package:archive/archive.dart';
import 'package:three_js_advanced_exporters/image/image_export.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class TextureConverter {
  // Declare these as static or class-level cache objects to prevent memory leaks
  BufferGeometry? fullscreenQuadGeometry;
  ShaderMaterial? fullscreenQuadMaterial;
  Mesh? fullscreenQuad;
  PerspectiveCamera? decompressCamera;
  Scene? decompressScene;

  static final Uint8List PNG_SIGNATURE = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);

  static final Uint32List CRC32_TABLE = (() {
    final table = Uint32List(256);
    for (int i = 0; i < 256; i++) {
      int crc = i;
      for (int j = 0; j < 8; j++) {
        crc = ((crc & 1) != 0) ? (0xedb88320 ^ (crc >>> 1)) : (crc >>> 1);
      }
      table[i] = crc.toUnsigned(32);
    }
    return table;
  })();

  // --- Helper Functions ---
  static Future<Uint8List?> convertTextureToPNG(Texture texture, [int maxTextureSize = 2048]) async {
    // Prefer rasterizing image-backed textures through your ImageExport decoder utility
    if (texture.image != null) {
      try {
        final imageElement = texture.image;
        final bool flipY = !texture.flipY; // Maintain default Three.js texture coordinate flip behavior

        // Execute your custom image processing utility directly
        final pngData = await ImageExport.decodeImageFromList(
          imageElement, 
          flipY, 
          maxTextureSize
        );
        
        if (pngData != null) {
          return pngData;
        }
      } catch (error) {
        console.warning('Failed to convert texture to PNG via ImageExport: $error');
      }
    }

    // Fall back to collecting uncompressed/raw pixel arrays instantly if no image element exists
    final textureData = getImmediateTextureData(texture);
    if (textureData != null) {
      return textureData;
    }

    return null;
  }

  static Uint8List? getImmediateTextureData(Texture texture) {
    if (texture is DataTexture) {
      final ImageElement? img = texture.image;
      if (img != null && img.data != null) {
        final int w = (img.width).toInt();
        final int h = (img.height).toInt();
        
        Uint8List? rawBytes;
        if (img.data is Uint8List) rawBytes = img.data as Uint8List;
        if (img.data is ByteBuffer) rawBytes = (img.data as ByteBuffer).asUint8List();

        if (rawBytes != null && w > 0 && h > 0) {
          return _encodePngRgba(rawBytes, w, h);
        }
      }
    }

    final Texture texDyn = texture;
    if (texDyn.image != null && texDyn.image.src is String) {
      final String dataUrl = texDyn.image.src as String;
      const prefix = 'data:image/png;base64,';
      if (dataUrl.startsWith(prefix)) {
        return base64Decode(dataUrl.substring(prefix.length));
      }
    }

    if (texDyn.source.data != null) {
      final dynamic sourceData = texDyn.source.data;
      if (sourceData is Uint8List) {
        return Uint8List.fromList(sourceData);
      }
      if (sourceData is ByteBuffer) {
        return sourceData.asUint8List();
      }
    }

    return null;
  }

  static Uint8List? extractTextureData(Texture texture, bool embedTextures) {
    if (!embedTextures) return null;
    return getImmediateTextureData(texture);
  }

  static Vector2 getMaxTextureSize(List<Texture?> textures) {
    double width = 64;
    double height = 64; // Default minimum size

    for (final texture in textures) {
      final ImageElement img = texture?.image;
      width = math.max(width, img.width.toDouble());
      height = math.max(height, img.height.toDouble());
    }

    // Limit maximum texture size to prevent performance issues
    double maxSize = 1024; // Maximum 1024x1024 for combined textures
    if (width > maxSize || height > maxSize) {
      width = math.min(width, maxSize);
      height = math.min(height, maxSize);
    }
    
    return Vector2(width, height);
  }

  static Uint8List concatUint8Arrays(List<Uint8List> chunks) {
    final totalLength = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final output = Uint8List(totalLength);
    int offset = 0;
    for (final chunk in chunks) {
      output.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return output;
  }

  static void writeUint32BE(Uint8List target, int offset, int value) {
    target[offset] = (value >>> 24) & 0xff;
    target[offset + 1] = (value >>> 16) & 0xff;
    target[offset + 2] = (value >>> 8) & 0xff;
    target[offset + 3] = value & 0xff;
  }

  static int crc32(Uint8List data) {
    int crc = 0xffffffff;
    for (int i = 0; i < data.length; i++) {
      crc = CRC32_TABLE[(crc ^ data[i]) & 0xff] ^ (crc >>> 8);
    }
    return (crc ^ 0xffffffff).toUnsigned(32);
  }

  static Uint8List createPngChunk(String type, Uint8List data) {
    final typeBytes = Uint8List.fromList(utf8.encode(type));
    final lengthBytes = Uint8List(4);
    writeUint32BE(lengthBytes, 0, data.length);

    final crcBytes = Uint8List(4);
    writeUint32BE(crcBytes, 0, crc32(concatUint8Arrays([typeBytes, data])));

    return concatUint8Arrays([lengthBytes, typeBytes, data, crcBytes]);
  }

  static Uint8List _encodePngRgba(Uint8List rgba, int width, int height) {
    final stride = width * 4;
    final filtered = Uint8List(height * (stride + 1));

    for (int y = 0; y < height; y++) {
      final sourceOffset = y * stride;
      final targetOffset = y * (stride + 1);
      filtered[targetOffset] = 0; // Filter type 0 (None)
      
      final sub = rgba.buffer.asUint8List(rgba.offsetInBytes + sourceOffset, stride);
      filtered.setRange(targetOffset + 1, targetOffset + 1 + stride, sub);
    }

    final ihdr = Uint8List(13);
    writeUint32BE(ihdr, 0, width);
    writeUint32BE(ihdr, 4, height);
    ihdr[8] = 8;  // Bit depth
    ihdr[9] = 6;  // Color type (RGBA)
    ihdr[10] = 0; // Compression method
    ihdr[11] = 0; // Filter method
    ihdr[12] = 0; // Interlace method

    // Using package:archive's ZLibEncoder for zlibSync
    final idat = Uint8List.fromList(ZLibEncoder().encode(filtered, level: 9));

    return concatUint8Arrays([
      PNG_SIGNATURE,
      createPngChunk('IHDR', ihdr),
      createPngChunk('IDAT', idat),
      createPngChunk('IEND', Uint8List(0))
    ]);
  }

  // Rewritten to natively use package:archive instead of streaming fflate callbacks
  static Future<Uint8List> createZipData(Map<String, Uint8List> files) async {
    final archive = Archive();

    for (final entry in files.entries) {
      final fileName = entry.key;
      final contents = entry.value;

      final archiveFile = ArchiveFile(
        fileName, 
        contents.length, 
        contents
      );
      archive.addFile(archiveFile);
    }

    final zipBytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipBytes);
  }

  /// Decompresses hardware/GPU compressed textures into a readable raw pixel DataTexture.
  /// Fully compatible across Web, iOS, Android, and Desktop targets.
  Texture? decompress(Texture texture, [int? maxTextureSize, Renderer? renderer]) {
    maxTextureSize ??= double.infinity.toInt();
    
    if (renderer == null) {
      print('THREE.GLTFExporter: A valid active WebGLRenderer must be provided to decompress textures natively.');
      return texture; // Fallback to avoid a full crash
    }

    // 1. Initialize full-screen quad layout geometry if it hasn't been cached yet
    fullscreenQuadGeometry ??= PlaneGeometry(2, 2, 1, 1);

    // 2. Setup the blitting uncompression shader material
    fullscreenQuadMaterial ??= ShaderMaterial.fromMap({
      "uniforms": {
        "blitTexture": Uniform(texture)
      },
      "vertexShader": '''
        varying vec2 vUv;
        void main() {
          vUv = uv;
          gl_Position = vec4(position.xy * 1.0, 0.0, 0.999999);
        }
      ''',
      "fragmentShader": '''
        uniform sampler2D blitTexture;
        varying vec2 vUv;
        void main() {
          // Adjust default preview UV coordinates
          #ifdef IS_SRGB
            // Handles sRGB color transfer natively if defined
            gl_FragColor = sRGBTransferOETF(texture2D(blitTexture, vUv));
          #else
            gl_FragColor = texture2D(blitTexture, vUv);
          #endif
        }
      '''
    });

    // Update uniforms and shader defines for the current texture pass
    fullscreenQuadMaterial!.uniforms['blitTexture']!.value = texture;
    fullscreenQuadMaterial!.defines?['IS_SRGB'] = (texture.colorSpace == 'srgb');
    fullscreenQuadMaterial!.needsUpdate = true;

    // 3. Assemble the isolated rendering scene graph context
    if (fullscreenQuad == null) {
      fullscreenQuad = Mesh(fullscreenQuadGeometry!, fullscreenQuadMaterial!);
      fullscreenQuad!.frustumCulled = false;
    }

    decompressCamera ??= PerspectiveCamera();
    if (decompressScene == null) {
      decompressScene = Scene();
      decompressScene!.add(fullscreenQuad!);
    }

    // 4. Compute layout sizing bounds safely
    final int width = math.min<int>(texture.image?.width ?? 0, maxTextureSize);
    final int height = math.min<int>(texture.image?.height ?? 0, maxTextureSize);
    
    if (width == 0 || height == 0) return texture;

    // 5. Setup an off-screen GPU frame buffer instead of creating an HTML Canvas element
    final RenderTarget renderTarget = RenderTarget(
      width, 
      height, 
      RenderTargetOptions({
        'minFilter': LinearFilter,
        'magFilter': LinearFilter,
        'format': RGBAFormat,
        'type': UnsignedByteType
      })
    );

    // 6. Direct the active renderer context to draw the uncompressed texture into the target buffer
    final currentRenderTarget = renderer.getRenderTarget();
    renderer.setRenderTarget(renderTarget);
    renderer.clear();
    renderer.render(decompressScene!, decompressCamera!);

    // 7. Pull raw pixel arrays straight out of GPU memory into a native Dart byte buffer
    final Uint8List pixelBuffer = Uint8List(width * height * 4);
    renderer.readRenderTargetPixels(renderTarget, 0, 0, width, height, pixelBuffer);

    // Restore the previous rendering target to avoid interrupting the main game loop
    renderer.setRenderTarget(currentRenderTarget);
    renderTarget.dispose(); // Free GPU memory allocation immediately

    // 8. Pack the raw bytes back into an uncompressed DataTexture container
    // This completely replaces browser-only CanvasTexture components
    final DataTexture readableTexture = DataTexture(pixelBuffer, width, height);
    readableTexture.minFilter = texture.minFilter;
    readableTexture.magFilter = texture.magFilter;
    readableTexture.wrapS = texture.wrapS;
    readableTexture.wrapT = texture.wrapT;
    readableTexture.colorSpace = texture.colorSpace;
    readableTexture.name = texture.name;
    readableTexture.generateMipmaps = false;
    readableTexture.needsUpdate = true;

    return readableTexture;
  }

}