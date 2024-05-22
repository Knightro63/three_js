import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_curves/three_js_curves.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

class ExtrudeGeometry extends BufferGeometry {
  List<Shape> shapes;
  ExtrudeGeometry(this.shapes, ExtrudeGeometryOptions options) : super() {
    type = "ExtrudeGeometry";
    parameters = {"shapes": shapes, "options": options};

    final scope = this;

    List<double> verticesArray = [];
    List<double> uvArray = [];

    void addShape(Shape shape) {
      List<double> placeholder = [];

      // options

      int curveSegments = options.curveSegments;
      final steps = options.steps;
      final depth = options.depth;
      bool bevelEnabled = options.bevelEnabled;
      num bevelThickness = options.bevelThickness;
      num bevelSize = options.bevelSize;
      num bevelOffset = options.bevelOffset;
      int bevelSegments = options.bevelSegments;
      final Curve? extrudePath = options.extrudePath;
      const String uvgen = "WorldUVGenerator";// options["UVGenerator"] ?? 


      late List<Vector?> extrudePts;
      bool extrudeByPath = false;
      late FrenetFrames splineTube;
      Vector3 binormal = Vector3.zero(); 
      Vector3 normal = Vector3.zero();
      Vector3 position2 = Vector3.zero();

      if (extrudePath != null) {
        extrudePts = extrudePath.getSpacedPoints(steps);

        extrudeByPath = true;
        bevelEnabled = false; // bevels not supported for path extrusion

        // SETUP TNB variables

        // TODO1 - have a .isClosed in spline?

        splineTube = extrudePath.computeFrenetFrames(steps, false);
      }

      // Safeguards if bevels are not enabled

      if (!bevelEnabled) {
        bevelSegments = 0;
        bevelThickness = 0;
        bevelSize = 0;
        bevelOffset = 0;
      }

      // Variables initialization

      final shapePoints = shape.extractPoints(curveSegments);

      List<Vector?> vertices = shapePoints["shape"];
      List<List<Vector?>> holes = (shapePoints["holes"] as List).map((item) => item as List<Vector?>).toList();

      final reverse = !ShapeUtils.isClockWise(vertices);

      if (reverse) {
        vertices = vertices.reversed.toList();

        // Maybe we should also check if holes are in the opposite direction, just to be safe ...

        for (int h = 0, hl = holes.length; h < hl; h++) {
          final ahole = holes[h];

          if (ShapeUtils.isClockWise(ahole)) {
            holes[h] = ahole.reversed.toList();
          }
        }
      }

      final faces = ShapeUtils.triangulateShape(vertices, holes);

      /* Vertices */
      List<Vector?> contour = vertices.sublist(0); // vertices has all points but contour has only points of circumference

      for (int h = 0, hl = holes.length; h < hl; h++) {
        List<Vector?> ahole = holes[h];
        vertices.addAll(ahole);
      }

      scalePt2(pt, vec, size) {
        if (vec == null) {
          console.info('ExtrudeGeometry: vec does not exist');
        }

        return vec.clone().scale(size).add(pt);
      }

      final vlen = vertices.length, flen = faces.length;

      // Find directions for point movement

      Vector2 getBevelVec(Vector inPt, Vector inPrev, Vector inNext) {
        // computes for inPt the corresponding point inPt' on a new contour
        //   shifted by 1 unit (length of normalized vector) to the left
        // if we walk along contour clockwise, this new contour is outside the old one
        //
        // inPt' is the intersection of the two lines parallel to the two
        //  adjacent edges of inPt at a distance of 1 unit on the left side.

        late double vTransX;
        late double vTransY;
        late double shrinkBy; // resulting translation vector for inPt

        // good reading for geometry algorithms (here: line-line intersection)
        // http://geomalgorithms.com/a05-_intersect-1.html

        final vPrevX = inPt.x - inPrev.x;
        final vPrevY = inPt.y - inPrev.y;
        final vNextX = inNext.x - inPt.x;
        final vNextY = inNext.y - inPt.y;

        final vPrevLensq = (vPrevX * vPrevX + vPrevY * vPrevY);

        // check for collinear edges
        final collinear0 = (vPrevX * vNextY - vPrevY * vNextX);

        if (collinear0.abs() > MathUtils.epsilon) {
          // not collinear

          // length of vectors for normalizing

          final vPrevLen = math.sqrt(vPrevLensq);
          final vNextLen = math.sqrt(vNextX * vNextX + vNextY * vNextY);

          // shift adjacent points by unit vectors to the left

          final ptPrevShiftX = (inPrev.x - vPrevY / vPrevLen);
          final ptPrevShiftY = (inPrev.y + vPrevX / vPrevLen);

          final ptNextShiftX = (inNext.x - vNextY / vNextLen);
          final ptNextShiftY = (inNext.y + vNextX / vNextLen);

          // scaling factor for v_prev to intersection point

          final sf = ((ptNextShiftX - ptPrevShiftX) * vNextY -
                  (ptNextShiftY - ptPrevShiftY) * vNextX) /
              (vPrevX * vNextY - vPrevY * vNextX);

          // vector from inPt to intersection point

          vTransX = (ptPrevShiftX + vPrevX * sf - inPt.x);
          vTransY = (ptPrevShiftY + vPrevY * sf - inPt.y);

          // Don't normalize!, otherwise sharp corners become ugly
          //  but prevent crazy spikes
          final vTransLensq = (vTransX * vTransX + vTransY * vTransY);
          if (vTransLensq <= 2) {
            return Vector2(vTransX, vTransY);
          } else {
            shrinkBy = math.sqrt(vTransLensq / 2);
          }
        } else {
          // handle special case of collinear edges

          bool directionEq = false; // assumes: opposite

          if (vPrevX > MathUtils.epsilon) {
            if (vNextX > MathUtils.epsilon) {
              directionEq = true;
            }
          } else {
            if (vPrevX < -MathUtils.epsilon) {
              if (vNextX < -MathUtils.epsilon) {
                directionEq = true;
              }
            } else {
              if (vPrevY.sign == vNextY.sign) {
                directionEq = true;
              }
            }
          }

          if (directionEq) {
            // Console.log("Warning: lines are a straight sequence");
            vTransX = -vPrevY;
            vTransY = vPrevX;
            shrinkBy = math.sqrt(vPrevLensq);
          } else {
            // Console.log("Warning: lines are a straight spike");
            vTransX = vPrevX;
            vTransY = vPrevY;
            shrinkBy = math.sqrt(vPrevLensq / 2);
          }
        }

        return Vector2(vTransX / shrinkBy, vTransY / shrinkBy);
      }

      final contourMovements = [];

      for (int i = 0, il = contour.length, j = il - 1, k = i + 1;
          i < il;
          i++, j++, k++) {
        if (j == il) j = 0;
        if (k == il) k = 0;

        //  (j)---(i)---(k)
        // Console.log('i,j,k', i, j , k)

        final v = getBevelVec(contour[i]!, contour[j]!, contour[k]!);

        contourMovements.add(v);
      }

      final holesMovements = [];
      List oneHoleMovements, verticesMovements = contourMovements.sublist(0);

      for (int h = 0, hl = holes.length; h < hl; h++) {
        final ahole = holes[h];

        oneHoleMovements = List<Vector2>.filled(ahole.length, Vector2(0, 0));

        for (int i = 0, il = ahole.length, j = il - 1, k = i + 1;
            i < il;
            i++, j++, k++) {
          if (j == il) j = 0;
          if (k == il) k = 0;

          //  (j)---(i)---(k)
          oneHoleMovements[i] = getBevelVec(ahole[i]!, ahole[j]!, ahole[k]!);
        }

        holesMovements.add(oneHoleMovements);
        verticesMovements.addAll(oneHoleMovements);
      }

      void v(double x, double y, double z) {
        placeholder.add(x);
        placeholder.add(y);
        placeholder.add(z);
      }

      // Loop bevelSegments, 1 for the front, 1 for the back

      for (int b = 0; b < bevelSegments; b++) {
        //for ( b = bevelSegments; b > 0; b -- ) {

        final t = b / bevelSegments;
        final z = bevelThickness * math.cos(t * math.pi / 2);
        final bs = bevelSize * math.sin(t * math.pi / 2) + bevelOffset;

        // contract shape

        for (int i = 0, il = contour.length; i < il; i++) {
          final vert = scalePt2(contour[i], contourMovements[i], bs);

          v(vert.x, vert.y, -z);
        }

        // expand holes

        for (int h = 0, hl = holes.length; h < hl; h++) {
          final ahole = holes[h];
          oneHoleMovements = holesMovements[h];

          for (int i = 0, il = ahole.length; i < il; i++) {
            final vert = scalePt2(ahole[i], oneHoleMovements[i], bs);

            v(vert.x, vert.y, -z);
          }
        }
      }

      final bs = bevelSize + bevelOffset;

      // Back facing vertices

      for (int i = 0; i < vlen; i++) {
        final vert = bevelEnabled
            ? scalePt2(vertices[i], verticesMovements[i], bs)
            : vertices[i];

        if (!extrudeByPath) {
          v(vert.x, vert.y, 0);
        } else {
          normal..setFrom(splineTube.normals![0])..scale(vert.x);
          binormal..setFrom(splineTube.binormals![0])..scale(vert.y);
          position2..setFrom(extrudePts[0]! as Vector3)..add(normal)..add(binormal);
          v(position2.x, position2.y, position2.z);
        }
      }

      // Add stepped vertices...
      // Including front facing vertices

      for (int s = 1; s <= steps; s++) {
        for (int i = 0; i < vlen; i++) {
          final vert = bevelEnabled
              ? scalePt2(vertices[i], verticesMovements[i], bs)
              : vertices[i];

          if (!extrudeByPath) {
            v(vert.x, vert.y, depth / steps * s);
          } 
          else {
            normal..setFrom(splineTube.normals![s])..scale(vert.x);
            binormal..setFrom(splineTube.binormals![s])..scale(vert.y);
            position2..setFrom(extrudePts[s] as Vector3)..add(normal)..add(binormal);
            v(position2.x, position2.y, position2.z);
          }
        }
      }

      // Add bevel segments planes

      //for ( b = 1; b <= bevelSegments; b ++ ) {
      for (int b = bevelSegments - 1; b >= 0; b--) {
        final t = b / bevelSegments;
        final z = bevelThickness * math.cos(t * math.pi / 2);
        final bs = bevelSize * math.sin(t * math.pi / 2) + bevelOffset;

        // contract shape

        for (int i = 0, il = contour.length; i < il; i++) {
          final vert = scalePt2(contour[i], contourMovements[i], bs);
          v(vert.x, vert.y, depth + z);
        }

        // expand holes
        for (int h = 0, hl = holes.length; h < hl; h++) {
          final ahole = holes[h];
          oneHoleMovements = holesMovements[h];

          for (int i = 0, il = ahole.length; i < il; i++) {
            final vert = scalePt2(ahole[i], oneHoleMovements[i], bs);

            if (!extrudeByPath) {
              v(vert.x, vert.y, depth + z);
            } else {
              v(vert.x, vert.y + extrudePts[steps - 1]!.y, extrudePts[steps - 1]!.x + z);
            }
          }
        }
      }

      void addUV(Vector2 vector2) {
        uvArray.add(vector2.x);
        uvArray.add(vector2.y);
      }

      void addVertex(num index) {
        // print(" addVertex index: ${index} ${placeholder.length} ");

        verticesArray.add(placeholder[index.toInt() * 3 + 0]);
        verticesArray.add(placeholder[index.toInt() * 3 + 1]);
        verticesArray.add(placeholder[index.toInt() * 3 + 2]);
      }

      void f3(num a, num b, num c) {
        addVertex(a);
        addVertex(b);
        addVertex(c);

        final nextIndex = verticesArray.length ~/ 3;
        dynamic uvs;

        if (uvgen == "WorldUVGenerator") {
          uvs = WorldUVGenerator.generateTopUV(verticesArray, nextIndex - 3, nextIndex - 2, nextIndex - 1);
        } 
        else {
          throw ("ExtrudeBufferGeometry uvgen: $uvgen is not support yet ");
        }

        // final uvs = uvgen.generateTopUV( scope, verticesArray, nextIndex - 3, nextIndex - 2, nextIndex - 1 );

        addUV(uvs[0]);
        addUV(uvs[1]);
        addUV(uvs[2]);
      }

      void buildLidFaces() {
        final start = verticesArray.length / 3;

        if (bevelEnabled) {
          int layer = 0; // steps + 1
          int offset = vlen * layer;

          // Bottom faces

          for (int i = 0; i < flen; i++) {
            final face = faces[i];
            f3(face[2] + offset, face[1] + offset, face[0] + offset);
          }

          layer = steps + bevelSegments * 2;
          offset = vlen * layer;

          // Top faces

          for (int i = 0; i < flen; i++) {
            final face = faces[i];
            f3(face[0] + offset, face[1] + offset, face[2] + offset);
          }
        } else {
          // Bottom faces

          for (int i = 0; i < flen; i++) {
            final face = faces[i];
            f3(face[2], face[1], face[0]);
          }

          // Top faces

          for (int i = 0; i < flen; i++) {
            final face = faces[i];
            f3(face[0] + vlen * steps, face[1] + vlen * steps,
                face[2] + vlen * steps);
          }
        }

        scope.addGroup(start.toInt(), (verticesArray.length / 3 - start).toInt(),0);
      }

      void f4(num a, num b, num c, num d) {
        addVertex(a);
        addVertex(b);
        addVertex(d);

        addVertex(b);
        addVertex(c);
        addVertex(d);

        final nextIndex = verticesArray.length ~/ 3;

        dynamic uvs;
        if (uvgen == "WorldUVGenerator") {
          uvs = WorldUVGenerator.generateSideWallUV(verticesArray, nextIndex - 6, nextIndex - 3, nextIndex - 2, nextIndex - 1);
        } else {
          throw ("ExtrudeBufferGeometry uvgen: $uvgen is not support yet ");
        }
        // final uvs = uvgen.generateSideWallUV( scope, verticesArray, nextIndex - 6, nextIndex - 3, nextIndex - 2, nextIndex - 1 );

        addUV(uvs[0]);
        addUV(uvs[1]);
        addUV(uvs[3]);

        addUV(uvs[1]);
        addUV(uvs[2]);
        addUV(uvs[3]);
      }

      void sidewalls(contour, int layeroffset) {
        int i = contour.length;

        while (--i >= 0) {
          final j = i;
          int k = i - 1;
          if (k < 0) k = contour.length - 1;

          //Console.log('b', i,j, i-1, k,vertices.length);

          for (int s = 0, sl = (steps + bevelSegments * 2); s < sl; s++) {
            final slen1 = vlen * s;
            final slen2 = vlen * (s + 1);

            final a = layeroffset + j + slen1;
            final b = layeroffset + k + slen1;
            final c = layeroffset + k + slen2;
            final d = layeroffset + j + slen2;

            f4(a, b, c, d);
          }
        }
      }

      // Create faces for the z-sides of the shape
      void buildSideFaces() {
        int start = verticesArray.length ~/ 3.0;
        int layeroffset = 0;
        sidewalls(contour, layeroffset);
        layeroffset = layeroffset + contour.length;

        for (int h = 0, hl = holes.length; h < hl; h++) {
          List ahole = holes[h];

          sidewalls(ahole, layeroffset);

          //, true
          layeroffset += ahole.length;
        }

        // TODO WHY???  need fix ???
        scope.addGroup(start, (verticesArray.length / 3 - start).toInt(),1);
      }

      /* Faces */

      // Top and bottom faces
      buildLidFaces();

      // Sides faces
      buildSideFaces();
    }

    for (int i = 0, l = shapes.length; i < l; i++) {
      final shape = shapes[i];
      addShape(shape);
    }

    // build geometry

    setAttribute(Attribute.position,Float32BufferAttribute.fromTypedData(Float32List.fromList(verticesArray), 3, false));
    setAttribute(Attribute.uv, Float32BufferAttribute.fromTypedData(Float32List.fromList(uvArray), 2, false));

    computeVertexNormals();

    // functions
  }
}

