import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'dart:math' as math;

BufferGeometry? _lineGeometry;

class ArrowHelper extends Object3D {
  late Line line;
  late Mesh cone;
  final _axis = Vector3();
  CylinderGeometry? _coneGeometry;
  

  ArrowHelper([Vector3? dir, Vector3? origin, double? length, int? color, double? headLength, double? headWidth]) : super() {
    // dir is assumed to be normalized

    type = 'ArrowHelper';

    dir ??= Vector3(0, 0, 1);
    origin ??= Vector3(0, 0, 0);
    length ??= 1;
    color ??= 0xffff00;
    headLength ??= 0.2 * length;
    headWidth ??= 0.2 * headLength;

    if (_lineGeometry == null) {
      _lineGeometry = BufferGeometry();
      _lineGeometry!.setAttributeFromString('position',Float32BufferAttribute(Float32Array.from([0, 0, 0, 0, 1, 0]), 3, false));

      _coneGeometry = CylinderGeometry(0, 0.5, 1, 5, 1);
      _coneGeometry!.translate(0, -0.5, 0);
    }

    position.setFrom(origin);

    line = Line(_lineGeometry,
        LineBasicMaterial.fromMap({"color": color, "toneMapped": false}));
    line.matrixAutoUpdate = false;
    add(line);

    cone = Mesh(_coneGeometry,
        MeshBasicMaterial.fromMap({"color": color, "toneMapped": false}));
    cone.matrixAutoUpdate = false;
    add(cone);

    setDirection(dir);
    setLength(length, headLength, headWidth);
  }

  void setDirection(Vector3 dir) {
    // dir is assumed to be normalized

    if (dir.y > 0.99999) {
      quaternion.set(0, 0, 0, 1);
    } else if (dir.y < -0.99999) {
      quaternion.set(1, 0, 0, 0);
    } else {
      _axis.setValues(dir.z, 0, -dir.x).normalize();

      final radians = math.acos(dir.y);

      quaternion.setFromAxisAngle(_axis, radians);
    }
  }

  void setLength(double length, [double? headLength, double? headWidth]) {
    headLength ??= 0.2 * length;
    headWidth ??= 0.2 * headLength;

    line.scale.setValues(1, math.max(0.0001, length - headLength), 1); // see #17458
    line.updateMatrix();

    cone.scale.setValues(headWidth, headLength, headWidth);
    cone.position.y = length.toDouble();
    cone.updateMatrix();
  }

  void setColor(Color color) {
    line.material?.color.setFrom(color);
    cone.material?.color.setFrom(color);
  }

  @override
  ArrowHelper copy(Object3D source, [bool? recursive]) {
    super.copy(source, false);
    if (source is ArrowHelper) {
      line.copy(source.line, false);
      cone.copy(source.cone, false);
    }
    return this;
  }
}
