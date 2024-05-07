import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';

// https://wwwimages2.adobe.com/content/dam/acom/en/products/speedgrade/cc/pdfs/cube-lut-specification-1.0.pdf
class LUTCubeLoaderData {
  LUTCubeLoaderData({
    this.title,
    required this.size,
    required this.domainMax,
    required this.domainMin,
    this.texture,
    this.texture3D
  });

  String? title;
  num size;
  Vector3 domainMin;
  Vector3 domainMax;
  DataTexture? texture;
  Data3DTexture? texture3D;
}

/// A 3D LUT loader that supports the .cube file format.
/// 
/// Based on the following reference: (https://wwwimages2.adobe.com/content/dam/acom/en/products/speedgrade/cc/pdfs/cube-lut-specification-1.0.pdf)
class LUTCubeLoader extends Loader {
  late final FileLoader _loader;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
  /// 
  /// Creates a new [LUTCubeLoader].
  LUTCubeLoader([super.manager]){
    _loader = FileLoader(manager);
  }

  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
  }
  
  void _init(){
    _loader.setPath(path);
    _loader.setResponseType('text');
  }

  @override
  Future<LUTCubeLoaderData?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<LUTCubeLoaderData> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<LUTCubeLoaderData?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<LUTCubeLoaderData> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<LUTCubeLoaderData?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<LUTCubeLoaderData> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }

  LUTCubeLoaderData _parse(Uint8List bytes) {
    String str = String.fromCharCodes(bytes);
    // Remove empty lines and comments
    // str = str
    // 	.replace( /^#.*?(\n|\r)/gm, '' )
    // 	.replace( /^\s*?(\n|\r)/gm, '' )
    // 	.trim();

    final reg = RegExp(r"^#.*?(\n|\r)", multiLine: true);
    str = str.replaceAll(reg, "");

    final reg2 = RegExp(r"^\s*?(\n|\r)", multiLine: true);
    str = str.replaceAll(reg2, "");
    str = str.trim();

    String? title;
    int size = 0;
    final domainMin = Vector3(0, 0, 0);
    final domainMax = Vector3(1, 1, 1);

    final reg3 = RegExp(r"[\n\r]+");
    final lines = str.split(reg3);
    Uint8Array? data;

    int currIndex = 0;
    for (int i = 0, l = lines.length; i < l; i++) {
      final line = lines[i].trim();
      final split = line.split(RegExp(r"\s"));

      switch (split[0]) {
        case 'TITLE':
          title = line.substring(7, line.length - 1);
          break;
        case 'LUT_3D_SIZE':
          // TODO: A .CUBE LUT file specifies floating point values and could be represented with
          // more precision than can be captured with Uint8Array.
          final sizeToken = split[1];
          size = double.parse(sizeToken).toInt();
          data = Uint8Array(size * size * size * 4);
          break;
        case 'DOMAIN_MIN':
          domainMin.x = double.parse(split[1]);
          domainMin.y = double.parse(split[2]);
          domainMin.z = double.parse(split[3]);
          break;
        case 'DOMAIN_MAX':
          domainMax.x = double.parse(split[1]);
          domainMax.y = double.parse(split[2]);
          domainMax.z = double.parse(split[3]);
          break;
        default:
          final r = double.parse(split[0]);
          final g = double.parse(split[1]);
          final b = double.parse(split[2]);

          if (r > 1.0 || r < 0.0 || g > 1.0 || g < 0.0 || b > 1.0 || b < 0.0) {
            throw ('LUTCubeLoader : Non normalized values not supported.');
          }

          data![currIndex + 0] = (r * 255).toInt();
          data[currIndex + 1] = (g * 255).toInt();
          data[currIndex + 2] = (b * 255).toInt();
          data[currIndex + 3] = 255;
          currIndex += 4;
      }
    }

    final texture = DataTexture();
    texture.image!.data = data;
    texture.image!.width = size;
    texture.image!.height = size * size;
    texture.type = UnsignedByteType;
    texture.magFilter = LinearFilter;
    texture.wrapS = ClampToEdgeWrapping;
    texture.wrapT = ClampToEdgeWrapping;
    texture.generateMipmaps = false;

    final texture3D = Data3DTexture();
    texture3D.image!.data = data;
    texture3D.image!.width = size;
    texture3D.image!.height = size;
    texture3D.image!.depth = size;
    texture3D.type = UnsignedByteType;
    texture3D.magFilter = LinearFilter;
    texture3D.wrapS = ClampToEdgeWrapping;
    texture3D.wrapT = ClampToEdgeWrapping;
    texture3D.wrapR = ClampToEdgeWrapping;
    texture3D.generateMipmaps = false;

    return LUTCubeLoaderData(
      title: title,
      size: size,
      domainMin: domainMin,
      domainMax: domainMax,
      texture: texture,
      texture3D: texture3D,
    );
  }
}
