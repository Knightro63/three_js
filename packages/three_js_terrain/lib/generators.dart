import 'dart:typed_data';
import 'dart:math' as math; 
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_terrain/core.dart';
import 'package:three_js_terrain/noise.dart';

class Passes{
  Passes({
    this.amplitude,
    this.frequency,
    this.method
  });

  double? amplitude;
  Function? method;
  double? frequency;
}

extension Generators on Terrain{
  /**
   * A utility for generating heightmap functions by additive composition.
   *
   * @param {Float32Array} g
   *   The geometry's z-positions to modify with heightmap data.
   * @param {Object} [options]
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid values are the same as those for the `options` parameter
   *   of {@link THREE.Terrain}().
   * @param {Object[]} passes
   *   Determines which heightmap functions to compose to create a new one.
   *   Consists of an array of objects with the following properties:
   *   - `method`: Contains something that will be passed around as an
   *     `options.heightmap` (a heightmap-generating function or a heightmap image)
   *   - `amplitude`: A multiplier for the heightmap of the pass. Applied before
   *     the result of the pass is added to the result of previous passes.
   *   - `frequency`: For terrain generation methods that support it (Perlin,
   *     Simplex, and Worley) the octave of randomness. This basically controls
   *     how big features of the terrain will be (higher frequencies result in
   *     smaller features). Often running multiple generation functions with
   *     different frequencies and amplitudes results in nice detail.
   */
  static void multiPass(Float32List g, TerrainOptions options, List<Passes> passes) {
    TerrainOptions clonedOptions = TerrainOptions();
    for (var opt in options.keys) {
      if (options.containsKey(opt)) {
        clonedOptions[opt] = options[opt];
      }
    }
    var range = options.maxHeight! - options.minHeight!;
    for (int i = 0, l = passes.length; i < l; i++) {
        var amp = passes[i].amplitude == null ? 1 : passes[i].amplitude!,
            move = 0.5 * (range - range * amp);
        clonedOptions.maxHeight = options.maxHeight! - move;
        clonedOptions.minHeight = options.minHeight! + move;
        clonedOptions.frequency = passes[i].frequency == null ? options.frequency : passes[i].frequency!;
        passes[i].method?.call(g, clonedOptions);
    }
  }

  /**
   * Generate random terrain using a curve.
   *
   * @param {Float32Array} g
   *   The geometry's z-positions to modify with heightmap data.
   * @param {Object} options
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid values are the same as those for the `options` parameter
   *   of {@link THREE.Terrain}().
   * @param {Function} curve
   *   A function that takes an x- and y-coordinate and returns a z-coordinate.
   *   For example, `function(x, y) { return math.sin(x*y*math.pi*100); }`
   *   generates sine noise, and `function() { return math.Random().nextDouble(); }` sets the
   *   vertex elevations entirely randomly. The function's parameters (the x- and
   *   y-coordinates) are given as percentages of a phase (i.e. how far across
   *   the terrain in the relevant direction they are).
   */
  static void curve(Float32List g, TerrainOptions options, [curve]) {
      var range = (options.maxHeight! - options.minHeight!) * 0.5,
          scalar = options.frequency / (math.min(options.xSegments, options.ySegments) + 1);
    for (var i = 0, xl = options.xSegments + 1, yl = options.ySegments + 1; i < xl; i++) {
      for (var j = 0; j < yl; j++) {
        g[j * xl + i] += curve(i * scalar, j * scalar) * range;
      }
    }
  }

  /**
   * Generate random terrain using the Cosine waves.
   *
   * Parameters are the same as those for {@link static DiamondSquare}.
   */
  static void cosine(Float32List g, TerrainOptions options) {
    var amplitude = (options.maxHeight! - options.minHeight!) * 0.5,
        frequencyScalar = options.frequency * math.pi / (math.min(options.xSegments, options.ySegments) + 1),
        phase = math.Random().nextDouble() * math.pi * 2;
    for (var i = 0, xl = options.xSegments + 1; i < xl; i++) {
      for (var j = 0, yl = options.ySegments + 1; j < yl; j++) {
        g[j * xl + i] += amplitude * (math.cos(i * frequencyScalar + phase) + math.cos(j * frequencyScalar + phase));
      }
    }
  }

