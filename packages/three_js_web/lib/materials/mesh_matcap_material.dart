import './material.dart';
import 'package:three_js_math/three_js_math.dart';

/// [MeshMatcapMaterial] is defined by a MatCap (or Lit Sphere) texture, which encodes the
/// material color and shading.
/// 
/// [MeshMatcapMaterial] does not respond to lights since the matcap image file encodes
/// baked lighting. It will cast a shadow onto an object that receives shadows
/// (and shadow clipping works), but it will not self-shadow or receive
/// shadows.
class MeshMatcapMaterial extends Material {

  /// [parameters] - (optional) an object with one or more
  /// properties defining the material's appearance. Any property of the
  /// material (including any property inherited from [Material]) can be
  /// passed in here.
  /// 
  /// The exception is the property [color], which can be
  /// passed in as a hexadecimal int and is 0xffffff (white) by default.
  /// [Color]is called internally.
  MeshMatcapMaterial([Map<MaterialProperty, dynamic>? parameters]) : super() {
    _init();
    setValues(parameters);
  }
  MeshMatcapMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    _init();
    setValuesFromString(parameters);
  }
  void _init(){
    defines = {'MATCAP': ''};

    type = 'MeshMatcapMaterial';

    color = Color.fromHex32(0xffffff); // diffuse

    matcap = null;

    map = null;

    bumpMap = null;
    bumpScale = 1;

    normalMap = null;
    normalMapType = TangentSpaceNormalMap;
    normalScale = Vector2(1, 1);

    displacementMap = null;
    displacementScale = 1;
    displacementBias = 0;

    alphaMap = null;

    flatShading = false;

    fog = true;
  }

  @override
  MeshMatcapMaterial copy(Material source) {
    super.copy(source);

    defines = {'MATCAP': ''};

    color.setFrom(source.color);

    matcap = source.matcap;

    map = source.map;

    bumpMap = source.bumpMap;
    bumpScale = source.bumpScale;

    normalMap = source.normalMap;
    normalMapType = source.normalMapType;
    normalScale!.setFrom(source.normalScale!);

    displacementMap = source.displacementMap;
    displacementScale = source.displacementScale;
    displacementBias = source.displacementBias;

    alphaMap = source.alphaMap;

    flatShading = source.flatShading;

    fog = source.fog;

    return this;
  }
}
