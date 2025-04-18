import './material.dart';
import 'package:three_js_math/three_js_math.dart';

/// The default material used by [Points].
/// 
/// ```
/// final vertices = [];
///
/// for ( int i = 0; i < 10000; i ++ ) {
///   final x = MathUtils.randFloatSpread( 2000 );
///   final y = MathUtils.randFloatSpread( 2000 );
///   final z = MathUtils.randFloatSpread( 2000 );
///
///   vertices.add( x, y, z );
/// }
///
/// final geometry = BufferGeometry();
/// geometry.setAttribute(Attribute.position, Float32BufferAttribute( vertices, 3 ) );
/// final material = PointsMaterial( { MaterialProperty.color: 0x888888 } );
/// final points = Points( geometry, material );
/// scene.add( points );
/// ```
class PointsMaterial extends Material {

  /// [parameters] - (optional) an object with one or more
  /// properties defining the material's appearance. Any property of the
  /// material (including any property inherited from [Material] and
  /// [MeshStandardMaterial]) can be passed in here.
  /// 
  /// The exception is the property [color], which can be
  /// passed in as a hexadecimal int and is 0xffffff (white) by default.
  /// [Color] is called internally.
  PointsMaterial([Map<MaterialProperty, dynamic>? parameters]) {
    _init();
    setValues(parameters);
  }
  PointsMaterial.fromMap([Map<String, dynamic>? parameters]) {
    _init();
    setValuesFromString(parameters);
  }

  void _init(){
    type = "PointsMaterial";
    sizeAttenuation = true;
    color = Color(1, 1, 1);
    size = 1;

    fog = true;
  }

  @override
  PointsMaterial copy(Material source) {
    super.copy(source);
    color.setFrom(source.color);

    map = source.map;
    alphaMap = source.alphaMap;
    size = source.size;
    sizeAttenuation = source.sizeAttenuation;

    fog = source.fog;

    return this;
  }
}
