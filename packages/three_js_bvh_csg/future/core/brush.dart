import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'utils/geometry_utils.dart';
import './half_edge_map.dart';
import 'dart:typed_data';

class Brush extends Mesh {
  bool isBrush = true;
  final _previousMatrix = Matrix4.zero();
  Brush(super.geometry, super.material) : super() {
    _previousMatrix.copyFromArray(List.filled(16, 0.0));
  }

  void markUpdated() {
    _previousMatrix.setFrom(matrix);
  }

  bool isDirty() {
    List<double> el1 = matrix.storage;
    List<double> el2 = _previousMatrix.storage;
    for (int i = 0; i < 16; i++) {
      if (el1[i] != el2[i]) {
        return true;
      }
    }
    return false;
  }

  void prepareGeometry() {
    // generate shared array buffers
    final geometry = this.geometry;
    final attributes = geometry!.attributes;
    bool useSharedArrayBuffer = areSharedArrayBuffersSupported();
    if (useSharedArrayBuffer) {
      for (final key in attributes.keys) {
        final attribute = attributes[key];
        if (attribute is InterleavedBufferAttribute) {
          throw Exception('Brush: InterleavedBufferAttributes are not supported.');
        }
        attribute.array = convertToSharedArrayBuffer(attribute.array);
      }
    }

    // generate bounds tree
    if (!geometry.boundsTree) {
      ensureIndex(geometry, {useSharedArrayBuffer});
      geometry.boundsTree = MeshBVH(geometry, {'maxLeafTris': 3, 'indirect': true, useSharedArrayBuffer});
    }

    // generate half edges
    if (!geometry.halfEdges) {
      geometry.halfEdges = HalfEdgeMap(geometry);
    }

    // save the group indices for materials
    if (!geometry.groupIndices) {
      final triCount = getTriCount(geometry);
      final array = Uint16List(triCount);
      final groups = geometry.groups;
      for (int i = 0, l = groups.length; i < l; i++) {
        final start = groups[i]['start'];
        final count = groups[i]['count'];
        for (int g = start / 3, lg = (start + count) / 3; g < lg; g++) {
          array[g] = i;
        }
      }

      geometry.groupIndices = array;
    }
  }

  void disposeCacheData() {
    final geometry = this.geometry;
    geometry.halfEdges = null;
    geometry.boundsTree = null;
    geometry.groupIndices = null;
  }
}
