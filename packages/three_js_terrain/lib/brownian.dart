import 'dart:typed_data';
import 'dart:math' as math; 
import 'package:three_js_terrain/core.dart';

///
/// Generate random terrain using Brownian motion.
///
/// Note that this method takes a particularly long time to run (a few seconds).
///
/// Parameters are the same as those for {@link THREE.Terrain.DiamondSquare}.
///
class Brownian{
  Brownian(Float32List g, TerrainOptions options){
    List<Map<String,double>> untouched = [],
      touched = [];
    double smallerSideSize = math.min(options.xSize, options.ySize);
    double changeDirectionProbability = math.sqrt(smallerSideSize) / smallerSideSize;
    double maxHeightAdjust = math.sqrt(options.maxHeight! - options.minHeight!);
    int xl = options.xSegments + 1;
    int yl = options.ySegments + 1;
    int i = (math.Random().nextDouble() * options.xSegments).floor();
    int j = (math.Random().nextDouble() * options.ySegments).floor();
    double x = i*1.0;
    double y = j*1.0;
    int numVertices = g.length;
    //List<double> vertices = g.toList();
    List<Map<String,double>> vertices = [];
    
    double randomDirection = math.Random().nextDouble() * math.pi * 2;
    double addX = math.cos(randomDirection);
    double addY = math.sin(randomDirection);

    for(int i = 0; i < g.length; i++){
      vertices.add({'z': g[i]});
    }
    Map<String,double> current = vertices[j * xl + i];

    double sum;
    double? lastAdjust;
    // Initialize the first vertex.
    current['z'] = math.Random().nextDouble() * (options.maxHeight! - options.minHeight!) + options.minHeight!;
    touched.add(current);

    // Walk through all vertices until they've all been adjusted.
    while (touched.length != numVertices) {
      // Mark the untouched neighboring vertices to revisit later.
      for (int n = -1; n <= 1; n++) {
        for (int m = -1; m <= 1; m++) {
          final key = (j+n)*xl + i + m;
          if (vertices.get(key) != null && touched.indexOf(vertices.get(key)) == -1 && i+m >= 0 && j+n >= 0 && i+m < xl && j+n < yl && n != 0 && m != 0) {
            untouched.add(vertices[key]);
          }
        }
      }

      // Occasionally, pick a random untouched point instead of continuing.
      if (math.Random().nextDouble() < changeDirectionProbability ) {
        current = untouched.removeAt((math.Random().nextDouble() * untouched.length).floor());//untouched.splice((math.Random().nextDouble() * untouched.length).floor())[0];
        randomDirection = math.Random().nextDouble() * math.pi * 2;
        addX = math.cos(randomDirection);
        addY = math.sin(randomDirection);
        final index = vertices.indexOf(current);
        i = index % xl;
        j = (index / xl).floor();
        x = i*1.0;
        y = j*1.0;
      }
      else {
        // Keep walking in the current direction.
        double u = x*1.0,
            v = y*1.0;
        while (u.round() == i && v.round() == j) {
          u += addX;
          v += addY;
        }
        i = u.round();
        j = u.round();

        // If we hit a touched vertex, look in different directions to try to find an untouched one.
        for (int k = 0; i >= 0 && j >= 0 && i < xl && j < yl && touched.indexOf(vertices[j * xl + i]) != -1 && k < 9; k++) {
          randomDirection = math.Random().nextDouble() * math.pi * 2;
          addX = math.cos(randomDirection);
          addY = math.sin(randomDirection);
          while (u.round() == i && v.round() == j) {
            u += addX;
            v += addY;
          }
          i = u.round();
          j = v.round();
        }

        // If we found an untouched vertex, make it the current one.
        if (i >= 0 && j >= 0 && i < xl && j < yl && touched.indexOf(vertices[j * xl + i]) == -1) {
          x = u;
          y = v;
          current = vertices[j * xl + i];
          final io = untouched.indexOf(current);
          if (io != -1) {
            untouched.removeAt(io);
          }
        }

        // If we couldn't find an untouched vertex near the current point,
        // pick a random untouched vertex instead.
        else {
          current = untouched.removeAt((math.Random().nextDouble() * untouched.length).floor());//untouched.splice((math.Random().nextDouble() * untouched.length).floor())[0];
          randomDirection = math.Random().nextDouble() * math.pi * 2;
          addX = math.cos(randomDirection);
          addY = math.sin(randomDirection);
          final index = vertices.indexOf(current);
          i = index % xl;
          j = (index / xl).floor();
          x = i*1.0;
          y = j*1.0;
        }
      }

      // Set the current vertex to the average elevation of its touched neighbors plus a random amount
      sum = 0;
      int c = 0;
      for (int n = -1; n <= 1; n++) {
        for (int m = -1; m <= 1; m++) {
          final key = (j+n)*xl + i + m;
          if (vertices.get(key) != null && touched.indexOf(vertices.get(key)) != -1 && i+m >= 0 && j+n >= 0 && i+m < xl && j+n < yl && n != 0 && m != 0) {
            sum += vertices[key]['z']!;
            c++;
          }
        }
      }
      if (c != 0) {
        if (lastAdjust == null || math.Random().nextDouble() < changeDirectionProbability) {
          lastAdjust = math.Random().nextDouble();
        }
        current['z'] = sum / c + Easing.easeInWeak(lastAdjust) * maxHeightAdjust * 2 - maxHeightAdjust;
      }
      touched.add(current);
    }

    for (i = vertices.length - 1; i >= 0; i--) {
      g[i] = vertices[i]['z']!;
    }

    // Erase artifacts.
    Terrain.smooth(g, options);
    Terrain.smooth(g, options);
  }
}
