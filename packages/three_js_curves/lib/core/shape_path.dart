import 'path.dart';
import 'shape.dart';
import '../utils/shape_utils.dart';
import 'package:three_js_math/three_js_math.dart';

/// This class is used to convert a series of shapes to an array of
/// [Path]s, for example an SVG shape to a path.
class ShapePath {
  String type = "ShapePath";
  Color color = Color(1, 1, 1);
  List<Path> subPaths = [];
  late Path currentPath;
  Map<String, dynamic>? userData;

  /// Creates a new ShapePath. Unlike a [Path], no points are passed in as
  /// the ShapePath is designed to be generated after creation.
  ShapePath();

  /// Starts a new [Path] and calls [Path.moveTo]( x, y ) on that
  /// [Path]. Also points [ShapePath.currentPath currentPath] to that
  /// [Path].
  ShapePath moveTo(double x, double y) {
    currentPath = Path(null);
    subPaths.add(currentPath);
    currentPath.moveTo(x, y);
    return this;
  }

  /// This creates a line from the [currentPath]'s
  /// offset to X and Y and updates the offset to X and Y.
  ShapePath lineTo(double x, double y) {
    currentPath.lineTo(x, y);
    return this;
  }

  /// This creates a quadratic curve from the [currentPath]'s offset to x and y with cpX and cpY as control point and
  /// updates the [currentPath]'s offset to x and y.
  ShapePath quadraticCurveTo(double aCPx, double aCPy, double aX, double aY) {
    currentPath.quadraticCurveTo(aCPx, aCPy, aX, aY);
    return this;
  }

  /// This creates a bezier curve from the [currentPath]'s offset to x and y with cp1X, cp1Y and cp2X, cp2Y as control
  /// points and updates the [currentPath]'s offset
  /// to x and y.
  ShapePath bezierCurveTo(double aCP1x, double aCP1y, double aCP2x, double aCP2y, double aX, double aY) {
    currentPath.bezierCurveTo(aCP1x, aCP1y, aCP2x, aCP2y, aX, aY);
    return this;
  }

  /// Connects a new [SplineCurve] onto the [currentPath].
  ShapePath splineThru(List<Vector2> pts) {
    currentPath.splineThru(pts);
    return this;
  }

