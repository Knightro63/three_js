import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import '../intersection_map.dart';
import '../constants.dart';
import '../utils/triangle_utils.dart';
import 'dart:math';

final Ray _ray = Ray();
Matrix4 _matrix = Matrix4();
final Triangle _tri = Triangle();
final Vector3 _vec3 = Vector3();
final Vector4 _vec4a = Vector4();
final Vector4 _vec4b = Vector4();
final Vector4 _vec4c = Vector4();
final Vector4 _vec4_0 = Vector4();
final Vector4 _vec4_1 = Vector4();
final Vector4 _vec4_2 = Vector4();
final Line3 _edge = Line3();
final Vector3 _normal = Vector3();
const jitterEpsilon = 1e-8;
const offsetEpsilon = 1e-15;

const int backSide = -1;
const int frontSide = 1;
const int coplanarOpposite = -2;
const int coplanarAlign = 2;

const int invertTri = 0;
const int addTri = 1;
const int skipTri = 2;

double floatingCoplanarOpposite = 1e-14;

dynamic _debugContext;

void setDebugContext(dynamic debugData) {
  _debugContext = debugData;
}

int getHitSide(Triangle tri, bvh) {
  tri.getMidpoint(_ray.origin);
  tri.getNormal(_ray.direction);

  var hit = bvh.raycastFirst(_ray, DoubleSide);
  var hitBackSide = hit != null && _ray.direction.dot(hit.face.normal) > 0;
  return hitBackSide ? backSide : frontSide;
}

int getHitSideWithCoplanarCheck(Triangle tri, bvh) {
  // random function that returns [ -0.5, 0.5]
  double rand() => Random().nextDouble() - 0.5;

  // get the ray the check the triangle for
  tri.getNormal(_normal);
  // _ray.direction.copy(_normal);
  _ray.direction = _normal;
  tri.getMidpoint(_ray.origin);

  int total = 3;
  int count = 0;
  double minDistance = double.infinity;

  for (int i = 0; i < total; i++) {
    //jitter the ray slightly
    _ray.direction.x += rand() * jitterEpsilon;
    _ray.direction.y += rand() * jitterEpsilon;
    _ray.direction.z += rand() * jitterEpsilon;

    // and invert it so we can account for floating point error by checking
    // both directions to catch coplanar distances
    //_ray.direction.multiplyScalar(-1);
    _ray.direction.scale(-1);

    // check if the ray hit the backside
    var hit = bvh.raycastFirst(_ray, DoubleSide);
    bool hitBackSide = (hit && _ray.direction.dot(hit.face.normal) > 0);

    if (hitBackSide) {
      count++;
    }

    if (hit != null) {
      minDistance = min(minDistance, hit.distance);
    }

    // if we're right up against another face then we're coplanar
    if (minDistance <= offsetEpsilon) {
      return hit.face.normal.dot(_normal) > 0 ? coplanarAlign : coplanarOpposite;
    }

    // if our current casts meet our requirements then early out
    if (count / total > 0.5 || (i - count + 1) / total > 0.5) {
      break;
    }
  }

  return count / total > 0.5 ? backSide : frontSide;
}

// returns the intersected triangles and returns objects mapping triangle
// indicies to the other triangles intersected
Map<String, IntersectionMap> collectIntersectingTriangles(a,b) {
  IntersectionMap aIntersections = IntersectionMap();
  IntersectionMap bIntersections = IntersectionMap();

  //_matrix.copy(a.matrixWorld).invert().multiply(b.matrixWorld);
  _matrix = a.matrixWorld;
  _matrix.invert();
  _matrix.multiply(b.matrixWorld);

  a.geometry.boundsTree.bvhcast(b.geometry.boundsTree, _matrix, (triangleA, triangleB, ia, ib) {
    intersectsTriangles(triangleA, triangleB, ia, ib) {
      if (!isTriDegenerate(triangleA) && !isTriDegenerate(triangleB)) {
        // due to floating point error it's possible that we can have two overlapping, coplanar
        // triangles that are a _tiny_ fraction of a value away from each other. If we find that
        // case then check the distance between triangles and if it's small enough consider them intersecting.
        bool intersected = triangleA.intersectsTriangles(triangleB, _edge, true);
        if (!intersected) {
          var pa = triangleA.plane;
          var pb = triangleB.plane;
          var na = pa.normal;
          var nb = pb.normal;

          if (na.dot(nb) == 1 && (pa.constant - pb.constant).abs() < floatingCoplanarOpposite) {
            intersected = true;
          }
        }

        if (intersected) {
          var va = a.geometry.boundsTree.resolveTriangleIndex(ia);
          var vb = b.geometry.boundsTree.resolveTriangleIndex(ib);
          aIntersections.add(va, vb);
          bIntersections.add(vb, va);

          if (_debugContext != null) {
            _debugContext.addEdge(_edge);
            _debugContext.addIntersectingTriangles(ia, triangleA, ib, triangleB);
          }
        }
      }
      return false;
    }
  });

  //return { aIntersections, bIntersections };
  return {'aIntersections': aIntersections, 'bIntersections': bIntersections};
}