  /**
   * Generate random terrain using layers of Cosine waves.
   *
   * Parameters are the same as those for {@link static DiamondSquare}.
   */
  static void cosineLayers(Float32List g, TerrainOptions options) {
    multiPass(g, options, [
      Passes( method: cosine,                   frequency:  2.5 ),
      Passes( method: cosine, amplitude: 0.1,   frequency:  12  ),
      Passes( method: cosine, amplitude: 0.05,  frequency:  15  ),
      Passes( method: cosine, amplitude: 0.025, frequency:  20  ),
    ]);
  }

  /**
   * Generate random terrain using the Diamond-Square method.
   *
   * Based on https://github.com/srchea/Terrain-Generation/blob/master/js/classes/TerrainGeneration.js
   *
   * @param {Float32Array} g
   *   The geometry's z-positions to modify with heightmap data.
   * @param {Object} options
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid values are the same as those for the `options` parameter
   *   of {@link THREE.Terrain}().
   */
  static void diamondSquare(Float32List g, TerrainOptions options) {
    // Set the segment length to the smallest power of 2 that is greater than
    // the number of vertices in either dimension of the plane
    int segments = MathUtils.ceilPowerOfTwo<int>(math.max(options.xSegments, options.ySegments) + 1).toInt();

    // Initialize heightmap
    var size = segments + 1,
        heightmap = [],
        smoothing = (options.maxHeight! - options.minHeight!),
        i,
        j,
        xl = options.xSegments + 1,
        yl = options.ySegments + 1;

      for (i = 0; i <= segments; i++) {
        heightmap.add(new Float64Array(segments+1));
      }

      // Generate heightmap
      for (int l = segments; l >= 2; l ~/= 2) {
        var half = (l*0.5).round(),
            whole = l.round(),
            x,
            y,
            avg,
            d;
        smoothing /= 2;
          // square
        for (x = 0; x < segments; x += whole) {
          for (y = 0; y < segments; y += whole) {
            d = math.Random().nextDouble() * smoothing * 2 - smoothing;
            avg = heightmap[x][y] +            // top left
                  heightmap[x+whole][y] +      // top right
                  heightmap[x][y+whole] +      // bottom left
                  heightmap[x+whole][y+whole]; // bottom right
            avg *= 0.25;
            heightmap[x+half][y+half] = avg + d;
          }
        }
        // diamond
        for (x = 0; x < segments; x += half) {
          for (y = (x+half) % l; y < segments; y += l) {
            d = math.Random().nextDouble() * smoothing * 2 - smoothing;
            avg = heightmap[(x-half+size)%size][y] + // middle left
                  heightmap[(x+half)%size][y] +      // middle right
                  heightmap[x][(y+half)%size] +      // middle top
                  heightmap[x][(y-half+size)%size];  // middle bottom
            avg *= 0.25;
            avg += d;
            heightmap[x][y] = avg;
            // top and right edges
            if (x == 0) heightmap[segments][y] = avg;
            if (y == 0) heightmap[x][segments] = avg;
          }
        }
      }

    // Apply heightmap
    for (i = 0; i < xl; i++) {
      for (j = 0; j < yl; j++) {
        g[j * xl + i] += heightmap[i][j];
      }
    }

    // static SmoothConservative(g, options);
  }

  /**
   * Generate random terrain using the Fault method.
   *
   * Based on http://www.lighthouse3d.com/opengl/terrain/index.php3?fault
   * Repeatedly draw random lines that cross the terrain. Raise the terrain on
   * one side of the line and lower it on the other.
   *
   * Parameters are the same as those for {@link static DiamondSquare}.
   */
  static void fault(Float32List g, TerrainOptions options) {
    var d = math.sqrt(options.xSegments*options.xSegments + options.ySegments*options.ySegments),
        iterations = d * options.frequency,
        range = (options.maxHeight! - options.minHeight!) * 0.5,
        displacement = range / iterations,
        smoothDistance = math.min(options.xSize / options.xSegments, options.ySize / options.ySegments) * options.frequency;
    for (var k = 0; k < iterations; k++) {
      var v = math.Random().nextDouble(),
          a = math.sin(v * math.pi * 2),
          b = math.cos(v * math.pi * 2),
          c = math.Random().nextDouble() * d - d*0.5;
      for (var i = 0, xl = options.xSegments + 1; i < xl; i++) {
        for (var j = 0, yl = options.ySegments + 1; j < yl; j++) {
          var distance = a*i + b*j - c;
          if (distance > smoothDistance) {
            g[j * xl + i] += displacement;
          }
          else if (distance < -smoothDistance) {
            g[j * xl + i] -= displacement;
          }
          else {
            g[j * xl + i] += math.cos(distance / smoothDistance * math.pi * 2) * displacement;
          }
        }
      }
    }
    // static Smooth(g, options);
  }

