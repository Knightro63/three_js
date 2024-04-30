import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';

class BoundingBoxHelper extends LineSegments {
  BoundingBox? box;

  BoundingBoxHelper.create(super.geometry, super.material);

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
