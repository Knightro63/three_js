import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_core/others/index.dart';
import 'package:three_js_math/three_js_math.dart';
import './line.dart';

final _lsstart = Vector3.zero();
final _lsend = Vector3.zero();

/// A series of lines drawn between pairs of vertices.
/// 
/// This is nearly the same as [Line]; the only difference is that it is
/// rendered using
/// [gl.LINE_LOOP](https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/drawElements) instead of
/// [gl.LINE_STRIP](https://developer.mozilla.org/en-US/docs/Web/API/WebGLRenderingContext/drawElements).
/// 
class LineSegments extends Line {

  /// [geometry] — Pair(s) of vertices representing each line segment(s).
  /// 
  /// [material] — Material for the line. Default is
  /// [LineBasicMaterial].
  /// 
  LineSegments(super.geometry, [super.material]){
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
        console.info('LineSegments.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.');
      }
    }
    // else if (geometry.isGeometry) {
    //   throw ('LineSegments.computeLineDistances() no longer supports Geometry. Use BufferGeometry instead.');
    // }

    return this;
  }
}