class WorldUVGenerator {
  static List<Vector2> generateTopUV(List<double> vertices, int indexA, int indexB, int indexC) {
    final aX = vertices[indexA * 3];
    final aY = vertices[indexA * 3 + 1];
    final bX = vertices[indexB * 3];
    final bY = vertices[indexB * 3 + 1];
    final cX = vertices[indexC * 3];
    final cY = vertices[indexC * 3 + 1];

    return [
      Vector2(aX, aY), Vector2(bX, bY), Vector2(cX, cY)
    ];
  }

  static List<Vector2> generateSideWallUV(List<double> vertices, int indexA, int indexB, int indexC, int indexD) {
    double aX = vertices[indexA * 3];
    double aY = vertices[indexA * 3 + 1];
    double aZ = vertices[indexA * 3 + 2];
    double bX = vertices[indexB * 3];
    double bY = vertices[indexB * 3 + 1];
    double bZ = vertices[indexB * 3 + 2];
    double cX = vertices[indexC * 3];
    double cY = vertices[indexC * 3 + 1];
    double cZ = vertices[indexC * 3 + 2];
    double dX = vertices[indexD * 3];
    double dY = vertices[indexD * 3 + 1];
    double dZ = vertices[indexD * 3 + 2];

    if ((aY - bY).abs() < (aX - bX).abs()) {
      return [
        Vector2(aX, 1 - aZ),
        Vector2(bX, 1 - bZ),
        Vector2(cX, 1 - cZ),
        Vector2(dX, 1 - dZ)
      ];
    } else {
      return [
        Vector2(aY, 1 - aZ),
        Vector2(bY, 1 - bZ),
        Vector2(cY, 1 - cZ),
        Vector2(dY, 1 - dZ)
      ];
    }
  }
}

Map<String,dynamic> toJSON2(shapes, Map<String, dynamic>? options, data) {
  if (shapes != null) {
    data["shapes"] = [];

    for (int i = 0, l = shapes.length; i < l; i++) {
      final shape = shapes[i];

      data["shapes"].add(shape.uuid);
    }
  }

  if (options != null && options["extrudePath"] != null) {
    data["options"]["extrudePath"] = options["extrudePath"].toJson();
  }

  return data;
}


class ExtrudeGeometryOptions{
  ExtrudeGeometryOptions({
    this.curveSegments = 12,
    this.steps = 1,
    this.depth = 100,
    this.bevelEnabled = true,
    this.bevelThickness = 6,
    num? bevelSize,
    this.bevelOffset = 0,
    this.extrudePath,
    this.bevelSegments = 3,
    //this.uvGenerator
  }){
    this.bevelSize = bevelSize ?? bevelThickness-2;
  }

  final int curveSegments;
  final int steps;
  final num depth;
  final bool bevelEnabled;
  final num bevelThickness;
  late final num bevelSize;
  final num bevelOffset;
  final int bevelSegments;
  final Curve? extrudePath;
  //final uvgen = options["UVGenerator"] ?? "WorldUVGenerator"; //not supported yet
}