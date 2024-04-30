import 'dart:math' as math;
import 'package:three_js_math/three_js_math.dart';

class SVGLoaderPointsToStroke {
  Vector2 tempV2_1 = Vector2();
  Vector2 tempV2_2 = Vector2();
  Vector2 tempV2_3 = Vector2();
  Vector2 tempV2_4 = Vector2();
  Vector2 tempV2_5 = Vector2();
  Vector2 tempV2_6 = Vector2();
  Vector2 tempV2_7 = Vector2();
  Vector2 lastPointL = Vector2();
  Vector2 lastPointR = Vector2();
  Vector2 point0L = Vector2();
  Vector2 point0R = Vector2();
  Vector2 currentPointL = Vector2();
  Vector2 currentPointR = Vector2();
  Vector2 nextPointL = Vector2();
  Vector2 nextPointR = Vector2();
  Vector2 innerPoint = Vector2();
  Vector2 outerPoint = Vector2();

  int arcDivisions = 12;
  num minDistance = 0.001;
  int vertexOffset = 0;

  late List<Vector2> points;
  late dynamic style;

  List<double> vertices = List<double>.of([], growable: true);
  List<double> normals = List<double>.of([], growable: true);
  List<double> uvs = List<double>.of([], growable: true);

  int numVertices = 0;
  late Vector2 currentPoint;

  // This function can be called to update existing arrays or buffers.
  // Accepts same parameters as pointsToStroke, plus the buffers and optional offset.
  // Param vertexOffset: Offset vertices to start writing in the buffers (3 elements/vertex for vertices and normals, and 2 elements/vertex for uvs)
  // Returns number of written vertices / normals / uvs pairs
  // if 'vertices' parameter is null no triangles will be generated, but the returned vertices count will still be valid (useful to preallocate the buffers)
  // 'normals' and 'uvs' buffers are optional
  int currentCoordinate = 0;
  int currentCoordinateUV = 0;

  num u0 = 0.0;

  SVGLoaderPointsToStroke(
    List<Vector?> points, 
    this.style, 
    int? arcDivisions, 
    double? minDistance, 
    this.vertices,
    this.normals, 
    this.uvs, 
    int? vertexOffset
  ) {
    this.arcDivisions = arcDivisions ?? 12;
    this.minDistance = minDistance ?? 0.001;
    this.vertexOffset = vertexOffset ?? 0;

    // First ensure there are no duplicated points
    this.points = removeDuplicatedPoints(points);
    currentCoordinate = this.vertexOffset * 3;
    currentCoordinateUV = this.vertexOffset * 2;
  }

