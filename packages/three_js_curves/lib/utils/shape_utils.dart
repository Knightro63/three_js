import 'package:three_js_math/three_js_math.dart';
import './earcut.dart';

class ShapeUtils {
  // calculate area of the contour polygon

  static double area(List<Vector?> contour) {
    final n = contour.length;
    double a = 0.0;

    for (int p = n - 1, q = 0; q < n; p = q++) {
      if(contour[p] != null){
        a += contour[p]!.x * contour[q]!.y - contour[q]!.x * contour[p]!.y;
      }
    }

    return a * 0.5;
  }

  static bool isClockWise(List<Vector?> pts) {
    return ShapeUtils.area(pts) < 0;
  }

  static List<List<num>> triangulateShape(List<Vector?> contour, List<List<Vector?>> holes) {
    final List<double> vertices = []; // flat array of vertices like [ x0,y0, x1,y1, x2,y2, ... ]
    List<int> holeIndices = []; // array of hole indices
    final List<List<num>> faces = []; // final array of vertex indices like [ [ a,b,d ], [ b,c,d ] ]

    removeDupEndPts(contour);
    addContour(vertices, contour);

    //

    int holeIndex = contour.length;

    holes.forEach(removeDupEndPts);

    for (int i = 0; i < holes.length; i++) {
      holeIndices.add(holeIndex);
      holeIndex += holes[i].length;
      addContour(vertices, holes[i]);
    }

    final List<num> triangles = Earcut.triangulate(vertices, holeIndices);
    for (int i = 0; i < triangles.length; i += 3) {
      faces.add(triangles.sublist(i, i + 3));
    }

    return faces;
  }

  static void removeDupEndPts(points) {
    final l = points.length;

    if (l > 2 && points[l - 1].equals(points[0])) {
      points.removeLast();
    }
  }

  static void addContour(List<num> vertices, List<Vector?> contour) {
    for (int i = 0; i < contour.length; i++) {
      if(contour[i] != null){
        vertices.add(contour[i]!.x);
        vertices.add(contour[i]!.y);
      }
    }
  }
}