// Add the barycentric interpolated values fro the triangle into the new attribute data
// void appendAttributeFromTriangle(int triIndex, Triangle baryCoordTri, geometry, Matrix4 matrixWorld,
//     Matrix3 normalMatrix, Map<String, List<double>> attributeData,
//     {bool invert = false})
void appendAttributeFromTriangle(int triIndex, Triangle baryCoordTri, BufferGeometry geometry, Matrix4 matrixWorld,
    Matrix3 normalMatrix, Map<String, List<double>> attributeData, bool invert) {
  var attributes = geometry.attributes;
  var indexAttr = geometry.index;
  int i3 = triIndex * 3;
  int i0 = indexAttr!.getX(i3 + 0)!.toInt();
  int i1 = indexAttr.getX(i3 + 1)!.toInt();
  int i2 = indexAttr.getX(i3 + 2)!.toInt();

  //attributes.forEach((key, attr) {
  for (var key in attributeData.keys) {
    // check if the key we're asking for is in the geometry at all
    var attr = attributes[key];
    var arr = attributeData[key];

    if (!attributes.containsKey(key)) {
      throw Exception('CSG Operations: Attribute $key not available on geometry.');
    }

    // replaced instances of 'fromBufferAttribute' with 'fromBuffer'
    // replaced instances of 'multiplyScaler(-1)' with 'scale(-1)'

    // handle normals and positions specifically because they require transforming
    var itemSize = attr.itemSize;
    if (key == 'position') {
      _tri.a.fromBuffer(attr, i0).applyMatrix4(matrixWorld);
      _tri.b.fromBuffer(attr, i1).applyMatrix4(matrixWorld);
      _tri.c.fromBuffer(attr, i2).applyMatrix4(matrixWorld);

      pushBarycoordInterpolatedValues(_tri.a, _tri.b, _tri.c, baryCoordTri, 3, arr!, invert, false);
    } else if (key == 'normal') {
      _tri.a.fromBuffer(attr, i0).applyNormalMatrix(normalMatrix);
      _tri.b.fromBuffer(attr, i1).applyNormalMatrix(normalMatrix);
      _tri.c.fromBuffer(attr, i2).applyNormalMatrix(normalMatrix);

      if (invert) {
        _tri.a.scale(-1);
        _tri.b.scale(-1);
        _tri.c.scale(-1);
      }

      pushBarycoordInterpolatedValues(_tri.a, _tri.b, _tri.c, baryCoordTri, 3, arr!, invert, true);
    } else {
      _vec4a.fromBuffer(attr, i0);
      _vec4b.fromBuffer(attr, i1);
      _vec4c.fromBuffer(attr, i2);

      pushBarycoordInterpolatedValues(_vec4a, _vec4b, _vec4c, baryCoordTri, itemSize, arr!, invert, false);
    }
  }
}

// Append all the values of the attributes for the triangle onto the new attribute arrays
// void appendAttributesFromIndices(int i0, int i1, int i2, Map<String, BufferAttribute> attributes, Matrix4 matrixWorld,
//     Matrix3 normalMatrix, Map<String, List<double>> attributeData,
//     {bool invert = false})
void appendAttributesFromIndices(int i0, int i1, int i2, Map<String, BufferAttribute> attributes, Matrix4 matrixWorld,
    Matrix3 normalMatrix, Map<String, List<double>> attributeData, bool invert) {
  appendAttributeFromIndex(i0, attributes, matrixWorld, normalMatrix, attributeData, invert);
  appendAttributeFromIndex(invert ? i2 : i1, attributes, matrixWorld, normalMatrix, attributeData, invert);
  appendAttributeFromIndex(invert ? i1 : i2, attributes, matrixWorld, normalMatrix, attributeData, invert);
}

// Returns the triangle to add when performing an operation
//int getOperationAction(int operation, int hitSide, {bool invert = false})
int getOperationAction(int operation, int hitSide, bool invert) {
  switch (operation) {
    case ADDITION:
      if (hitSide == frontSide || (hitSide == coplanarAlign && !invert)) {
        return addTri;
      }
      break;

    case SUBTRACTION:
      if (hitSide == backSide) {
        return invertTri;
      } else {
        if (hitSide == frontSide || hitSide == coplanarOpposite) {
          return addTri;
        }
      }
      break;

    case REVERSE_SUBTRACTION:
      if (invert) {
        if (hitSide == frontSide || hitSide == coplanarOpposite) {
          return addTri;
        }
      } else {
        if (hitSide == backSide) {
          return invertTri;
        }
      }
      break;

    case DIFFERENCE:
      if (hitSide == backSide) {
        return invertTri;
      } else if (hitSide == frontSide) {
        return addTri;
      }
      break;

    case INTERSECTION:
      if (hitSide == backSide || (hitSide == coplanarAlign && !invert)) {
        return addTri;
      }
      break;

    case HOLLOW_SUBTRACTION:
      if (!invert && (hitSide == frontSide || hitSide == coplanarOpposite)) {
        return addTri;
      }
      break;

    case HOLLOW_INTERSECTION:
      if (!invert && (hitSide == backSide || hitSide == coplanarAlign)) {
        return addTri;
      }
      break;

    default:
      throw Exception('Unrecognized CSG operation enum $operation .');
  }

  return skipTri;
}