  int convert() {
    final numPoints = points.length;

    if (numPoints < 2) return 0;

    final isClosed = points[0].equals(points[numPoints - 1]);

    Vector2 previousPoint = points[0];
    Vector2? nextPoint;

    final strokeWidth2 = style["strokeWidth"] / 2;

    final deltaU = 1 / (numPoints - 1);

    bool innerSideModified = false;
    bool joinIsOnLeftSide = false;
    bool isMiter = false;
    bool initialJoinIsOnLeftSide = false;
    num u1 = 0;

    // Get initial left and right stroke points
    getNormal(points[0], points[1], tempV2_1).scale(strokeWidth2);
    lastPointL.setFrom(points[0]).sub(tempV2_1);
    lastPointR.setFrom(points[0]).add(tempV2_1);
    point0L.setFrom(lastPointL);
    point0R.setFrom(lastPointR);

    for (int iPoint = 1; iPoint < numPoints; iPoint++) {
      currentPoint = points[iPoint];

      // Get next point
      if (iPoint == numPoints - 1) {
        if (isClosed) {
          // Skip duplicated initial point
          nextPoint = points[1];
        } else {
          nextPoint = null;
        }
      } else {
        nextPoint = points[iPoint + 1];
      }

      // Normal of previous segment in tempV2_1
      final normal1 = tempV2_1;
      getNormal(previousPoint, currentPoint, normal1);

      tempV2_3.setFrom(normal1).scale(strokeWidth2);
      currentPointL.setFrom(currentPoint).sub(tempV2_3);
      currentPointR.setFrom(currentPoint).add(tempV2_3);

      u1 = u0 + deltaU;

      innerSideModified = false;

      if (nextPoint != null) {
        // Normal of next segment in tempV2_2
        getNormal(currentPoint, nextPoint, tempV2_2);

        tempV2_3.setFrom(tempV2_2).scale(strokeWidth2);
        nextPointL.setFrom(currentPoint).sub(tempV2_3);
        nextPointR.setFrom(currentPoint).add(tempV2_3);

        joinIsOnLeftSide = true;
        tempV2_3.sub2(nextPoint, previousPoint);
        if (normal1.dot(tempV2_3) < 0) {
          joinIsOnLeftSide = false;
        }

        if (iPoint == 1) initialJoinIsOnLeftSide = joinIsOnLeftSide;

        tempV2_3.sub2(nextPoint, currentPoint);
        tempV2_3.normalize();
        final dot = normal1.dot(tempV2_3).abs();

        // If path is straight, don't create join
        if (dot != 0) {
          // Compute inner and outer segment intersections
          final miterSide = strokeWidth2 / dot;
          tempV2_3.scale(-miterSide);
          tempV2_4.sub2(currentPoint, previousPoint);
          tempV2_5.setFrom(tempV2_4).setLength(miterSide).add(tempV2_3);
          innerPoint.setFrom(tempV2_5).negate();
          final miterLength2 = tempV2_5.length;
          final segmentLengthPrev = tempV2_4.length;
          tempV2_4.divideScalar(segmentLengthPrev);
          tempV2_6.sub2(nextPoint, currentPoint);
          final segmentLengthNext = tempV2_6.length;
          tempV2_6.divideScalar(segmentLengthNext);
          // Check that previous and next segments doesn't overlap with the innerPoint of intersection
          if (tempV2_4.dot(innerPoint) < segmentLengthPrev &&
              tempV2_6.dot(innerPoint) < segmentLengthNext) {
            innerSideModified = true;
          }

          outerPoint.setFrom(tempV2_5).add(currentPoint);
          innerPoint.add(currentPoint);

          isMiter = false;

          if (innerSideModified) {
            if (joinIsOnLeftSide) {
              nextPointR.setFrom(innerPoint);
              currentPointR.setFrom(innerPoint);
            } else {
              nextPointL.setFrom(innerPoint);
              currentPointL.setFrom(innerPoint);
            }
          } else {
            // The segment triangles are generated here if there was overlapping

            makeSegmentTriangles(u1);
          }

          switch (style["strokeLineJoin"]) {
            case 'bevel':
              makeSegmentWithBevelJoin(
                  joinIsOnLeftSide, innerSideModified, u1, u1);

              break;

            case 'round':

              // Segment triangles

              createSegmentTrianglesWithMiddleSection(
                  joinIsOnLeftSide, innerSideModified, u1);

              // Join triangles

              if (joinIsOnLeftSide) {
                makeCircularSector(
                    currentPoint, currentPointL, nextPointL, u1, 0);
              } else {
                makeCircularSector(
                    currentPoint, nextPointR, currentPointR, u1, 1);
              }

              break;

            case 'miter':
            case 'miter-clip':
            default:
              final miterFraction =
                  (strokeWidth2 * style["strokeMiterLimit"]) / miterLength2;

              if (miterFraction < 1) {
                // The join miter length exceeds the miter limit

                if (style["strokeLineJoin"] != 'miter-clip') {
                  makeSegmentWithBevelJoin(
                      joinIsOnLeftSide, innerSideModified, u1, u1);
                  break;
                } else {
                  // Segment triangles

                  createSegmentTrianglesWithMiddleSection(
                      joinIsOnLeftSide, innerSideModified, u1);

                  // Miter-clip join triangles

                  if (joinIsOnLeftSide) {
                    tempV2_6.sub2(outerPoint, currentPointL)
                        .scale(miterFraction)
                        .add(currentPointL);
                    tempV2_7.sub2(outerPoint, nextPointL)
                        .scale(miterFraction)
                        .add(nextPointL);

                    addVertex(currentPointL, u1, 0);
                    addVertex(tempV2_6, u1, 0);
                    addVertex(currentPoint, u1, 0.5);

                    addVertex(currentPoint, u1, 0.5);
                    addVertex(tempV2_6, u1, 0);
                    addVertex(tempV2_7, u1, 0);

                    addVertex(currentPoint, u1, 0.5);
                    addVertex(tempV2_7, u1, 0);
                    addVertex(nextPointL, u1, 0);
                  } else {
                    tempV2_6.sub2(outerPoint, currentPointR)
                        .scale(miterFraction)
                        .add(currentPointR);
                    tempV2_7.sub2(outerPoint, nextPointR)
                        .scale(miterFraction)
                        .add(nextPointR);

                    addVertex(currentPointR, u1, 1);
                    addVertex(tempV2_6, u1, 1);
                    addVertex(currentPoint, u1, 0.5);

                    addVertex(currentPoint, u1, 0.5);
                    addVertex(tempV2_6, u1, 1);
                    addVertex(tempV2_7, u1, 1);

                    addVertex(currentPoint, u1, 0.5);
                    addVertex(tempV2_7, u1, 1);
                    addVertex(nextPointR, u1, 1);
                  }
                }
              } else {
                // Miter join segment triangles

                if (innerSideModified) {
                  // Optimized segment + join triangles

                  if (joinIsOnLeftSide) {
                    addVertex(lastPointR, u0, 1);
                    addVertex(lastPointL, u0, 0);
                    addVertex(outerPoint, u1, 0);

                    addVertex(lastPointR, u0, 1);
                    addVertex(outerPoint, u1, 0);
                    addVertex(innerPoint, u1, 1);
                  } else {
                    addVertex(lastPointR, u0, 1);
                    addVertex(lastPointL, u0, 0);
                    addVertex(outerPoint, u1, 1);

                    addVertex(lastPointL, u0, 0);
                    addVertex(innerPoint, u1, 0);
                    addVertex(outerPoint, u1, 1);
                  }

                  if (joinIsOnLeftSide) {
                    nextPointL.setFrom(outerPoint);
                  } else {
                    nextPointR.setFrom(outerPoint);
                  }
                } else {
                  // Add extra miter join triangles

                  if (joinIsOnLeftSide) {
                    addVertex(currentPointL, u1, 0);
                    addVertex(outerPoint, u1, 0);
                    addVertex(currentPoint, u1, 0.5);

                    addVertex(currentPoint, u1, 0.5);
                    addVertex(outerPoint, u1, 0);
                    addVertex(nextPointL, u1, 0);
                  } else {
                    addVertex(currentPointR, u1, 1);
                    addVertex(outerPoint, u1, 1);
                    addVertex(currentPoint, u1, 0.5);

                    addVertex(currentPoint, u1, 0.5);
                    addVertex(outerPoint, u1, 1);
                    addVertex(nextPointR, u1, 1);
                  }
                }

                isMiter = true;
              }

              break;
          }
        } else {
          // The segment triangles are generated here when two consecutive points are collinear

          makeSegmentTriangles(u1);
        }
      } else {
        // The segment triangles are generated here if it is the ending segment

        makeSegmentTriangles(u1);
      }

      if (!isClosed && iPoint == numPoints - 1) {
        // Start line endcap
        addCapGeometry(points[0], point0L, point0R, joinIsOnLeftSide, true, u0);
      }

      // Increment loop variables

      u0 = u1;

      previousPoint = currentPoint;

      lastPointL.setFrom(nextPointL);
      lastPointR.setFrom(nextPointR);
    }

    if (!isClosed) {
      // Ending line endcap
      addCapGeometry(currentPoint, currentPointL, currentPointR,
          joinIsOnLeftSide, false, u1);
    } else if (innerSideModified) {
      // Modify path first segment vertices to adjust to the segments inner and outer intersections

      Vector2 lastOuter = outerPoint;
      Vector2 lastInner = innerPoint;

      if (initialJoinIsOnLeftSide != joinIsOnLeftSide) {
        lastOuter = innerPoint;
        lastInner = outerPoint;
      }

      if (joinIsOnLeftSide) {
        if (isMiter || initialJoinIsOnLeftSide) {
          lastInner.copyIntoArray(vertices, 0 * 3);
          lastInner.copyIntoArray(vertices, 3 * 3);

          if (isMiter) {
            lastOuter.copyIntoArray(vertices, 1 * 3);
          }
        }
      } else {
        if (isMiter || !initialJoinIsOnLeftSide) {
          lastInner.copyIntoArray(vertices, 1 * 3);
          lastInner.copyIntoArray(vertices, 3 * 3);

          if (isMiter) {
            lastOuter.copyIntoArray(vertices, 0 * 3);
          }
        }
      }
    }

    return numVertices;

    // -- End of algorithm
  }