  /**
   * Generate random terrain using the Hill method.
   *
   * The basic approach is to repeatedly pick random points on or near the
   * terrain and raise a small hill around those points. Those small hills
   * eventually accumulate into large hills with distinct features.
   *
   * @param {Float32Array} g
   *   The geometry's z-positions to modify with heightmap data.
   * @param {Object} options
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid values are the same as those for the `options` parameter
   *   of {@link THREE.Terrain}().
   * @param {Function} [feature=static Influences.Hill]
   *   A function describing the feature to raise at the randomly chosen points.
   *   Typically this is a hill shape so that the accumulated features result in
   *   something resembling mountains, but it could be any function that accepts
   *   one parameter representing the distance from the feature's origin
   *   expressed as a number between -1 and 1 inclusive. Optionally it can accept
   *   a second and third parameter, which are the x- and y- distances from the
   *   feature's origin, respectively. It should return a number between -1 and 1
   *   representing the height of the feature at the given coordinate.
   *   `static Influences` contains some useful functions for this
   *   purpose.
   * @param {Function} [shape]
   *   A function that takes an object with `x` and `y` properties consisting of
   *   uniform random variables from 0 to 1, and returns a number from 0 to 1,
   *   typically by transforming it over a distribution. The result affects where
   *   small hills are raised thereby affecting the overall shape of the terrain.
   */
  static void hill(Float32List g, TerrainOptions options, [InfluenceType? feature, Function? shape]) {
      var frequency = options.frequency * 2,
          numFeatures = frequency * frequency * 10,
          heightRange = options.maxHeight! - options.minHeight!,
          minHeight = heightRange / (frequency * frequency),
          maxHeight = heightRange / frequency,
          smallerSideLength = math.min(options.xSize, options.ySize),
          minRadius = smallerSideLength / (frequency * frequency),
          maxRadius = smallerSideLength / frequency;
      feature = feature ?? InfluenceType.hill;

      Vector2 coords = Vector2.zero();
      for (var i = 0; i < numFeatures; i++) {
          var radius = math.Random().nextDouble() * (maxRadius - minRadius) + minRadius,
              height = math.Random().nextDouble() * (maxHeight - minHeight) + minHeight;
          // var min = 0 - radius,
          //     maxX = options.xSize + radius,
          //     maxY = options.ySize + radius;
          coords.x = math.Random().nextDouble();
          coords.y = math.Random().nextDouble();
          if (shape != null) shape(coords);

          Terrain.influence(
            g, 
            options,
            Terrain.influences[feature],
            coords.x, 
            coords.y,
            radius, 
            height,
            AdditiveBlending,
            Easing.easeInStrong
          );
      }
  }

  /**
   * Generate random terrain using the Hill method, centered on the terrain.
   *
   * The only difference between this and the Hill method is that the locations
   * of the points to place small hills are not uniformly randomly distributed
   * but instead are more likely to occur close to the center of the terrain.
   *
   * @param {Float32Array} g
   *   The geometry's z-positions to modify with heightmap data.
   * @param {Object} options
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid values are the same as those for the `options` parameter
   *   of {@link THREE.Terrain}().
   * @param {Function} [feature=static Influences.Hill]
   *   A function describing the feature. The function should accept one
   *   parameter representing the distance from the feature's origin expressed as
   *   a number between -1 and 1 inclusive. Optionally it can accept a second and
   *   third parameter, which are the x- and y- distances from the feature's
   *   origin, respectively. It should return a number between -1 and 1
   *   representing the height of the feature at the given coordinate.
   *   `static Influences` contains some useful functions for this
   *   purpose.
   */
  static void hillIsland(Float32List g, TerrainOptions options, [InfluenceType? feature]) {
    hill(g, options, feature, (coords) {
      var theta = math.Random().nextDouble() * math.pi * 2;
      coords.x = 0.5 + math.cos(theta) * coords.x * 0.4;
      coords.y = 0.5 + math.sin(theta) * coords.y * 0.4;
    });
  }


