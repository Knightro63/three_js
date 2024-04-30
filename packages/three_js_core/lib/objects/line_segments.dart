import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';
import './line.dart';

final _lsstart = Vector3.zero();
final _lsend = Vector3.zero();

class LineSegments extends Line {
  LineSegments(super.geometry, super.material){
    type = 'LineSegments';
  }

  @override
  LineSegments computeLineDistances() {
    final geometry = this.geometry;

    if (geometry != null) {
      // we assume non-indexed geometry

      if (geometry.index == null) {
        final positionAttribute = geometry.attributes["position"];
        final lineDistances = Float32Array(positionAttribute.count);

        for (int i = 0, l = positionAttribute.count; i < l; i += 2) {
          _lsstart.fromBuffer(positionAttribute, i);
          _lsend.fromBuffer(positionAttribute, i + 1);

          lineDistances[i] = (i == 0) ? 0 : lineDistances[i - 1];
          lineDistances[i + 1] = lineDistances[i] + _lsstart.distanceTo(_lsend);
        }

        geometry.setAttributeFromString('lineDistance', Float32BufferAttribute(lineDistances, 1, false));
      } 
      else {
        print('THREE.LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.');
      }
    }
    // else if (geometry.isGeometry) {
    //   throw ('THREE.LineSegments.computeLineDistances() no longer supports THREE.Geometry. Use THREE.BufferGeometry instead.');
    // }

    return this;
  }
}
