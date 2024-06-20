import 'dart:typed_data';
import 'dart:convert';
import '../core/index.dart';
import 'package:three_js_math/three_js_math.dart';
import './source.dart';

int textureId = 0;

/// Create a texture to apply to a surface or as a reflection or refraction map.
/// 
/// Note: After the initial use of a texture, its dimensions, format, and type
/// cannot be changed. Instead, call [dispose] on the texture and
/// instantiate a new one.
/// ```
/// // load a texture, set wrap mode to repeat
/// final texture = TextureLoader().fromAsset( "textures/water.jpg" );
/// texture.wrapS = RepeatWrapping;
/// texture.wrapT = RepeatWrapping;
/// texture.repeat.setValues( 4, 4 );
/// ```
class Texture with EventDispatcher {
  static String? defaultImage;
  static int defaultMapping = UVMapping;

  bool isTexture = true;
  bool isWebGLRenderTarget = false;
  bool isVideoTexture = false;
  bool isDepthTexture = false;
  bool isCompressedTexture = false;
  bool isOpenGLTexture = false;
  bool isRenderTargetTexture = false; // indicates whether a texture belongs to a render target or not
  bool needsPMREMUpdate = false; // indicates whether this texture should be processed by PMREMGenerator or not (only relevant for render target textures)
  
  late Source source;

  String colorSpace = NoColorSpace;
  int id = textureId++;
  String uuid = MathUtils.generateUUID();
  String name = "";
  int? mapping;
  int wrapS = ClampToEdgeWrapping;
  int wrapT = ClampToEdgeWrapping;
  int wrapR = ClampToEdgeWrapping;
  int magFilter = LinearFilter;
  int minFilter = LinearMipmapLinearFilter;
  late int anisotropy;
  int format = RGBAFormat;
  late int? internalFormat;
  int type = UnsignedByteType;

  Vector2 offset = Vector2(0, 0);
  Vector2 repeat = Vector2(1, 1);
  Vector2 center = Vector2(0, 0);
  double rotation = 0;

  bool matrixAutoUpdate = true;
  Matrix3 matrix = Matrix3.identity();

  bool generateMipmaps = true;
  bool premultiplyAlpha = false;
  bool flipY = true;
  int unpackAlignment = 4; // valid values: 1, 2, 4, 8 (see http://www.khronos.org/opengles/sdk/docs/man/xhtml/glPixelStorei.xml)

  // Values of encoding !== THREE.LinearEncoding only supported on map, envMap and emissiveMap.
  //
  // Also changing the encoding after already used by a Material will not automatically make the Material
  // update. You need to explicitly call Material.needsUpdate to trigger it to recompile.
  int encoding = LinearEncoding;
  Map userData = {};
  int version = 0;
  Function? onUpdate;
  List mipmaps = [];

  Texture([
    image, 
    int? mapping, 
    int? wrapS, 
    int? wrapT, 
    int? magFilter,
    int? minFilter, 
    int? format, 
    int? type, 
    int? anisotropy, 
    int? encoding
  ]) {
    source = Source(image);
    this.mapping = mapping ?? Texture.defaultMapping;

    this.wrapS = wrapS ?? ClampToEdgeWrapping;
    this.wrapT = wrapT ?? ClampToEdgeWrapping;

    this.magFilter = magFilter ?? LinearFilter;
    this.minFilter = minFilter ?? LinearMipmapLinearFilter;

    this.anisotropy = anisotropy ?? 1;

    this.format = format ?? RGBAFormat;
    internalFormat = null;
    this.type = type ?? UnsignedByteType;
    this.encoding = encoding ?? LinearEncoding;
  }

  get image => source.data;
  set image(value) => source.data = value;

  set needsUpdate(bool value) {
    if (value) {
      version++;
      source.needsUpdate = true;
    }
  }

  void updateMatrix() {
    matrix.setUvTransform(offset.x, offset.y, repeat.x, repeat.y, rotation, center.x, center.y);
  }

