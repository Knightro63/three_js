
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

/// Helper object to visualize a [Plane].
/// 
/// ```
/// final plane = Plane( Vector3( 1, 1, 0.2 ), 3 );
/// final helper = PlaneHelper( plane, 1, 0xffff00 );
/// scene.add( helper );
/// ```
class PlaneHelper extends Line {
  double size = 1.0;
  Plane? plane;

  PlaneHelper.create(super.geometry, super.material){
    type = "PlaneHelper";
  }

  /// [plane] - the plane to visualize.
  /// 
  /// [size] - (optional) side length of plane helper. Default is
  /// 1.
  /// 
  /// [color] - (optional) the color of the helper. Default is
  /// 0xffff00.
  factory PlaneHelper(Plane plane, [double size = 1, int color = 0xffff00]) {
    List<double> positions = [
      1,
      -1,
      1,
      -1,
      1,
      1,
      -1,
      -1,
      1,
      1,
      1,
      1,
      -1,
      1,
      1,
      -1,
      -1,
      1,
      1,
      -1,
      1,
      1,
      1,
      1,
      0,
      0,
      1,
      0,
      0,
      0
    ];

    final geometry = BufferGeometry();
    geometry.setAttributeFromString('position',Float32BufferAttribute.fromList(positions, 3, false));
    geometry.computeBoundingSphere();

    final planeHelper = PlaneHelper.create(geometry, LineBasicMaterial.fromMap({"color": color, "toneMapped": false}));

    planeHelper.plane = plane;
    planeHelper.size = size;

    List<double> positions2 = [
      1,
      1,
      1,
      -1,
      1,
      1,
      -1,
      -1,
      1,
      1,
      1,
      1,
      -1,
      -1,
      1,
      1,
      -1,
      1
    ];

    final geometry2 = BufferGeometry();
    geometry2.setAttributeFromString('position',Float32BufferAttribute.fromList(positions2, 3, false));
    geometry2.computeBoundingSphere();

    planeHelper.add(Mesh(
        geometry2,
        MeshBasicMaterial.fromMap({
          "color": color,
          "opacity": 0.2,
          "transparent": true,
          "depthWrite": false,
          "toneMapped": false
        })));

    return planeHelper;
  }

  /// This overrides the method in the base [Object3D] class so that it
  /// also updates the helper object according to the [plane] and [size] properties.
  @override
  void updateMatrixWorld([bool force = false]) {
    double scale = -plane!.constant;

    if (scale.abs() < 1e-8) scale = 1e-8; // sign does not matter

    this.scale.setValues(0.5 * size, 0.5 * size, scale);

    children[0].material?.side = (scale < 0)
        ? BackSide
        : FrontSide; // renderer flips side when determinant < 0; flipping not wanted here

    lookAt(plane!.normal);

    super.updateMatrixWorld(force);
  }
}
