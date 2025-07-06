import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_curves/three_js_curves.dart';
import 'package:three_js_math/three_js_math.dart';
import 'svg_loader_parser.dart';
import 'svg_loader_points_to_stroke.dart';

/// [Scalable Vector Graphics](https://en.wikipedia.org/wiki/Scalable_Vector_Graphics) is an XML-based vector image format for two-dimensional graphics with support for interactivity and animation.
class SVGLoader extends Loader{
  late final FileLoader _loader;
  // Default dots per inch
  num defaultDPI = 90;
  SVGUnits defaultUnit = SVGUnits.px;

  /// [manager] — The [loadingManager] for the loader to use. Default is [DefaultLoadingManager].
  /// 
  /// Creates a new [SVGLoader].
  SVGLoader([super.manager]){
    _loader = FileLoader(manager);
  }

  @override
  void dispose(){
    super.dispose();
    _loader.dispose();
  }
  
  void _init(){
    _loader.setPath(path);
    _loader.setRequestHeader(requestHeader);
    _loader.setWithCredentials(withCredentials);
  }

  @override
  Future<SVGData?> fromNetwork(Uri uri) async{
    _init();
    ThreeFile? tf = await _loader.fromNetwork(uri);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<SVGData> fromFile(File file) async{
    _init();
    ThreeFile tf = await _loader.fromFile(file);
    return _parse(tf.data);
  }
  @override
  Future<SVGData?> fromPath(String filePath) async{
    _init();
    ThreeFile? tf = await _loader.fromPath(filePath);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<SVGData> fromBlob(Blob blob) async{
    _init();
    ThreeFile tf = await _loader.fromBlob(blob);
    return _parse(tf.data);
  }
  @override
  Future<SVGData?> fromAsset(String asset, {String? package}) async{
    _init();
    ThreeFile? tf = await _loader.fromAsset(asset,package: package);
    return tf == null?null:_parse(tf.data);
  }
  @override
  Future<SVGData> fromBytes(Uint8List bytes) async{
    _init();
    ThreeFile tf = await _loader.fromBytes(bytes);
    return _parse(tf.data);
  }
  Future<SVGData> fromString(String text) async{
    _init();
    return _parseFromString(text);
  }

  SVGData _parse(Uint8List bytes) {
    String text = String.fromCharCodes(bytes);
    return _parseFromString(text);
  }
  SVGData _parseFromString(String text) {
    final parse = SVGLoaderParser(text, defaultUnit: defaultUnit, defaultDPI: defaultDPI);
    return parse.parse(text);
  }
  // Function parse ================ end

  static Map<String, dynamic> getStrokeStyle(double? width, String? color, String? lineJoin, String? lineCap, num? miterLimit) {
    // Param width: Stroke width
    // Param color: As returned by THREE.Color.getStyle()
    // Param lineJoin: One of "round", "bevel", "miter" or "miter-limit"
    // Param lineCap: One of "round", "square" or "butt"
    // Param miterLimit: Maximum join length, in multiples of the "width" parameter (join is truncated if it exceeds that distance)
    // Returns style object

    width = width ?? 1;
    color = color ?? '#000';
    lineJoin = lineJoin ?? 'miter';
    lineCap = lineCap ?? 'butt';
    miterLimit = miterLimit ?? 4;

    return {
      "strokeColor": color,
      "strokeWidth": width,
      "strokeLineJoin": lineJoin,
      "strokeLineCap": lineCap,
      "strokeMiterLimit": miterLimit
    };
  }

  static BufferGeometry? pointsToStroke(List<Vector?> points, style, [int? arcDivisions, double? minDistance]) {
    // Generates a stroke with some witdh around the given path.
    // The path can be open or closed (last point equals to first point)
    // Param points: Array of Vector2D (the path). Minimum 2 points.
    // Param style: Object with SVG properties as returned by SVGLoader.getStrokeStyle(), or SVGLoader.parse() in the path.userData.style object
    // Params arcDivisions: Arc divisions for round joins and endcaps. (Optional)
    // Param minDistance: Points closer to this distance will be merged. (Optional)
    // Returns BufferGeometry with stroke triangles (In plane z = 0). UV coordinates are generated ('u' along path. 'v' across it, from left to right)

    List<double> vertices = [];
    List<double> normals = [];
    List<double> uvs = [];

    if (SVGLoader.pointsToStrokeWithBuffers(points, style, arcDivisions, minDistance, vertices, normals, uvs, 0) == 0) {
      return null;
    }

    final geometry = BufferGeometry();
    geometry.setAttributeFromString('position',Float32BufferAttribute.fromList(Float32List.fromList(vertices), 3, false));
    geometry.setAttributeFromString('normal', Float32BufferAttribute.fromList(Float32List.fromList(normals), 3, false));
    geometry.setAttributeFromString('uv', Float32BufferAttribute.fromList(Float32List.fromList(uvs), 2, false));

    return geometry;
  }

  static int pointsToStrokeWithBuffers(
    List<Vector?> points, 
    style, 
    int? arcDivisions, 
    double? minDistance, 
    List<double> vertices, 
    List<double> normals, 
    List<double> uvs, 
    int? vertexOffset
  ) {
    final svgLPTS = SVGLoaderPointsToStroke(points, style, arcDivisions,
        minDistance, vertices, normals, uvs, vertexOffset);
    return svgLPTS.convert();
  }

  static List<Shape> createShapes(ShapePath shapePath) {
    // Param shapePath: a shapepath as returned by the parse function of this class
    // Returns Shape object

    const bigNumber = 99999999999999.0;

    final intersectionLocationType = {
      "ORIGIN": 0,
      "DESTINATION": 1,
      "BETWEEN": 2,
      "LEFT": 3,
      "RIGHT": 4,
      "BEHIND": 5,
      "BEYOND": 6
    };

    Map<String, dynamic> classifyResult = {
      "loc": intersectionLocationType["ORIGIN"],
      "t": 0
    };

    classifyPoint(p, edgeStart, edgeEnd) {
      final ax = edgeEnd.x - edgeStart.x;
      final ay = edgeEnd.y - edgeStart.y;
      final bx = p.x - edgeStart.x;
      final by = p.y - edgeStart.y;
      final sa = ax * by - bx * ay;

      if ((p.x == edgeStart.x) && (p.y == edgeStart.y)) {
        classifyResult["loc"] = intersectionLocationType["ORIGIN"];
        classifyResult["t"] = 0;
        return;
      }

      if ((p.x == edgeEnd.x) && (p.y == edgeEnd.y)) {
        classifyResult["loc"] = intersectionLocationType["DESTINATION"];
        classifyResult["t"] = 1;
        return;
      }

      if (sa < -MathUtils.epsilon) {
        classifyResult["loc"] = intersectionLocationType["LEFT"];
        return;
      }

      if (sa > MathUtils.epsilon) {
        classifyResult["loc"] = intersectionLocationType["RIGHT"];
        return;
      }

      if (((ax * bx) < 0) || ((ay * by) < 0)) {
        classifyResult["loc"] = intersectionLocationType["BEHIND"];
        return;
      }

      if ((math.sqrt(ax * ax + ay * ay)) < (math.sqrt(bx * bx + by * by))) {
        classifyResult["loc"] = intersectionLocationType["BEYOND"];
        return;
      }

      dynamic t;

      if (ax != 0) {
        t = bx / ax;
      } 
      else {
        t = by / ay;
      }

      classifyResult["loc"] = intersectionLocationType["BETWEEN"];
      classifyResult["t"] = t;
    }

    findEdgeIntersection(a0, a1, b0, b1) {
      final x1 = a0.x;
      final x2 = a1.x;
      final x3 = b0.x;
      final x4 = b1.x;
      final y1 = a0.y;
      final y2 = a1.y;
      final y3 = b0.y;
      final y4 = b1.y;
      final nom1 = (x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3);
      final nom2 = (x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3);
      final denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1);
      final t1 = nom1 / denom;
      final t2 = nom2 / denom;

      if (((denom == 0) && (nom1 != 0)) ||
          (t1 <= 0) ||
          (t1 >= 1) ||
          (t2 < 0) ||
          (t2 > 1)) {
        //1. lines are parallel or edges don't intersect

        return null;
      } else if ((nom1 == 0) && (denom == 0)) {
        //2. lines are colinear

        //check if endpoints of edge2 (b0-b1) lies on edge1 (a0-a1)
        for (int i = 0; i < 2; i++) {
          classifyPoint(i == 0 ? b0 : b1, a0, a1);
          //find position of this endpoints relatively to edge1
          if (classifyResult["loc"] == intersectionLocationType["ORIGIN"]) {
            final point = (i == 0 ? b0 : b1);
            return {"x": point.x, "y": point.y, "t": classifyResult["t"]};
          } else if (classifyResult["loc"] ==
              intersectionLocationType["BETWEEN"]) {
            final x = num.parse((x1 + classifyResult["t"]! * (x2 - x1))
                .toStringAsPrecision(10));
            final y = num.parse((y1 + classifyResult["t"]! * (y2 - y1))
                .toStringAsPrecision(10));
            return {"x": x, "y": y, "t": classifyResult["t"]};
          }
        }

        return null;
      } 
      else {
        //3. edges intersect

        for (int i = 0; i < 2; i++) {
          classifyPoint(i == 0 ? b0 : b1, a0, a1);

          if (classifyResult["loc"] == intersectionLocationType["ORIGIN"]) {
            final point = (i == 0 ? b0 : b1);
            return {"x": point.x, "y": point.y, "t": classifyResult["t"]};
          }
        }

        final x = num.parse((x1 + t1 * (x2 - x1)).toStringAsPrecision(10));
        final y = num.parse((y1 + t1 * (y2 - y1)).toStringAsPrecision(10));
        return {"x": x, "y": y, "t": t1};
      }
    }

    getIntersections(path1, path2) {
      final intersectionsRaw = [];
      final intersections = [];

      for (int index = 1; index < path1.length; index++) {
        final path1EdgeStart = path1[index - 1];
        final path1EdgeEnd = path1[index];

        for (int index2 = 1; index2 < path2.length; index2++) {
          final path2EdgeStart = path2[index2 - 1];
          final path2EdgeEnd = path2[index2];

          final intersection = findEdgeIntersection(
              path1EdgeStart, path1EdgeEnd, path2EdgeStart, path2EdgeEnd);

          if (intersection != null &&
              intersectionsRaw.indexWhere((i) =>
                      i["t"] <= intersection["t"] + MathUtils.epsilon &&
                      i["t"] >= intersection["t"] - MathUtils.epsilon) <
                  0) {
            intersectionsRaw.add(intersection);
            intersections.add(Vector3(intersection["x"], intersection["y"]));
          }
        }
      }

      return intersections;
    }

    getScanlineIntersections(scanline, boundingBox, paths) {
      final center = Vector3();
      boundingBox.getCenter(center);

      final allIntersections = [];

      paths.forEach((path) {
        // check if the center of the bounding box is in the bounding box of the paths.
        // this is a pruning method to limit the search of intersections in paths that can't envelop of the current path.
        // if a path envelops another path. The center of that oter path, has to be inside the bounding box of the enveloping path.
        if (path["boundingBox"].containsPoint(center)) {
          final intersections = getIntersections(scanline, path["points"]);

          for (final p in intersections) {
            allIntersections.add({
              "identifier": path["identifier"],
              "isCW": path["isCW"],
              "point": p
            });
          }
        }
      });

      allIntersections.sort((i1, i2) {
        return i1["point"].x >= i2["point"].x ? 1 : -1;
      });

      return allIntersections;
    }

    isHoleTo(simplePath, allPaths, scanlineMinX, scanlineMaxX, _fillRule) {
      if (_fillRule == null || _fillRule == '') {
        _fillRule = 'nonzero';
      }

      final centerBoundingBox = Vector3();
      simplePath["boundingBox"].getCenter(centerBoundingBox);

      final scanline = [
        Vector3(scanlineMinX, centerBoundingBox.y),
        Vector3(scanlineMaxX, centerBoundingBox.y)
      ];

      final scanlineIntersections = getScanlineIntersections(
          scanline, simplePath["boundingBox"], allPaths);

      scanlineIntersections.sort((i1, i2) {
        return i1["point"].x >= i2["point"].x ? 1 : -1;
      });

      final baseIntersections = [];
      final otherIntersections = [];

      for (final i in scanlineIntersections) {
        if (i["identifier"] == simplePath["identifier"]) {
          baseIntersections.add(i);
        } else {
          otherIntersections.add(i);
        }
      }

      final firstXOfPath = baseIntersections[0]["point"].x;

      // build up the path hierarchy
      final stack = [];
      int i = 0;

      while (i < otherIntersections.length &&
          otherIntersections[i]["point"].x < firstXOfPath) {
        if (stack.isNotEmpty &&
            stack[stack.length - 1] == otherIntersections[i]["identifier"]) {
          stack.removeLast();
        } else {
          stack.add(otherIntersections[i]["identifier"]);
        }

        i++;
      }

      stack.add(simplePath["identifier"]);

      if (_fillRule == 'evenodd') {
        final isHole = stack.length % 2 == 0 ? true : false;
        final isHoleFor = stack[stack.length - 2];

        return {
          "identifier": simplePath["identifier"],
          "isHole": isHole,
          "for": isHoleFor
        };
      }
      else if (_fillRule == 'nonzero') {
        // check if path is a hole by counting the amount of paths with alternating rotations it has to cross.
        bool isHole = true;
        late int isHoleFor;
        late bool lastCWValue;

        for (int i = 0; i < stack.length; i++) {
          final identifier = stack[i];
          if (isHole) {
            lastCWValue = allPaths[identifier]["isCW"];
            isHole = false;
            isHoleFor = identifier;
          } 
          else if (lastCWValue != allPaths[identifier]["isCW"]) {
            lastCWValue = allPaths[identifier]["isCW"];
            isHole = true;
          }
        }

        return {
          "identifier": simplePath["identifier"],
          "isHole": isHole,
          "for": isHoleFor
        };
      } else {
        console.info('fill-rule: $_fillRule is currently not implemented.');
      }
    }

    // check for self intersecting paths
    // TODO

    // check intersecting paths
    // TODO

    // prepare paths for hole detection
    int identifier = 0;

    num scanlineMinX = bigNumber;
    num scanlineMaxX = -bigNumber;

    List simplePaths = shapePath.subPaths.map((p) {
      final points = p.getPoints();
      double maxY = -bigNumber;
      double minY = bigNumber;
      double maxX = -bigNumber;
      double minX = bigNumber;

      //points.forEach(p => p.y *= -1);

      for (int i = 0; i < points.length; i++) {
        final p = points[i]!;

        if (p.y > maxY) {
          maxY = p.y;
        }

        if (p.y < minY) {
          minY = p.y;
        }

        if (p.x > maxX) {
          maxX = p.x;
        }

        if (p.x < minX) {
          minX = p.x;
        }
      }

      //
      if (scanlineMaxX <= maxX) {
        scanlineMaxX = maxX + 1;
      }

      if (scanlineMinX >= minX) {
        scanlineMinX = minX - 1;
      }

      return {
        "curves": p.curves,
        "points": points,
        "isCW": ShapeUtils.isClockWise(points),
        "identifier": identifier++,
        "boundingBox": BoundingBox(Vector3(minX, minY,0), Vector3(maxX, maxY,0))
      };
    }).toList();

    simplePaths = simplePaths.where((sp) {
      return sp["points"].length > 1;
    }).toList();

    // check if path is solid or a hole
    final isAHole = simplePaths
        .map((p) => isHoleTo(p, simplePaths, scanlineMinX, scanlineMaxX,
            shapePath.userData!["style"]["fillRule"]))
        .toList();

    final List<Shape> shapesToReturn = [];
    for (final p in simplePaths) {
      final amIAHole = isAHole[p["identifier"]];

      if (amIAHole?["isHole"] == false) {
        final shape = Shape(null);
        shape.curves = p["curves"];
        final holes = isAHole
            .where((h) => h!["isHole"] && h["for"] == p["identifier"])
            .toList();
        for (final h in holes) {
          final hole = simplePaths[h!["identifier"]];
          final path = Path(null);
          path.curves = hole["curves"];
          shape.holes.add(path);
        }
        shapesToReturn.add(shape);
      }
    }

    return shapesToReturn;
  }
}