  /**
   * Deposit a particle at a vertex.
   */
  static void deposit(Float32List g, int i, int j, int xl, double displacement) {
    int currentKey = j * xl + i;
    // Pick a random neighbor.
    for (int k = 0; k < 3; k++) {
        int r = (math.Random().nextDouble() * 8).floor();
        switch (r) {
            case 0: i++; break;
            case 1: i--; break;
            case 2: j++; break;
            case 3: j--; break;
            case 4: i++; j++; break;
            case 5: i++; j--; break;
            case 6: i--; j++; break;
            case 7: i--; j--; break;
        }
        var neighborKey = j * xl + i;
        // If the neighbor is lower, move the particle to that neighbor and re-evaluate.
        if (g.get(neighborKey) != null) {
          if (g.get(neighborKey) < g.get(currentKey)) {
            deposit(g, i, j, xl, displacement);
            return;
          }
        }
        // Deposit some particles on the edge.
        else if (math.Random().nextDouble() < 0.2) {
            g[g.getK(currentKey)] += displacement;
            return;
        }
    }
    g[g.getK(currentKey)] += displacement;
  }

  /**
   * Generate random terrain using the Particle Deposition method.
   *
   * Based on http://www.lighthouse3d.com/opengl/terrain/index.php?particle
   * Repeatedly deposit particles on terrain vertices. Pick a random neighbor
   * of that vertex. If the neighbor is lower, roll the particle to the
   * neighbor. When the particle stops, displace the vertex upwards.
   *
   * The shape of the outcome is highly dependent on options.frequency
   * because that affects how many particles will be dropped. Values around
   * 0.25 generally result in archipelagos whereas the default of 2.5
   * generally results in one large mountainous island.
   *
   * Parameters are the same as those for {@link static DiamondSquare}.
   */
  static void particles(Float32List g, TerrainOptions options) {
    var iterations = math.sqrt(options.xSegments*options.xSegments + options.ySegments*options.ySegments) * options.frequency * 300,
        xl = options.xSegments + 1,
        displacement = (options.maxHeight! - options.minHeight!) / iterations * 1000,
        i = (math.Random().nextDouble() * options.xSegments).floor(),
        j = (math.Random().nextDouble() * options.ySegments).floor(),
        xDeviation = math.Random().nextDouble() * 0.2 - 0.1,
        yDeviation = math.Random().nextDouble() * 0.2 - 0.1;
    for (var k = 0; k < iterations; k++) {
      deposit(g, i, j, xl, displacement);
      var d = math.Random().nextDouble() * math.pi * 2;
      if (k % 1000 == 0) {
        xDeviation = math.Random().nextDouble() * 0.2 - 0.1;
        yDeviation = math.Random().nextDouble() * 0.2 - 0.1;
      }
      if (k % 100 == 0) {
        i = (options.xSegments*(0.5+xDeviation) + math.cos(d) * math.Random().nextDouble() * options.xSegments*(0.5-xDeviation.abs())).floor();
        j = (options.ySegments*(0.5+yDeviation) + math.sin(d) * math.Random().nextDouble() * options.ySegments*(0.5-yDeviation.abs())).floor();
      }
    }
    // static Smooth(g, options, 3);
  }


  /**
   * Generate random terrain using the Perlin Noise method.
   *
   * Parameters are the same as those for {@link static DiamondSquare}.
   */
  static void perlin(Float32List g, TerrainOptions options) {
    Noise.seed(math.Random().nextDouble());
    var range = (options.maxHeight! - options.minHeight!) * 0.5,
        divisor = (math.min(options.xSegments, options.ySegments) + 1) / options.frequency;
    for (var i = 0, xl = options.xSegments + 1; i < xl; i++) {
      for (var j = 0, yl = options.ySegments + 1; j < yl; j++) {
        g[j * xl + i] += Noise.perlin(i / divisor, j / divisor) * range;
      }
    }
  }

