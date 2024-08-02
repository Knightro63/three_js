//import 'package:vector_math/vector_math_64.dart';
import 'package:three_js_math/three_js_math.dart';
//import 'package:three_js_math/vector/vector3_util.dart';
//import 'package:vector_math/vector_math.dart';
import 'operations_utils.dart';
import '../utils/geometry_utils.dart';
import '../constants.dart';
import '../utils/triangle_utils.dart';

Matrix4 _matrix = Matrix4.identity();
final Matrix3 _normalMatrix = Matrix3.identity();
final Triangle _triA = Triangle();
final Triangle _triB = Triangle();
final Triangle _tri = Triangle();
final Triangle _barycoordTri = Triangle();
final List<dynamic> _attr = [];
final List<dynamic> _actions = [];

dynamic getFirstIdFromSet(Set<dynamic> set) {
  // for (const id of set) return id;
  return set.first;
}

// runs the given oepration against a and b using the splitter and appending data
// to the attributeData obejct.
Map<String, dynamic> performOperation(dynamic a, dynamic b, List<dynamic> operations, dynamic splitter,
    List<dynamic> attributeData, Map<String, dynamic> options) {
  //const { useGroups = true } = options;
  bool useGroups = options['useGroups'] ?? true;
  final aIntersections = collectIntersectingTriangles(a, b);
  final bIntersections = collectIntersectingTriangles(a, b);

  final List<dynamic> resultGroups = [];
  dynamic resultMaterials;

  int groupOffset;
  groupOffset = useGroups ? 0 : -1;
  performSplitTriangleOperations(a, b, aIntersections, operations, false, splitter, attributeData, groupOffset);
  performWholeTriangleOperations(a, b, aIntersections, operations, false, attributeData, groupOffset);

  // find whether the set of operations contains a non-hollow operations. If it does then we need
  // to perform the second set of triangle additions
  //const nonHollow = operations.findIndex( op => op !== HOLLOW_INTERSECTION && op !== HOLLOW_SUBTRACTION ) !== - 1;
  bool nonHollow = operations.any((op) => op != HOLLOW_INTERSECTION && op != HOLLOW_SUBTRACTION);

  if (nonHollow) {
    groupOffset = useGroups ? a['geometry'].groups.length ?? 1 : -1;
    performSplitTriangleOperations(b, a, bIntersections, operations, true, splitter, attributeData, groupOffset);
    performWholeTriangleOperations(b, a, bIntersections, operations, true, attributeData, groupOffset);
  }

  _attr.length = 0;
  _actions.length = 0;

  return {'groups': resultGroups, 'materials': resultMaterials};
}

// perform triangle splitting and CSG operations on the set of split triangles
int performSplitTriangleOperations(dynamic a, dynamic b, dynamic intersectionMap, List<dynamic> operations, bool invert,
    dynamic splitter, List<dynamic> attributeData,
    [int groupOffset = 0]) {
  bool invertedGeometry = a.matrixWorld.determinant() < 0;

  // transforms into the local frame of matrix b
  //_matrix.copy( b.matrixWorld ).invert().multiply( a.matrixWorld );
  _matrix = b.matrixWorld;
  _matrix
    ..invert()
    ..multiply(a.matrixWorld);

  //_normalmatrix.getNormalMatrix( a.matrixWorld ).multiplyScalar( invertedGeometry ? -1 : 1);
  _normalMatrix.getNormalMatrix(a.matrixWorld).scale(invertedGeometry ? -1 : 1);

  final groupIndices = a.geometry.groupIndicies;
  final aIndex = a.geometry.index;
  final aPosition = a.geometry.attributes.position;

  final bBVH = b.geometry.boundsTree;
  final bIndex = b.geometry.index;
  final bPosition = b.geometry.attributes.position;
  final splitIds = intersectionMap.ids;
  final intersectionSet = intersectionMap.intersectionSet;

  // iterate over all the split triangle indices
  for (var i = 0; i < splitIds.length; i++) {
    final ia = splitIds[i];
    final groupIndex = groupOffset == -1 ? 0 : groupIndices[ia] + groupOffset;

    // get the triangle in geometry B local frame
    final ia3 = 3 * ia;
    final ia0 = aIndex.getX(ia3 + 0);
    final ia1 = aIndex.getX(ia3 + 1);
    final ia2 = aIndex.getX(ia3 + 2);
    //_triA.a.fromBufferAttribute( aPosition, ia0 ).applyMatrix4( _matrix );
    _triA.a.fromBuffer(aPosition, ia0).applyMatrix4(_matrix);
    _triA.b.fromBuffer(aPosition, ia1).applyMatrix4(_matrix);
    _triA.c.fromBuffer(aPosition, ia2).applyMatrix4(_matrix);

    // initalize the splitter with the triangle from geometry A
    splitter.reset();
    splitter.initialize(_triA);

    // split the triangle with the intersecting triangles from B
    final intersectingIndices = intersectionSet[ia];
    for (var ib = 0, l = intersectingIndices.length; ib < l; ib++) {
      final ib3 = 3 * intersectingIndices[ib];
      final ib0 = bIndex.getX(ib3 + 0);
      final ib1 = bIndex.getX(ib3 + 1);
      final ib2 = bIndex.getX(ib3 + 2);
      _triB.a.fromBuffer(bPosition, ib0);
      _triB.b.fromBuffer(bPosition, ib1);
      _triB.c.fromBuffer(bPosition, ib2);
      splitter.splitByTriangle(_triB);
    }

    // for all triangles in the split result
    final triangles = splitter.triangles;
    for (var ib = 0, l = triangles.length; ib < l; ib++) {
      // get the barycentric coordinates of the clipped triangle to add
      final clippedTri = triangles[ib];

      // try to use the side serived from the clipping but if it turns out to be
      // uncertain then fall back to the raycasting approach
      final hitSide =
          splitter.coplanarTriangleUsed ? getHitSideWithCoplanarCheck(clippedTri, bBVH) : getHitSide(clippedTri, bBVH);

      _attr.length = 0;
      _actions.length = 0;
      for (var o = 0; o < operations.length; o++) {
        final op = getOperationAction(operations[o], hitSide, invert);
        if (op != skipTri) {
          _actions.add(op);
          _attr.add(attributeData[o].getGroupAttrSet(groupIndex));
        }
      }

      if (_attr.isNotEmpty) {
        _triA.getBarycoord(clippedTri.a, _barycoordTri.a);
        _triA.getBarycoord(clippedTri.b, _barycoordTri.b);
        _triA.getBarycoord(clippedTri.c, _barycoordTri.c);

        for (var k = 0, lk = _attr.length; k < lk; k++) {
          final attrSet = _attr[k];
          final action = _actions[k];
          final invertTri_ = action == invertTri;
          appendAttributeFromTriangle(
              ia, _barycoordTri, a.geometry, a.matrixWorld, _normalMatrix, attrSet, invertedGeometry != invertTri_);
        }
      }
    }
  }

  return splitIds.length;
}