  /// Converts the [subPaths] array into an array of
  /// Shapes. By default solid shapes are defined clockwise (CW) and holes are
  /// defined counterclockwise (CCW). If isCCW is set to true, then those are
  /// flipped.
  List<Shape> toShapes(bool isCCW, bool noHoles) {
    toShapesNoHoles(inSubpaths) {
      List<Shape> shapes = [];

      for (int i = 0, l = inSubpaths.length; i < l; i++) {
        final tmpPath = inSubpaths[i];

        final tmpShape = Shape(null);
        tmpShape.curves = tmpPath.curves;

        shapes.add(tmpShape);
      }

      return shapes;
    }

    bool isPointInsidePolygon(Vector2 inPt, List<Vector2> inPolygon) {
      final polyLen = inPolygon.length;

      // inPt on polygon contour => immediate success    or
      // toggling of inside/outside at every single! intersection point of an edge
      //  with the horizontal line through inPt, left of inPt
      //  not counting lowerY endpoints of edges and whole edges on that line
      bool inside = false;
      for (int p = polyLen - 1, q = 0; q < polyLen; p = q++) {
        Vector2 edgeLowPt = inPolygon[p];
        Vector2 edgeHighPt = inPolygon[q];

        double edgeDx = edgeHighPt.x - edgeLowPt.x;
        double edgeDy = edgeHighPt.y - edgeLowPt.y;

        if (edgeDy.abs() > MathUtils.epsilon) {
          // not parallel
          if (edgeDy < 0) {
            edgeLowPt = inPolygon[q];
            edgeDx = -edgeDx;
            edgeHighPt = inPolygon[p];
            edgeDy = -edgeDy;
          }

          if ((inPt.y < edgeLowPt.y) || (inPt.y > edgeHighPt.y)) continue;

          if (inPt.y == edgeLowPt.y) {
            if (inPt.x == edgeLowPt.x) return true; // inPt is on contour ?
            // continue;				// no intersection or edgeLowPt => doesn't count !!!

          } else {
            double perpEdge = edgeDy * (inPt.x - edgeLowPt.x) -
                edgeDx * (inPt.y - edgeLowPt.y);
            if (perpEdge == 0) return true; // inPt is on contour ?
            if (perpEdge < 0) continue;
            inside = !inside; // true intersection left of inPt

          }
        } else {
          // parallel or collinear
          if (inPt.y != edgeLowPt.y) continue; // parallel
          // edge lies on the same horizontal line as inPt
          if (((edgeHighPt.x <= inPt.x) && (inPt.x <= edgeLowPt.x)) ||
              ((edgeLowPt.x <= inPt.x) && (inPt.x <= edgeHighPt.x))) {
            return true;
          } // inPt: Point on contour !
          // continue;

        }
      }

      return inside;
    }

    const isClockWise = ShapeUtils.isClockWise;

    final subPaths = this.subPaths;
    if (subPaths.isEmpty) return [];

    if (noHoles == true) return toShapesNoHoles(subPaths);

    bool solid;
    Path tmpPath;
    Shape tmpShape;
    List<Shape> shapes = [];

    if (subPaths.length == 1) {
      tmpPath = subPaths[0];
      tmpShape = Shape();
      tmpShape.curves = tmpPath.curves;
      shapes.add(tmpShape);
      return shapes;
    }

    bool holesFirst = !isClockWise(subPaths[0].getPoints());
    holesFirst = isCCW ? !holesFirst : holesFirst;

    // Console.log("Holes first", holesFirst);

    dynamic betterShapeHoles = [];
    final newShapes = [];
    List newShapeHoles = [];
    int mainIdx = 0;
    List<Vector?> tmpPoints;

    // newShapes[ mainIdx ] = null;
    newShapes.listSetter(mainIdx, null);

    // newShapeHoles[ mainIdx ] = [];
    newShapeHoles.listSetter(mainIdx, []);

    for (int i = 0, l = subPaths.length; i < l; i++) {
      tmpPath = subPaths[i];
      tmpPoints = tmpPath.getPoints();
      solid = isClockWise(tmpPoints);
      solid = isCCW ? !solid : solid;

      if (solid) {
        if ((!holesFirst) && (newShapes[mainIdx] != null)) mainIdx++;

        // newShapes[ mainIdx ] = { "s": Shape(null), "p": tmpPoints };
        newShapes.listSetter(mainIdx, {"s": Shape(null), "p": tmpPoints});

        newShapes[mainIdx]["s"].curves = tmpPath.curves;

        if (holesFirst) mainIdx++;
        // newShapeHoles[ mainIdx ] = [];
        newShapeHoles.listSetter(mainIdx, []);

        //Console.log('cw', i);

      } else {
        newShapeHoles[mainIdx].add({"h": tmpPath, "p": tmpPoints[0]});

        //Console.log('ccw', i);

      }
    }

    // only Holes? -> probably all Shapes with wrong orientation
    if (newShapes.isEmpty || newShapes[0] == null) {
      return toShapesNoHoles(subPaths);
    }

    if (newShapes.length > 1) {
      bool ambiguous = false;
      int toChange = 0;

      for (int sIdx = 0, sLen = newShapes.length; sIdx < sLen; sIdx++) {
        // betterShapeHoles[ sIdx ] = [];
        (betterShapeHoles as List).listSetter(sIdx, []);
      }

      for (int sIdx = 0, sLen = newShapes.length; sIdx < sLen; sIdx++) {
        final sho = newShapeHoles[sIdx];

        for (int hIdx = 0; hIdx < sho.length; hIdx++) {
          final ho = sho[hIdx];
          bool holeUnassigned = true;

          for (int s2Idx = 0; s2Idx < newShapes.length; s2Idx++) {
            if (isPointInsidePolygon(ho["p"], newShapes[s2Idx]["p"])) {
              if ( sIdx != s2Idx ) toChange ++;
              if (holeUnassigned) {
                holeUnassigned = false;
                betterShapeHoles[s2Idx].add(ho);
              } else {
                ambiguous = true;
              }
            }
          }

          if (holeUnassigned) {
            betterShapeHoles[sIdx].add(ho);
          }
        }
      }
      if ( toChange > 0 && ambiguous == false ) {
				newShapeHoles = betterShapeHoles;
      }
    }

    dynamic tmpHoles;

    for (int i = 0, il = newShapes.length; i < il; i++) {
      tmpShape = newShapes[i]["s"];
      shapes.add(tmpShape);
      tmpHoles = newShapeHoles[i];

      for (int j = 0, jl = tmpHoles.length; j < jl; j++) {
        tmpShape.holes.add(tmpHoles[j]["h"]);
      }
    }

    //Console.log("shape", shapes);

    return shapes;
  }
}