// takes a set of barycentric values in the form of a triangle, a set of vectors, number of components,
// and whether to invert the result and pushes the new values onto the provided attribute arrays
pushBarycoordInterpolatedValues(
    v0, v1, v2, Triangle baryCoordTri, int itemSize, List<double> attrArr, bool invert, bool normalize) {
  // adds the appropriate number of values for the vector onto the array
  void addValues(Vector4 v) {
    attrArr.add(v.x);
    if (itemSize > 1) attrArr.add(v.y);
    if (itemSize > 2) attrArr.add(v.z);
    if (itemSize > 3) attrArr.add(v.w);
  }

  // barycentric interpolate the first component
  //_vec4_0.set(0, 0, 0, 0);
  _vec4_0.setW(0);
  _vec4_0.setX(0);
  _vec4_0.setY(0);
  _vec4_0.setZ(0);
  //..addScaledVector(v0, baryCoordTri.a.x)..
  _vec4_0.addScaled(v0, baryCoordTri.a.x)
    ..addScaled(v1, baryCoordTri.a.y)
    ..addScaled(v2, baryCoordTri.a.z);

  //_vec4_1.set(0, 0, 0, 0);
  _vec4_1.setW(0);
  _vec4_1.setX(0);
  _vec4_1.setY(0);
  _vec4_1.setZ(0);
  //..addScaledVector(v0, baryCoordTri.b.x)..
  _vec4_1.addScaled(v0, baryCoordTri.b.x)
    ..addScaled(v1, baryCoordTri.b.y)
    ..addScaled(v2, baryCoordTri.b.z);

  //_vec4_1.set(0, 0, 0, 0);
  _vec4_2.setW(0);
  _vec4_2.setX(0);
  _vec4_2.setY(0);
  _vec4_2.setZ(0);
  //..addScaledVector(v0, baryCoordTri.c.x)..
  _vec4_2.addScaled(v0, baryCoordTri.c.x)
    ..addScaled(v1, baryCoordTri.c.y)
    ..addScaled(v2, baryCoordTri.c.z);

  if (normalize) {
    _vec4_0.normalize();
    _vec4_1.normalize();
    _vec4_2.normalize();
  }

  // if the face is inverted then add the values in an inverted order
  addValues(_vec4_0);

  if (invert) {
    addValues(_vec4_2);
    addValues(_vec4_1);
  } else {
    addValues(_vec4_1);
    addValues(_vec4_2);
  }
}

// Adds the values for the given vertex index onto the new attribute arrays
appendAttributeFromIndex(int index, Map<String, BufferAttribute> attributes, Matrix4 matrixWorld, Matrix3 normalMatrix,
    Map<String, List<double>> attributeData, bool invert) {
  // check if the key we're asking for is in the geometry at all
  attributeData.forEach((key, attr) {
    var attr = attributes[key];
    var arr = attributeData[key];

    if (attr == null) {
      throw Exception('CSG Operations: Attribute $key no available on geometry.');
    }

    // specially handle the position and normal attributes because they require transforms
    var itemSize = attr.itemSize;

    if (key == 'position') {
      // _vec3.fromBufferAttribute(attr, index).applyMatrix4(matrixWorld);
      // arr.push(_vec3.x, _vec3.y, _vec3.z);
      _vec3.fromBuffer(attr, index).applyMatrix4(matrixWorld);
      arr?.addAll({_vec3.x, _vec3.y, _vec3.z});
    } else if (key == 'normal') {
      // _vec3.fromBufferAttribute(attr, index).applyNormalMatrix(normalMatrix);
      _vec3.fromBuffer(attr, index).applyNormalMatrix(normalMatrix);

      if (invert) {
        //_vec3.multiplyScalar(-1)
        _vec3.scale(-1);
      }

      //arr.push( _vec3.x, _vec3.y, _vec3.z );
      arr?.addAll({_vec3.x, _vec3.y, _vec3.z});
    } else {
      // arr.push( attr.getX( index ) );
      // if ( itemSize > 1 ) arr.push( attr.getY( index ) );
      arr?.add((attr.getX(index))!.toDouble());
      if (itemSize > 1) arr?.add((attr.getY(index))!.toDouble());
      if (itemSize > 2) arr?.add((attr.getZ(index))!.toDouble());
      if (itemSize > 3) arr?.add((attr.getW(index))!.toDouble());
    }
  });
}