// perform CSG operations on the set of whole triangles using a half edge structure
// at the moment this isn't always faster due to overhead of building the half edge
// structure and degraded connectivity due to split triangles.
void performWholeTriangleOperations(dynamic a, dynamic b, dynamic splitTriSet, List<dynamic> operations, bool invert,
    List<dynamic> attributeData, int groupOffset) {
  bool invertedGeometry = a.matrixWorld.determinant() < 0;

  // matrix for transforming into the local frame of geometry b
  //_matrix..copy(b.matrixWorld)..invert()..multiply(a.matrixWorld);
  _matrix = b.matrixWorld;
  _matrix
    ..invert()
    ..multiply(a.matrixWorld);

  //_normalMatrix.getNormalMatrix( a.matrixWorld ).multiplyScalar( invertedGeometry ? -1 : 1 );
  _normalMatrix.setFrom(a.matrixWorld).scale(invertedGeometry ? -1 : 1);

  final bBVH = b.geometry.boundsTree;
  final groupIndices = a.geometry.groupIndices;
  final aIndex = a.geometry.index;
  final aAttributes = a.geometry.attributes;
  final aPosition = aAttributes.position;

  final stack = [];
  final halfEdges = a.geometry.halfEdges;
  final traverseSet = <dynamic>{};
  final triCount = getTriCount(a.geometry);
  for (var i = 0, l = triCount; i < l; i++) {
    if (!splitTriSet.intersectionSet.containsKey(i)) {
      traverseSet.add(i);
    }
  }

  while (traverseSet.isNotEmpty) {
    final id = getFirstIdFromSet(traverseSet);
    traverseSet.remove(id);

    stack.add(id);

    // get the vertex indices
    final i3 = 3 * id;
    final i0 = aIndex.getX(i3 + 0);
    final i1 = aIndex.getX(i3 + 1);
    final i2 = aIndex.getX(i3 + 2);

    // get the vertex position in the frame of geometry b so we can perform hit testing
    //_tri.a.fromBufferAttribute( aPosition, i0 ).applyMatrix4( _matrix );
    _tri.a.fromBuffer(aPosition, i0).applyMatrix4(_matrix);
    _tri.b.fromBuffer(aPosition, i1).applyMatrix4(_matrix);
    _tri.c.fromBuffer(aPosition, i2).applyMatrix4(_matrix);

    // get the side and decide if we need to cull the triangle based on the operation
    final hitSide = getHitSide(_tri, bBVH);

    _actions.length = 0;
    _attr.length = 0;
    for (var o = 0, lo = operations.length; o < lo; o++) {
      final op = getOperationAction(operations[o], hitSide, invert);
      if (op != skipTri) {
        _actions.add(op);
        _attr.add(attributeData[o]);
      }
    }

    while (stack.isNotEmpty) {
      final currId = stack.removeLast();
      for (var i = 0; i < 3; i++) {
        final sid = halfEdges.getSiblingTriangleIndex(currId, i);
        if (sid != -1 && traverseSet.contains(sid)) {
          stack.add(sid);
          traverseSet.remove(sid);
        }
      }

      if (_attr.isNotEmpty) {
        final i3 = 3 * currId;
        final i0 = aIndex.getX(i3 + 0);
        final i1 = aIndex.getX(i3 + 1);
        final i2 = aIndex.getX(i3 + 2);
        final groupIndex = groupOffset == -1 ? 0 : groupIndices[currId] + groupOffset;

        //_tri.a.fromBufferAttribute(aPosition, i0);
        _tri.a.fromBuffer(aPosition, i0);
        _tri.b.fromBuffer(aPosition, i1);
        _tri.c.fromBuffer(aPosition, i2);
        if (!isTriDegenerate(_tri)) {
          for (var k = 0, lk = _attr.length; k < lk; k++) {
            final action = _actions[k];
            final attrSet = _attr[k].getGroupAttrSet(groupIndex);
            final invertTri_ = action == invertTri;
            appendAttributesFromIndices(
                i0, i1, i2, aAttributes, a.matrixWorld, _normalMatrix, attrSet, invertTri_ != invertedGeometry);
          }
        }
      }
    }
  }
}
