import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

final _v1 = Vector3.zero();
final _v2 = Vector3.zero();

class VertexTangentsHelper extends LineSegments {
  late Object3D object;
  late int size;

  VertexTangentsHelper.create(super.geometry, super.material);

  factory VertexTangentsHelper(Object3D object, [int size = 1, color = 0x00ffff]) {
    final nTangents = object.geometry?.attributes["tangent"].count;
    final geometry = BufferGeometry();

    final positions = Float32BufferAttribute(Float32Array(nTangents * 2 * 3), 3);

    geometry.setAttributeFromString('position', positions);

    final vth = VertexTangentsHelper.create(geometry, LineBasicMaterial.fromMap({"color": color, "toneMapped": false}));

    vth.object = object;
    vth.size = size;
    vth.type = 'VertexTangentsHelper';

    vth.matrixAutoUpdate = false;
    vth.update();

    return vth;
  }

 void update() {
    object.updateMatrixWorld(true);

    final matrixWorld = object.matrixWorld;
    final position = geometry!.attributes["position"];

    final objGeometry = object.geometry;
    final objPos = objGeometry!.attributes["position"];
    final objTan = objGeometry.attributes["tangent"];

    int idx = 0;

    // for simplicity, ignore index and drawcalls, and render every tangent

    for (int j = 0, jl = objPos.count; j < jl; j++) {
      _v1.fromBuffer(objPos, j)
          .applyMatrix4(matrixWorld);

      _v2.fromBuffer(objTan, j);

      _v2.transformDirection(matrixWorld).scale(size).add(_v1);

      position.setXYZ(idx, _v1.x, _v1.y, _v1.z);
      idx = idx + 1;
      position.setXYZ(idx, _v2.x, _v2.y, _v2.z);
      idx = idx + 1;
    }

    position.needsUpdate = true;
  }
}