  /**
   * Generate random terrain using the Perlin and Diamond-Square methods composed.
   *
   * Parameters are the same as those for {@link static DiamondSquare}.
   */
  static void perlinDiamond(Float32List g, TerrainOptions options) {
    multiPass(g, options, [
      Passes( method: perlin ),
      Passes( method: diamondSquare, amplitude: 0.75 ),
      Passes( method: (g, o) { return Terrain.smoothMedian(g, o);}),
    ]);
  }

  /**
   * Generate random terrain using layers of Perlin noise.
   *
   * Parameters are the same as those for {@link static DiamondSquare}.
   */
  static void perlinLayers(g, options) {
    multiPass(g, options, [
      Passes( method: perlin,                  frequency:  1.25 ),
      Passes( method: perlin, amplitude: 0.05, frequency:  2.5  ),
      Passes( method: perlin, amplitude: 0.35, frequency:  5    ),
      Passes( method: perlin, amplitude: 0.15, frequency: 10    ),
    ]);
  }

  /**
   * Generate random terrain using the Simplex Noise method.
   *
   * Parameters are the same as those for {@link static DiamondSquare}.
   *
   * See https://github.com/mrdoob/three.js/blob/master/examples/webgl_terrain_dynamic.html
   * for an interesting comparison where the generation happens in GLSL.
   */
  static void simplex(Float32List g, TerrainOptions options) {
    Noise.seed(math.Random().nextDouble());
    var range = (options.maxHeight! - options.minHeight!) * 0.5,
          divisor = (math.min(options.xSegments, options.ySegments) + 1) * 2 / options.frequency;
    for (var i = 0, xl = options.xSegments + 1; i < xl; i++) {
      for (var j = 0, yl = options.ySegments + 1; j < yl; j++) {
        g[j * xl + i] += Noise.simplex(i / divisor, j / divisor) * range;
      }
    }
  }

  /**
   * Generate random terrain using layers of Simplex noise.
   *
   * Parameters are the same as those for {@link static DiamondSquare}.
   */
  static simplexLayers(Float32List g, TerrainOptions options) {
    multiPass(g, options, [
      Passes( method: simplex,                    frequency:  1.25),
      Passes( method: simplex, amplitude: 0.5,    frequency:  2.5 ),
      Passes( method: simplex, amplitude: 0.25,   frequency:  5   ),
      Passes( method: simplex, amplitude: 0.125,  frequency: 10   ),
      Passes( method: simplex, amplitude: 0.0625, frequency: 20   ),
    ]);
  }

  /**
   * Generate a heightmap using white noise.
   *
   * @param {THREE.Vector3[]} g The terrain vertices.
   * @param {Object} options Settings
   * @param {Number} scale The resolution of the resulting heightmap.
   * @param {Number} segments The width of the target heightmap.
   * @param {Number} range The altitude of the noise.
   * @param {Number[]} data The target heightmap.
   */
  static void whiteNoise(Float32List g, TerrainOptions options, double scale, int segments, range, Float64List data) {
    if (scale > segments) return;
    int i = 0,
        j = 0,
        xl = segments,
        yl = segments,
        inc = (segments / scale).floor(),
        lastX = -inc,
        lastY = -inc;
    // Walk over the target. For a target of size W and a resolution of N,
    // set every W/N points (in both directions).
    for (i = 0; i <= xl; i += inc) {
      for (j = 0; j <= yl; j += inc) {
        int k = j * xl + i;
        data[k] = math.Random().nextDouble() * range;
        if (lastX < 0 && lastY < 0) continue;
        // jscs:disable disallowSpacesInsideBrackets
        /* c b *
        * l t */
        var t = data.get(k),
            l = data.get( j      * xl + (i-inc)) ?? t, // left
            b = data.get((j-inc) * xl +  i     ) ?? t, // bottom
            c = data.get((j-inc) * xl + (i-inc)) ?? t; // corner
        // jscs:enable disallowSpacesInsideBrackets
        // Interpolate between adjacent points to set the height of
        // higher-resolution target data.
        for (int x = lastX; x < i; x++) {
          for (int y = lastY; y < j; y++) {
            if (x == lastX && y == lastY) continue;
            int z = y * xl + x;
            if (z < 0) continue;
            var px = ((x-lastX) / inc),
                py = ((y-lastY) / inc),
                r1 = px * b + (1-px) * c,
                r2 = px * t + (1-px) * l;
            data[z] = py * r2 + (1-py) * r1;
          }
        }
        lastY = j;
      }
      lastX = i;
      lastY = -inc;
    }
    // Assign the temporary data back to the actual terrain heightmap.
    xl = options.xSegments + 1;
    yl = options.ySegments + 1;
    for (i = 0; i < xl; i++) {
      for (j = 0; j < yl; j++) {
        // http://stackoverflow.com/q/23708306/843621
        var kg = j * xl + i,
            kd = j * segments + i;
        g[kg] += data[kd];
      }
    }
  }

