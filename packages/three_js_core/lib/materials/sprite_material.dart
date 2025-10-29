import './material.dart';
import 'package:three_js_math/three_js_math.dart';

/// A material for a use with a [Sprite].
/// 
/// ```
/// final map = TextureLoader().fromAsset( 'textures/sprite.png' );
/// final material = SpriteMaterial({MaterialProperty.map: map, MaterialProperty.color: 0xffffff } );
///
/// final sprite = Sprite( material );
/// sprite.scale.set(200, 200, 1)
/// scene.add( sprite );
/// ```
class SpriteMaterial extends Material {

  /// [parameters] - (optional) an object with one or more
  /// properties defining the material's appearance. Any property of the
  /// material (including any property inherited from [Material] and
  /// [MeshStandardMaterial]) can be passed in here.
  /// 
  /// The exception is the property [color], which can be
  /// passed in as a hexadecimal int and is 0xffffff (white) by default.
  /// [Color] is called internally.
  SpriteMaterial([Map<MaterialProperty, dynamic>? parameters]) : super() {
    _init();
    setValues(parameters);
  }
  SpriteMaterial.fromMap([Map<String, dynamic>? parameters]) : super() {
    _init();
    setValuesFromString(parameters);
  }
  SpriteMaterial.fromJson(Map<String, dynamic> json, Map<String, dynamic> rootJson):super.fromJson(json, rootJson);

  void _init(){
    type = 'SpriteMaterial';
    transparent = true;
    color = Color(1, 1, 1);
    fog = true;
  }

  @override
  SpriteMaterial copy(Material source) {
    super.copy(source);
    color.setFrom(source.color);
    map = source.map;
    alphaMap = source.alphaMap;
    rotation = source.rotation;
    sizeAttenuation = source.sizeAttenuation;
    fog = source.fog;
    return this;
  }

  @override
  SpriteMaterial clone() {
    return SpriteMaterial()..copy(this);
  }
}