  List<Vector2> removeDuplicatedPoints(List<Vector?> points) {
    // Creates a new array if necessary with duplicated points removed.
    // This does not remove duplicated initial and ending points of a closed path.

    bool dupPoints = false;
    final List<Vector2> convPoints = [];
    for (int i = 0; i < points.length-1; i++) {
      if (points[i]!.distanceTo(points[i + 1]!) < minDistance) {
        dupPoints = true;
        break;
      }

      convPoints.add(Vector2(points[i]!.x,points[i]!.y));
    }
    convPoints.add(Vector2(points[points.length - 1]!.x,points[points.length - 1]!.y));

    if (!dupPoints) return convPoints;

    final List<Vector2> newPoints = [];
    newPoints.add(Vector2(points[0]!.x,points[0]!.y));

    for (int i = 1, n = points.length - 1; i < n; i++) {
      if (points[i]!.distanceTo(points[i + 1]!) >= minDistance) {
        newPoints.add(Vector2(points[i]!.x,points[i]!.y));
      }
    }

    newPoints.add(Vector2(points[points.length - 1]!.x,points[points.length - 1]!.y));

    return newPoints;
  }

  Vector2 getNormal(Vector2 p1, Vector2 p2, Vector2 result) {
    result.sub2(p2, p1);
    return result.setValues(-result.y, result.x).normalize();
  }