  /**
   * Generate random terrain using value noise.
   *
   * The basic approach of value noise is to generate white noise at a
   * smaller octave than the target and then interpolate to get a higher-
   * resolution result. This is then repeated at different resolutions.
   *
   * Parameters are the same as those for {@link static DiamondSquare}.
   */
  static void value(Float32List g, TerrainOptions options) {
    // Set the segment length to the smallest power of 2 that is greater
    // than the number of vertices in either dimension of the plane
    int segments = MathUtils.ceilPowerOfTwo<int>(math.max(options.xSegments, options.ySegments) + 1).toInt();

    // Store the array of white noise outside of the WhiteNoise function to
    // avoid allocating a bunch of unnecessary arrays; we can just
    // overwrite old data each time WhiteNoise() is called.
    var data = new Float64List((segments+1)*(segments+1));

    // Layer white noise at different resolutions.
    var range = options.maxHeight! - options.minHeight!;
    for (int i = 2; i < 7; i++) {
      whiteNoise(g, options, math.pow(2.0, i).toDouble(), segments, range * math.pow(2, 2.4-i*1.2), data);
    }

    // White noise creates some weird artifacts; fix them.
    // static Smooth(g, options, 1);
    Terrain.clamp(g, TerrainOptions(
      maxHeight: options.maxHeight,
      minHeight: options.minHeight,
      stretch: true,
    ));
  }

  /**
   * Generate random terrain using Weierstrass functions.
   *
   * Weierstrass functions are known for being continuous but not differentiable
   * anywhere. This produces some nice shapes that look terrain-like, but can
   * look repetitive from above.
   *
   * Parameters are the same as those for {@link static DiamondSquare}.
   */
  static void weierstrass(Float32List g, TerrainOptions options) {
    var range = (options.maxHeight! - options.minHeight!) * 0.5,
        dir1 = math.Random().nextDouble() < 0.5 ? 1 : -1,
        dir2 = math.Random().nextDouble() < 0.5 ? 1 : -1,
        r11  =  0.5   + math.Random().nextDouble() * 1.0,
        r12  =  0.5   + math.Random().nextDouble() * 1.0,
        r13  =  0.025 + math.Random().nextDouble() * 0.10,
        r14  = -1.0   + math.Random().nextDouble() * 2.0,
        r21  =  0.5   + math.Random().nextDouble() * 1.0,
        r22  =  0.5   + math.Random().nextDouble() * 1.0,
        r23  =  0.025 + math.Random().nextDouble() * 0.10,
        r24  = -1.0   + math.Random().nextDouble() * 2.0;
    for (int i = 0, xl = options.xSegments + 1; i < xl; i++) {
      for (int j = 0, yl = options.ySegments + 1; j < yl; j++) {
        double sum = 0;
        for (int k = 0; k < 20; k++) {
          double x = math.pow(1+r11, -k) * math.sin(math.pow(1+r12, k) * (i + 0.25*math.cos(j) + r14*j) * r13);
          double y = math.pow(1+r21, -k) * math.sin(math.pow(1+r22, k) * (j + 0.25*math.cos(i) + r24*i) * r23);
          sum -= math.exp(dir1*x*x + dir2*y*y);
        }
        g[j * xl + i] += sum * range;
      }
    }
    Terrain.clamp(g, options);
  }
}