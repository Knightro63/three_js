import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

final _v1 = Vector3.zero();
final _v2 = Vector3.zero();
final _normalMatrix = Matrix3.identity();

class VertexNormalsHelper extends LineSegments {
  late Object3D object;
  late int size;

  VertexNormalsHelper.create(super.geometry, super.material);

  factory VertexNormalsHelper(Object3D object, [int size = 1, int color = 0xff0000]) {
    final geometry = BufferGeometry();

    final nNormals = object.geometry?.attributes["normal"].count;
    final positions = Float32BufferAttribute(Float32Array(nNormals * 2 * 3), 3, false);

    geometry.setAttributeFromString('position', positions);

    final vnh = VertexNormalsHelper.create(geometry, LineBasicMaterial.fromMap({"color": color, "toneMapped": false}));

    vnh.object = object;
    vnh.size = size;
    vnh.type = 'VertexNormalsHelper';

    //

    vnh.matrixAutoUpdate = false;

    vnh.update();

    return vnh;
  }

  void update() {
    object.updateMatrixWorld(true);
    _normalMatrix.getNormalMatrix(object.matrixWorld);

    final matrixWorld = object.matrixWorld;
    final position = geometry!.attributes["position"];

  
    BufferGeometry? objGeometry = object.geometry;

    if (objGeometry != null) {
      final objPos = objGeometry.attributes["position"];
      final objNorm = objGeometry.attributes["normal"];

      int idx = 0;

      // for simplicity, ignore index and drawcalls, and render every normal

      for (int j = 0, jl = objPos.count; j < jl; j++) {
        _v1.fromBuffer(objPos, j).applyMatrix4(matrixWorld);

        _v2.fromBuffer(objNorm, j);

        _v2.applyMatrix3(_normalMatrix)
            .normalize()
            .scale(size)
            .add(_v1);

        position.setXYZ(idx, _v1.x, _v1.y, _v1.z);
        idx = idx + 1;
        position.setXYZ(idx, _v2.x, _v2.y, _v2.z);
        idx = idx + 1;
      }
    }

    position.needsUpdate = true;
  }
}