  void addVertex(Vector2 position, num u, num v) {
    vertices.listSetter(currentCoordinate, position.x);
    // vertices[ currentCoordinate + 1 ] = position.y;
    vertices.listSetter( currentCoordinate + 1, position.y);
    // vertices[ currentCoordinate + 2 ] = 0;
    vertices.listSetter( currentCoordinate + 2, 0.0);
    normals.listSetter( currentCoordinate, 0.0);
    // normals[ currentCoordinate + 1 ] = 0;
    normals.listSetter( currentCoordinate + 1, 0.0);
    // normals[ currentCoordinate + 2 ] = 1;
    normals.listSetter(currentCoordinate + 2, 1.0);

    currentCoordinate += 3;
    uvs.listSetter(currentCoordinateUV, u.toDouble());
    // uvs[ currentCoordinateUV + 1 ] = v;
    uvs.listSetter(currentCoordinateUV + 1, v.toDouble());

    currentCoordinateUV += 2;
    numVertices += 3;
  }

  void makeCircularSector(Vector2 center, Vector2 p1, Vector2 p2, num u, num v) {
    // param p1, p2: Points in the circle arc.
    // p1 and p2 are in clockwise direction.

    tempV2_1.setFrom(p1).sub(center).normalize();
    tempV2_2.setFrom(p2).sub(center).normalize();

    double angle = math.pi;
    final dot = tempV2_1.dot(tempV2_2);
    if (dot.abs() < 1) angle = (math.acos(dot)).abs();

    angle /= arcDivisions;

    tempV2_3.setFrom(p1);

    for (int i = 0, il = arcDivisions - 1; i < il; i++) {
      tempV2_4.setFrom(tempV2_3).rotateAround(center, angle);

      addVertex(tempV2_3, u, v);
      addVertex(tempV2_4, u, v);
      addVertex(center, u, 0.5);

      tempV2_3.setFrom(tempV2_4);
    }

    addVertex(tempV2_4, u, v);
    addVertex(p2, u, v);
    addVertex(center, u, 0.5);
  }

  void makeSegmentTriangles(num u1) {
    addVertex(lastPointR, u0, 1);
    addVertex(lastPointL, u0, 0);
    addVertex(currentPointL, u1, 0);

    addVertex(lastPointR, u0, 1);
    addVertex(currentPointL, u1, 1);
    addVertex(currentPointR, u1, 0);
  }

  void makeSegmentWithBevelJoin(bool joinIsOnLeftSide, bool innerSideModified, num u, num u1) {
    if (innerSideModified) {
      // Optimized segment + bevel triangles

      if (joinIsOnLeftSide) {
        // Path segments triangles

        addVertex(lastPointR, u0, 1);
        addVertex(lastPointL, u0, 0);
        addVertex(currentPointL, u1, 0);

        addVertex(lastPointR, u0, 1);
        addVertex(currentPointL, u1, 0);
        addVertex(innerPoint, u1, 1);

        // Bevel join triangle

        addVertex(currentPointL, u, 0);
        addVertex(nextPointL, u, 0);
        addVertex(innerPoint, u, 0.5);
      } else {
        // Path segments triangles

        addVertex(lastPointR, u0, 1);
        addVertex(lastPointL, u0, 0);
        addVertex(currentPointR, u1, 1);

        addVertex(lastPointL, u0, 0);
        addVertex(innerPoint, u1, 0);
        addVertex(currentPointR, u1, 1);

        // Bevel join triangle

        addVertex(currentPointR, u, 1);
        addVertex(nextPointR, u, 0);
        addVertex(innerPoint, u, 0.5);
      }
    } else {
      // Bevel join triangle. The segment triangles are done in the main loop

      if (joinIsOnLeftSide) {
        addVertex(currentPointL, u, 0);
        addVertex(nextPointL, u, 0);
        addVertex(currentPoint, u, 0.5);
      } else {
        addVertex(currentPointR, u, 1);
        addVertex(nextPointR, u, 0);
        addVertex(currentPoint, u, 0.5);
      }
    }
  }