  Texture clone() {
    return Texture().copy(this);
  }

  Texture copy(Texture source) {
    name = source.name;

    this.source = source.source;

    mapping = source.mapping;

    wrapS = source.wrapS;
    wrapT = source.wrapT;

    magFilter = source.magFilter;
    minFilter = source.minFilter;

    anisotropy = source.anisotropy;

    format = source.format;
    internalFormat = source.internalFormat;
    type = source.type;

    offset.setFrom(source.offset);
    repeat.setFrom(source.repeat);
    center.setFrom(source.center);
    rotation = source.rotation;

    matrixAutoUpdate = source.matrixAutoUpdate;
    matrix.setFrom(source.matrix);

    generateMipmaps = source.generateMipmaps;
    premultiplyAlpha = source.premultiplyAlpha;
    flipY = source.flipY;
    unpackAlignment = source.unpackAlignment;
    encoding = source.encoding;

    userData = json.decode(json.encode(source.userData));

    return this;
  }

  Map<String, dynamic> toJson(meta) {
    bool isRootObject = (meta == null || meta is String);

    if (!isRootObject && meta.textures[uuid] != null) {
      return meta.textures[uuid];
    }

    Map<String, dynamic> output = {
      "metadata": {
        "version": 4.5,
        "type": 'Texture',
        "generator": 'Texture.toJson'
      },
      "uuid": uuid,
      "name": name,
      "image": source.toJson(meta)['uuid'],
      "mapping": mapping,
      "repeat": [repeat.x, repeat.y],
      "offset": [offset.x, offset.y],
      "center": [center.x, center.y],
      "rotation": rotation,
      "wrap": [wrapS, wrapT],
      "format": format,
      "type": type,
      "encoding": encoding,
      "minFilter": minFilter,
      "magFilter": magFilter,
      "anisotropy": anisotropy,
      "flipY": flipY,
      "premultiplyAlpha": premultiplyAlpha,
      "unpackAlignment": unpackAlignment
    };

    if (userData.isNotEmpty) output["userData"] = userData;

    if (!isRootObject) {
      meta.textures[uuid] = output;
    }

    return output;
  }

  void dispose() {
    dispatchEvent(Event(type: "dispose"));
    if (image is List) {
      image.forEach((img) {
        img.dispose();
      });
    }
    else {
      image?.dispose();
    }

    source.dispose();
  }

  Vector2 transformUv(Vector2 uv) {
    if (mapping != UVMapping) return uv;

    uv.applyMatrix3(matrix);

    if (uv.x < 0 || uv.x > 1) {
      switch (wrapS) {
        case RepeatWrapping:
          uv.x = uv.x - uv.x.floor();
          break;

        case ClampToEdgeWrapping:
          uv.x = uv.x < 0 ? 0 : 1;
          break;

        case MirroredRepeatWrapping:
          if((uv.x.floor().abs() % 2) == 1) {
            uv.x = uv.x.ceil() - uv.x;
          } else {
            uv.x = uv.x - uv.x.floor();
          }

          break;
      }
    }

    if (uv.y < 0 || uv.y > 1) {
      switch (wrapT) {
        case RepeatWrapping:
          uv.y = uv.y - uv.y.floor();
          break;

        case ClampToEdgeWrapping:
          uv.y = uv.y < 0 ? 0 : 1;
          break;

        case MirroredRepeatWrapping:
          if((uv.y.floor().abs() % 2) == 1) {
            uv.y = uv.y.ceil() - uv.y;
          } else {
            uv.y = uv.y - uv.y.floor();
          }

          break;
      }
    }

    if (flipY) {
      uv.y = 1 - uv.y;
    }

    return uv;
  }
}

class ImageDataInfo {
  Uint8List data;
  num width;
  num height;
  num depth;

  ImageDataInfo(this.data, this.width, this.height, this.depth);
}

