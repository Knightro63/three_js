import 'dart:math' as math;
import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

final Vector3 _tempNormal = Vector3();

/// Helper function to access vector component via string key dynamically
double _getComponent(Vector3 vec, String axis) {
  switch (axis) {
    case 'x': return vec.x;
    case 'y': return vec.y;
    case 'z': return vec.z;
    default: return 0.0;
  }
}

double _getUv(
  Vector3 faceDirVector,
  Vector3 normal,
  String uvAxis,
  String projectionAxis,
  double radius,
  double sideLength,
) {
  final double totArcLength = 2 * math.pi * radius / 4;
  
  // Length of the planes between the arcs on each axis
  final double centerLength = math.max(sideLength - 2 * radius, 0.0);
  final double halfArc = math.pi / 4;

  // Get the vector projected onto the complementary plane
  _tempNormal.setFrom(normal);
  
  // Explicitly clear the projection axis component
  if (projectionAxis == 'x') _tempNormal.x = 0;
  if (projectionAxis == 'y') _tempNormal.y = 0;
  if (projectionAxis == 'z') _tempNormal.z = 0;
  
  _tempNormal.normalize();

  // Total amount of UV space allotted to a single arc
  final double arcUvRatio = 0.5 * totArcLength / (totArcLength + centerLength);
  
  // The distance along one arc the point is at
  final double arcAngleRatio = 1.0 - (_tempNormal.angleTo(faceDirVector) / halfArc);

  final double uvAxisValue = _getComponent(_tempNormal, uvAxis);

  if (uvAxisValue.sign == 1.0 || uvAxisValue == 0.0) {
    return arcAngleRatio * arcUvRatio;
  } else {
    // Total amount of UV space allotted to the plane between the arcs
    final double lenUv = centerLength / (totArcLength + centerLength);
    return lenUv + arcUvRatio + arcUvRatio * (1.0 - arcAngleRatio);
  }
}

/// A special type of box geometry with rounded corners and edges.
class RoundedBoxGeometry extends BoxGeometry {
  Map<String, dynamic>? parameters;

  RoundedBoxGeometry({
    double width = 1.0,
    double height = 1.0,
    double depth = 1.0,
    int segments = 2,
    double radius = 0.1,
  }) : super(
         1.0,
         1.0,
         1.0,
         (segments * 2 + 1),
         (segments * 2 + 1),
         (segments * 2 + 1),
       ) {
    type = 'RoundedBoxGeometry';

    final int totalSegments = segments * 2 + 1;

    // Ensure radius isn't bigger than half of the shortest side
    double finalRadius = math.min(
      math.min(width / 2.0, height / 2.0),
      math.min(depth / 2.0, radius),
    );

    parameters = {
      'width': width,
      'height': height,
      'depth': depth,
      'segments': segments,
      'radius': finalRadius,
    };

    if (totalSegments == 1) return;

    // Convert geometry to non-indexed layout
    final BufferGeometry geometry2 = toNonIndexed();
    index = null;
    
    // Assign converted buffer attributes
    attributes['position'] = geometry2.attributes['position']!;
    attributes['normal'] = geometry2.attributes['normal']!;
    attributes['uv'] = geometry2.attributes['uv']!;

    final Vector3 position = Vector3();
    final Vector3 normal = Vector3();
    final Vector3 box = Vector3(width, height, depth).divideScalar(2.0).subScalar(finalRadius);

    // Retrieve underlying arrays safely via the buffer property
    final Float32List positions = attributes['position']!.array;
    final normals = attributes['normal']!.array;
    final uvs = attributes['uv']!.array;

    final double faceTris = positions.length / 6.0;
    final Vector3 faceDirVector = Vector3();
    final double halfSegmentSize = 0.5 / totalSegments;

    for (int i = 0, j = 0; i < positions.length; i += 3, j += 2) {
      position.fromArray(positions, i);
      normal.setFrom(position);
      
      normal.x -= position.x.sign * halfSegmentSize;
      normal.y -= position.y.sign * halfSegmentSize;
      normal.z -= position.z.sign * halfSegmentSize;
      normal.normalize();

      positions[i + 0] = box.x * position.x.sign + normal.x * finalRadius;
      positions[i + 1] = box.y * position.y.sign + normal.y * finalRadius;
      positions[i + 2] = box.z * position.z.sign + normal.z * finalRadius;

      normals[i + 0] = normal.x;
      normals[i + 1] = normal.y;
      normals[i + 2] = normal.z;

      final int side = (i / faceTris).floor();

      switch (side) {
        case 0: // Right
          faceDirVector.setValues(1.0, 0.0, 0.0);
          uvs[j + 0] = _getUv(faceDirVector, normal, 'z', 'y', finalRadius, depth);
          uvs[j + 1] = 1.0 - _getUv(faceDirVector, normal, 'y', 'z', finalRadius, height);
          break;
        case 1: // Left
          faceDirVector.setValues(-1.0, 0.0, 0.0);
          uvs[j + 0] = 1.0 - _getUv(faceDirVector, normal, 'z', 'y', finalRadius, depth);
          uvs[j + 1] = 1.0 - _getUv(faceDirVector, normal, 'y', 'z', finalRadius, height);
          break;
        case 2: // Top
          faceDirVector.setValues(0.0, 1.0, 0.0);
          uvs[j + 0] = 1.0 - _getUv(faceDirVector, normal, 'x', 'z', finalRadius, width);
          uvs[j + 1] = _getUv(faceDirVector, normal, 'z', 'x', finalRadius, depth);
          break;
        case 3: // Bottom
          faceDirVector.setValues(0.0, -1.0, 0.0);
          uvs[j + 0] = 1.0 - _getUv(faceDirVector, normal, 'x', 'z', finalRadius, width);
          uvs[j + 1] = 1.0 - _getUv(faceDirVector, normal, 'z', 'x', finalRadius, depth);
          break;
        case 4: // Front
          faceDirVector.setValues(0.0, 0.0, 1.0);
          uvs[j + 0] = 1.0 - _getUv(faceDirVector, normal, 'x', 'y', finalRadius, width);
          uvs[j + 1] = 1.0 - _getUv(faceDirVector, normal, 'y', 'x', finalRadius, height);
          break;
        case 5: // Back
          faceDirVector.setValues(0.0, 0.0, -1.0);
          uvs[j + 0] = _getUv(faceDirVector, normal, 'x', 'y', finalRadius, width);
          uvs[j + 1] = 1.0 - _getUv(faceDirVector, normal, 'y', 'x', finalRadius, height);
          break;
      }
    }
    
    // Explicitly notify the GPU that the data buffers were altered
    attributes['position']!.needsUpdate = true;
    attributes['normal']!.needsUpdate = true;
    attributes['uv']!.needsUpdate = true;
  }

  /// Factory constructor to map standard JSON format serialization
  factory RoundedBoxGeometry.fromJSON(Map<String, dynamic> data) {
    return RoundedBoxGeometry(
      width: data['width']?.toDouble() ?? 1.0,
      height: data['height']?.toDouble() ?? 1.0,
      depth: data['depth']?.toDouble() ?? 1.0,
      segments: data['segments']?.toInt() ?? 2,
      radius: data['radius']?.toDouble() ?? 0.1,
    );
  }
}