  void createSegmentTrianglesWithMiddleSection(bool joinIsOnLeftSide, bool innerSideModified, num u1) {
    if (innerSideModified) {
      if (joinIsOnLeftSide) {
        addVertex(lastPointR, u0, 1);
        addVertex(lastPointL, u0, 0);
        addVertex(currentPointL, u1, 0);

        addVertex(lastPointR, u0, 1);
        addVertex(currentPointL, u1, 0);
        addVertex(innerPoint, u1, 1);

        addVertex(currentPointL, u0, 0);
        addVertex(currentPoint, u1, 0.5);
        addVertex(innerPoint, u1, 1);

        addVertex(currentPoint, u1, 0.5);
        addVertex(nextPointL, u0, 0);
        addVertex(innerPoint, u1, 1);
      } else {
        addVertex(lastPointR, u0, 1);
        addVertex(lastPointL, u0, 0);
        addVertex(currentPointR, u1, 1);

        addVertex(lastPointL, u0, 0);
        addVertex(innerPoint, u1, 0);
        addVertex(currentPointR, u1, 1);

        addVertex(currentPointR, u0, 1);
        addVertex(innerPoint, u1, 0);
        addVertex(currentPoint, u1, 0.5);

        addVertex(currentPoint, u1, 0.5);
        addVertex(innerPoint, u1, 0);
        addVertex(nextPointR, u0, 1);
      }
    }
  }

  void addCapGeometry(Vector2 center, Vector2 p1, Vector2 p2, bool joinIsOnLeftSide, bool start, num u) {
    // param center: End point of the path
    // param p1, p2: Left and right cap points

    switch (style["strokeLineCap"]) {
      case 'round':
        if (start) {
          makeCircularSector(center, p2, p1, u, 0.5);
        } else {
          makeCircularSector(center, p1, p2, u, 0.5);
        }

        break;

      case 'square':
        if (start) {
          tempV2_1.sub2(p1, center);
          tempV2_2.setValues(tempV2_1.y, -tempV2_1.x);

          tempV2_3.add2(tempV2_1, tempV2_2).add(center);
          tempV2_4.sub2(tempV2_2, tempV2_1).add(center);

          // Modify already existing vertices
          if (joinIsOnLeftSide) {
            tempV2_3.copyIntoArray(vertices, 1 * 3);
            tempV2_4.copyIntoArray(vertices, 0 * 3);
            tempV2_4.copyIntoArray(vertices, 3 * 3);
          } else {
            tempV2_3.copyIntoArray(vertices, 1 * 3);
            tempV2_3.copyIntoArray(vertices, 3 * 3);
            tempV2_4.copyIntoArray(vertices, 0 * 3);
          }
        } else {
          tempV2_1.sub2(p2, center);
          tempV2_2.setValues(tempV2_1.y, -tempV2_1.x);

          tempV2_3.add2(tempV2_1, tempV2_2).add(center);
          tempV2_4.sub2(tempV2_2, tempV2_1).add(center);

          final vl = vertices.length;

          // Modify already existing vertices
          if (joinIsOnLeftSide) {
            tempV2_3.copyIntoArray(vertices, vl - 1 * 3);
            tempV2_4.copyIntoArray(vertices, vl - 2 * 3);
            tempV2_4.copyIntoArray(vertices, vl - 4 * 3);
          } else {
            tempV2_3.copyIntoArray(vertices, vl - 2 * 3);
            tempV2_4.copyIntoArray(vertices, vl - 1 * 3);
            tempV2_4.copyIntoArray(vertices, vl - 4 * 3);
          }
        }

        break;

      case 'butt':
      default:

        // Nothing to do here
        break;
    }
  }
}
