import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

/// Helper object to visualize a [BoundingBox].
/// 
/// ```
/// final box = BoundingBox();
/// box.setFromCenterAndSize(Vector3( 1, 1, 1 ),Vector3( 2, 1, 3 ) );
///
/// final helper = BoundingBoxHelper( box, 0xffff00 );
/// scene.add( helper );
/// ```
class BoundingBoxHelper extends LineSegments {
  BoundingBox? box;

  BoundingBoxHelper.create(super.geometry, super.material);

  /// [ box] -- the Box3 to show.
  /// 
  /// [color] -- (optional) the box's color. Default is 0xffff00.
  /// 
  /// Creates a new wireframe box that represents the passed [BoundingBox].
  factory BoundingBoxHelper(BoundingBox? box, [color = 0xffff00]) {
    final indices = Uint16Array.from([
      0,
      1,
      1,
      2,
      2,
      3,
      3,
      0,
      4,
      5,
      5,
      6,
      6,
      7,
      7,
      4,
      0,
      4,
      1,
      5,
      2,
      6,
      3,
      7
    ]);

    List<double> positions = [
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
      -1,
      -1,
      1,
      -1,
      -1,
      -1,
      -1,
      1,
      -1,
      -1
    ];

    final geometry = BufferGeometry();

    geometry.setIndex(Uint16BufferAttribute(indices, 1, false));
    geometry.setAttributeFromString('position',Float32BufferAttribute(Float32Array.from(positions), 3, false));

    final bbHelper = BoundingBoxHelper.create(geometry, LineBasicMaterial.fromMap({"color": color, "toneMapped": false}));

    bbHelper.box = box;
    bbHelper.type = 'BoundingBoxHelper';
    bbHelper.geometry!.computeBoundingSphere();

    return bbHelper;
  }

  /// This overrides the method in the base [Object3D] class so that it
  /// also updates the wireframe box to the extent of the [box] property.
  @override
  void updateMatrixWorld([bool force = false]) {
    final box = this.box!;
    if (box.isEmpty()) return;
    box.getCenter(position);
    box.getSize(scale);
    scale.scale(0.5);
    super.updateMatrixWorld(force);
  }
}
