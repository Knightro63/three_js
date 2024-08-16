import 'dart:typed_data';

import 'package:three_js_core/renderers/webgl/index.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'dart:math' as math;

import 'package:three_js_terrain/three_js_terrain.dart'; 

extension TerrainLE on List{

  int getK(int k){
    if(k >= length){
      return k-length;
    }
    else if (k < 0){
      return k+length;
    }
    else{
      return k;
    }
  }
  T? get<T>(int k){
    if(k >= length){
      if(k > k-length){
        return null;
      }
      else{
        return elementAt(k-length);
      }
    }
    else if (k < 0){
      return elementAt(length+k);
    }
    else{
      return elementAt(k);
    }
  }
}

/**
 * Optimization types.
 *
 * Note that none of these are implemented right now. They should be done as
 * shaders so that they execute on the GPU, and the resulting scene would need
 * to be updated every frame to adjust to the camera's position.
 *
 * Further reading:
 * - http://vterrain.org/LOD/Papers/
 * - http://vterrain.org/LOD/Implementations/
 *
 * GEOMIPMAP: The terrain plane should be split into sections, each with their
 * own LODs, for screen-space occlusion and detail reduction. Intermediate
 * vertices on higher-detail neighboring sections should be interpolated
 * between neighbor edge vertices in order to match with the edge of the
 * lower-detail section. The number of sections should be around sqrt(segments)
 * along each axis. It's unclear how to make materials stretch across segments.
 * Possible example (I haven't looked too much into it) at
 * https://github.com/felixpalmer/lod-terrain/tree/master/js/shaders
 *
 * GEOCLIPMAP: The terrain should be composed of multiple donut-shaped sections
 * at decreasing resolution as the radius gets bigger. When the player moves,
 * the sections should morph so that the detail "follows" the player around.
 * There is an implementation of geoclipmapping at
 * https://github.com/CodeArtemis/TriggerRally/blob/unified/server/public/scripts/client/terrain.coffee
 * and a tutorial on morph targets at
 * http://nikdudnik.com/making-3d-gfx-for-the-cinema-on-low-budget-and-three-js/
 *
 * POLYGONREDUCTION: Combine areas that are relatively coplanar into larger
 * polygons as described at http://www.shamusyoung.com/twentysidedtale/?p=142.
 * This method can be combined with the others if done very carefully, or it
 * can be adjusted to be more aggressive at greater distance from the camera
 * (similar to combining with geomipmapping).
 *
 * If these do get implemented, here is the option description to add to the
 * `Terrain` docblock:
 *
 *    - `optimization`: the type of optimization to apply to the terrain. If
 *      an optimization is applied, the number of segments along each axis that
 *      the terrain should be divided into at the most detailed level should
 *      equal (n * 2^(LODs-1))^2 - 1, for arbitrary n, where LODs is the number
 *      of levels of detail desired. Valid values include:
 *
 *          - `Terrain.NONE`: Don't apply any optimizations. This is the
 *            default.
 *          - `Terrain.GEOMIPMAP`: Divide the terrain into evenly-sized
 *            sections with multiple levels of detail. For each section,
 *            display a level of detail dependent on how close the camera is.
 *          - `Terrain.GEOCLIPMAP`: Divide the terrain into donut-shaped
 *            sections, where detail decreases as the radius increases. The
 *            rings then morph to "follow" the camera around so that the camera
 *            is always at the center, surrounded by the most detail.
 */
enum TerrainType{none,geomipmap,geoclipmap,polygonreduction}

enum InfluenceType{mesa,hole,hill,valley,dome,flat,volcano}

enum Easing{
  linear,easeIn,easeOut,easeInOut,inEaseOut,easeInWeak,easeInStrong;
  
  /**
   * Randomness interpolation functions.
   */
  double _linear(double x) {
    return x;
  }

  // x = [0, 1], x^2
  double _easeIn(double x) {
    return x*x;
  }

  // x = [0, 1], -x(x-2)
  double _easeOut(double x) {
      return -x * (x - 2);
  }

  // x = [0, 1], x^2(3-2x)
  // Nearly identical alternatives: 0.5+0.5*cos(x*pi-pi), x^a/(x^a+(1-x)^a) (where a=1.6 seems nice)
  // For comparison: http://www.wolframalpha.com/input/?i=x^1.6%2F%28x^1.6%2B%281-x%29^1.6%29%2C+x^2%283-2x%29%2C+0.5%2B0.5*cos%28x*pi-pi%29+from+0+to+1
  double _easeInOut(double x) {
    return x*x*(3-2*x);
  }

  // x = [0, 1], 0.5*(2x-1)^3+0.5
  double _inEaseOut(double x) {
    final y = 2*x-1;
    return 0.5 * y*y*y + 0.5;
  }

  // x = [0, 1], x^1.55
  double _easeInWeak(double x) {
      return math.pow(x, 1.55).toDouble();
  }

  // x = [0, 1], x^7
  double _easeInStrong(double x) {
    return x*x*x*x*x*x*x;
  }

  static Easing? fromString(String ease){
    for(final eases in Easing.values){
      if(ease.toLowerCase() == eases.name.toLowerCase()){
        return eases;
      }
    }

    return null;
  }

  double call(double x,[double? y, double? z]){
    switch (values[index]) {
      case linear:
        return _linear(x);
      case easeIn:
        return _easeIn(x);
      case easeOut:
        return _easeOut(x);
      case easeInOut:
        return _easeInOut(x);
      case inEaseOut:
        return _inEaseOut(x);
      case easeInWeak:
        return _easeInWeak(x);
      default:
        return _easeInStrong(x);
    }
  }
}

class TerrainTextures{
  TerrainTextures({
    required this.texture,
    this.levels,
    this.glsl = ''
  });

  Texture texture;
  List<double>? levels;
  String glsl;
}

class TerrainEdges{
  TerrainEdges({
    this.top = true, 
    this.bottom = true, 
    this.left = true, 
    this.right = true
  });

  bool top;
  bool bottom;
  bool left;
  bool right;
}

class ScatterOptions{
  ScatterOptions({
    required this.mesh,
    this.spreadFunction,
    this.scene,
    this.spread = 0.025,
    this.smoothSpread = 0,
    this.sizeVariance = 0.1,
    this.maxSlope = 0.6283185307179586,
    this.maxTilt = double.infinity,
    this.w = 0,
    this.h = 0,
    double Function(num)? randomness
  }){
    this.randomness = randomness ?? (k){ return math.Random().nextDouble();};
  }

  Object3D mesh;
  Object3D? scene;
  double spread;
  double smoothSpread;
  double sizeVariance;
  double w;
  double h;
  double maxTilt;
  double maxSlope;
  late double Function(num) randomness;
  late bool Function(Vector3,double,Vector3,int)? spreadFunction;
}

class TerrainOptions{
  TerrainOptions({
    this.after,
    this.easing = Easing.linear,
    this.heightmap,// = Terrain.DiamondSquare,
    this.material = null,
    this.maxHeight,
    this.minHeight,
    this.optimization = TerrainType.none,
    this.frequency = 2.5,
    this.steps = 1,
    this.stretch = true,
    this.turbulent = false,
    this.xSegments = 63,
    this.xSize = 1024,
    this.ySegments = 63,
    this.ySize = 1024,
    this.worleyDistribution,
    this.worleyDistanceTransformation,
    this.distanceType = 0,
    this.worleyPoints
    //List<Vector2>? worleyPoints
  }){
    //this.worleyPoints = worleyPoints ?? [];
  }

  double ySize;
  int ySegments;
  double xSize;
  int xSegments;
  bool turbulent;
  bool stretch;
  int steps;
  double frequency;
  Easing easing;
  double? maxHeight;
  double? minHeight;
  Material? material;
  Function? after;
  TerrainType optimization;
  dynamic heightmap;
  int distanceType;

  List<Vector2> Function(int,int,[int?])? worleyDistribution;
  double Function(num)? worleyDistanceTransformation;
  //late List<Vector2> worleyPoints;
  int? worleyPoints;

  bool containsKey(String key){
    return keys.contains(key);
  }

  List<String> keys = [
    'ySize',
    'ySegments',
    'xSize',
    'xSegments',
    'turbulent',
    'stretch',
    'steps',
    'frequency',
    'easing',
    'maxHeight',
    'minHeight',
    'material',
    'after',
    'optimization',
    'heightmap',
  ];

  dynamic operator [](String index) {
    switch (index) {
      case 'ySize':
        return ySize;
      case 'ySegments':
        return ySegments;
      case 'xSize':
        return xSize;
      case 'xSegments':
        return xSegments;
      case 'turbulent':
        return turbulent;
      case 'stretch':
        return stretch;
      case 'steps':
        return steps;
      case 'frequency':
        return frequency;
      case 'easing':
        return easing;
      case 'maxHeight':
        return maxHeight;
      case 'minHeight':
        return minHeight;
      case 'material':
        return material;
      case 'after':
        return after;
      case 'optimization':
        return optimization;
      case 'heightmap':
        return heightmap;
      default:
        return null;
    }
  }

  void operator []=(String index, value) {
    switch (index) {
      case 'ySize':
        ySize = value;
        break;
      case 'ySegments':
        ySegments = value;
        break;
      case 'xSize':
        xSize = value;
        break;
      case 'xSegments':
        xSegments = value;
        break;
      case 'turbulent':
        turbulent = value;
        break;
      case 'stretch':
        stretch = value;
        break;
      case 'steps':
        steps = value;
        break;
      case 'frequency':
        frequency = value;
        break;
      case 'easing':
        easing = value;
        break;
      case 'maxHeight':
        maxHeight = value;
        break;
      case 'minHeight':
        minHeight = value;
        break;
      case 'material':
        material = value;
        break;
      case 'after':
        after = value;
        break;
      case 'optimization':
        optimization = value;
        break;
      case 'heightmap':
        heightmap = value;
        break;
    }
  }
}

class Terrain{

  static void Function(Float32List,TerrainOptions)? fromString(String type){
    switch (type.toLowerCase()) {
      case 'brownian':
        return Brownian.new;
      case 'clamp':
        return clamp;
     case 'edges':
        return edges;
     case 'smooth':
        return smooth;
     case 'smoothmedian':
        return smoothMedian;
     case 'smoothconservative':
        return smoothConservative;
     case 'turbulence':
        return turbulence;
     case 'fromheightmap':
        return fromHeightmap;
      case 'influence':
     case 'influences':
        return influence;
     case 'gaussian':
        return Gaussian.new;
     case 'worley':
        return Worley.new;
     case 'cosinelayers':
        return Generators.cosineLayers;
     case 'cosine':
        return Generators.cosine;
     case 'curve':
        return Generators.curve;
     case 'diamondsquare':
        return Generators.diamondSquare;
     case 'fault':
        return Generators.fault;
     case 'hill':
        return Generators.hill;
     case 'hillisland':
        return Generators.hillIsland;
     case 'particles':
        return Generators.particles;
     case 'perlin':
        return Generators.perlin;
     case 'perlindiamond':
        return Generators.perlinDiamond;
     case 'perlinlayers':
        return Generators.perlinLayers;
     case 'simplex':
        return Generators.simplex;
      case 'simplexlayers':
        return Generators.simplexLayers;
      case 'value':
        return Generators.value;
      case 'weierstrass':
        return Generators.weierstrass;
      default:
        return null;
    }
  }
  /**
   * A terrain object for use with the js library.
   *
   * Usage: `var terrainScene = Terrain();`
   *
   * @param {Object} [options]
   *   An optional map of settings that control how the terrain is constructed
   *   and displayed. Options include:
   *
   *   - `after`: A function to run after other transformations on the terrain
   *     produce the highest-detail heightmap, but before optimizations and
   *     visual properties are applied. Takes two parameters, which are the same
   *     as those for {@link Terrain.DiamondSquare}: an array of
   *     `Vector3` objects representing the vertices of the terrain, and a
   *     map of options with the same available properties as the `options`
   *     parameter for the `Terrain` function.
   *   - `easing`: A function that affects the distribution of slopes by
   *     interpolating the height of each vertex along a curve. Valid values
   *     include `Terrain.Linear` (the default), `Terrain.EaseIn`,
   *     `Terrain.EaseOut`, `Terrain.EaseInOut`,
   *     `Terrain.InEaseOut`, and any custom function that accepts a float
   *     between 0 and 1 and returns a float between 0 and 1.
   *   - `frequency`: For terrain generation methods that support it (Perlin,
   *     Simplex, and Worley) the octave of randomness. This basically controls
   *     how big features of the terrain will be (higher frequencies result in
   *     smaller features). Often running multiple generation functions with
   *     different frequencies and heights results in nice detail, as
   *     the PerlinLayers and SimplexLayers methods demonstrate. (The counterpart
   *     to frequency, amplitude, is represented by the difference between the
   *     `maxHeight` and `minHeight` parameters.) Defaults to 2.5.
   *   - `heightmap`: Either a canvas or pre-loaded image (from the same domain
   *     as the webpage or served with a CORS-friendly header) representing
   *     terrain height data (lighter pixels are higher); or a function used to
   *     generate random height data for the terrain. Valid random functions are
   *     specified in `generators.js` (or custom functions with the same
   *     signature). Ideally heightmap images have the same number of pixels as
   *     the terrain has vertices, as determined by the `xSegments` and
   *     `ySegments` options, but this is not required. If the heightmap is a
   *     different size, vertex height values will be interpolated.) Defaults to
   *     `Terrain.DiamondSquare`.
   *   - `material`: a Material instance used to display the terrain.
   *     Defaults to `new MeshBasicMaterial({color: 0xee6633})`.
   *   - `maxHeight`: the highest point, in js units, that a peak should
   *     reach. Defaults to 100. Setting to `undefined`, `null`, or `Infinity`
   *     removes the cap, but this is generally not recommended because many
   *     generators and filters require a vertical range. Instead, consider
   *     setting the `stretch` option to `false`.
   *   - `minHeight`: the lowest point, in js units, that a valley should
   *     reach. Defaults to -100. Setting to `undefined`, `null`, or `-Infinity`
   *     removes the cap, but this is generally not recommended because many
   *     generators and filters require a vertical range. Instead, consider
   *     setting the `stretch` option to `false`.
   *   - `steps`: If this is a number above 1, the terrain will be paritioned
   *     into that many flat "steps," resulting in a blocky appearance. Defaults
   *     to 1.
   *   - `stretch`: Determines whether to stretch the heightmap across the
   *     maximum and minimum height range if the height range produced by the
   *     `heightmap` property is smaller. Defaults to true.
   *   - `turbulent`: Whether to perform a turbulence transformation. Defaults to
   *     false.
   *   - `xSegments`: The number of segments (rows) to divide the terrain plane
   *     into. (This basically determines how detailed the terrain is.) Defaults
   *     to 63.
   *   - `xSize`: The width of the terrain in js units. Defaults to 1024.
   *     Rendering might be slightly faster if this is a multiple of
   *     `options.xSegments + 1`.
   *   - `ySegments`: The number of segments (columns) to divide the terrain
   *     plane into. (This basically determines how detailed the terrain is.)
   *     Defaults to 63.
   *   - `ySize`: The length of the terrain in js units. Defaults to 1024.
   *     Rendering might be slightly faster if this is a multiple of
   *     `options.ySegments + 1`.
   */
  static Object3D create(TerrainOptions? options) {
    options = options ?? TerrainOptions(
      maxHeight: 100,
      minHeight: -100
    );
    options.material = options.material ?? MeshBasicMaterial.fromMap({ 'color': 0xee6633 });

    // Encapsulating the terrain in a parent object allows us the flexibility
    // to more easily have multiple meshes for optimization purposes.
    final scene = Object3D();
    // Planes are initialized on the XY plane, so rotate the plane to make it lie flat.
    scene.rotation.x = -0.5 * math.pi;

    // Create the terrain mesh.
    final mesh = Mesh(
      PlaneGeometry(options.xSize, options.ySize, options.xSegments, options.ySegments),
      options.material
    );

    // Assign elevation data to the terrain plane from a heightmap or function.
    final zs = toArray1D(mesh.geometry!.attributes['position'].array.toDartList());
    if (options.heightmap is Uint8List) {
      fromHeightmap(zs, options);
    }
    else if (options.heightmap is Function) {
      options.heightmap(zs, options);
    }
    else {
      console.warning('An invalid value was passed for `options.heightmap`: ${options.heightmap.runtimeType}');
    }

    fromArray1D(mesh.geometry!.attributes['position'].array.toDartList(), zs);
    normalize(mesh, options);

    // lod.addLevel(mesh, options.unit * 10 * Math.pow(2, lodLevel));

    scene.add(mesh);
    return scene;
  }

  /**
   * Normalize the terrain after applying a heightmap or filter.
   *
   * This applies turbulence, steps, and height clamping; calls the `after`
   * callback; updates normals and the bounding sphere; and marks vertices as
   * dirty.
   *
   * @param {Mesh} mesh
   *   The terrain mesh.
   * @param {Object} options
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid options are the same as for {@link Terrain}().
   */
  static void normalize(Object3D mesh, TerrainOptions options) {
    final zs = toArray1D(mesh.geometry!.attributes['position'].array.toDartList());
    if (options.turbulent) {
      turbulence(zs, options);
    }
    if (options.steps > 1) {
      step(zs, options.steps);
      smooth(zs, options);
    }

    // Keep the terrain within the allotted height range if necessary, and do easing.
    clamp(zs, options);

    // Call the "after" callback
    options.after?.call(zs, options);
    fromArray1D(mesh.geometry!.attributes['position'].array.toDartList(), zs);

    // Mark the geometry as having changed and needing updates.
    mesh.geometry?.computeBoundingSphere();
    mesh.geometry?.computeFaceNormals();
    mesh.geometry?.computeVertexNormals();
  }

  /**
   * Get a 2D array of heightmap values from a 1D array of Z-positions.
   *
   * @param {Float32Array} vertices
   *   A 1D array containing the vertex Z-positions of the geometry representing
   *   the terrain.
   * @param {Object} options
   *   A map of settings defining properties of the terrain. The only properties
   *   that matter here are `xSegments` and `ySegments`, which represent how many
   *   vertices wide and deep the terrain plane is, respectively (and therefore
   *   also the dimensions of the returned array).
   *
   * @return {Float32Array[]}
   *   A 2D array representing the terrain's heightmap.
   */
  static List<Float32List> toArray2D(Float32List vertices, TerrainOptions options) {
    List<Float32List> tgt = List.filled(options.xSegments + 1,new Float32List(options.ySegments + 1));
    int xl = options.xSegments + 1,
      yl = options.ySegments + 1,
      i, j;

    for (i = 0; i < xl; i++) {
      for (j = 0; j < yl; j++) {
        tgt[i][j] = vertices[j * xl + i];
      }
    }
    return tgt;
  }

  /**
   * Set the height of plane vertices from a 2D array of heightmap values.
   *
   * @param {Float32Array} vertices
   *   A 1D array containing the vertex Z-positions of the geometry representing
   *   the terrain.
   * @param {Number[][]} src
   *   A 2D array representing a heightmap to apply to the terrain.
   */
  static void fromArray2D(Float32List vertices, List<List<double>> src) {
    for (int i = 0, xl = src.length; i < xl; i++) {
      for (int j = 0, yl = src[i].length; j < yl; j++) {
        vertices[j * xl + i] = src[i][j];
      }
    }
  }

  /**
   * Get a 1D array of heightmap values from a 1D array of plane vertices.
   *
   * @param {Float32Array} vertices
   *   A 1D array containing the vertex positions of the geometry representing the
   *   terrain.
   * @param {Object} options
   *   A map of settings defining properties of the terrain. The only properties
   *   that matter here are `xSegments` and `ySegments`, which represent how many
   *   vertices wide and deep the terrain plane is, respectively (and therefore
   *   also the dimensions of the returned array).
   *
   * @return {Float32Array}
   *   A 1D array representing the terrain's heightmap.
   */
  static Float32List toArray1D(Float32List vertices) {
    final tgt = Float32List(vertices.length ~/ 3);
    for (int i = 0, l = tgt.length; i < l; i++) {
      tgt[i] = vertices[i * 3 + 2];
    }
    return tgt;
  }

  /**
   * Set the height of plane vertices from a 1D array of heightmap values.
   *
   * @param {Float32Array} vertices
   *   A 1D array containing the vertex positions of the geometry representing the
   *   terrain.
   * @param {Number[]} src
   *   A 1D array representing a heightmap to apply to the terrain.
   */
  static void fromArray1D(Float32List vertices, List <double> src) {
    for (int i = 0, l = math.min<int>(vertices.length ~/ 3, src.length); i < l; i++) {
      vertices[i * 3 + 2] = src[i];
    }
  }

  /**
   * Generate a 1D array containing random heightmap data.
   *
   * This is like {@link Terrain.toHeightmap} except that instead of
   * generating the js mesh and material information you can just get the
   * height data.
   *
   * @param {Function} method
   *   The method to use to generate the heightmap data. Works with function that
   *   would be an acceptable value for the `heightmap` option for the
   *   {link Terrain} function.
   * @param {Number} options
   *   The same as the options parameter for the {@link Terrain} function.
   */
  static Float32List heightmapArray(void Function(Float32List,TerrainOptions) method, TerrainOptions options) {
    Float32List arr = Float32List.fromList(List.filled((options.xSegments+1) * (options.ySegments+1), 0));
    method(arr, options);
    clamp(arr, options);
    return arr;
  }

  /**
   * Rescale the heightmap of a terrain to keep it within the maximum range.
   *
   * @param {Float32Array} g
   *   The geometry's z-positions to modify with heightmap data.
   * @param {Object} options
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid values are the same as those for the `options` parameter
   *   of {@link THREE.Terrain}() but only `maxHeight`, `minHeight`, and `easing`
   *   are used.
   */
  static void clamp(Float32List g, TerrainOptions options) {
      double min = double.infinity,
          max = -double.infinity;
      int l = g.length;

      options.easing = options.easing;
      for (int i = 0; i < l; i++) {
        if (g[i] < min) min = g[i];
        if (g[i] > max) max = g[i];
      }
      var actualRange = max - min,
        optMax = options.maxHeight ?? max,
        optMin = options.minHeight ?? min,
        targetMax = options.stretch ? optMax : (max < optMax ? max : optMax),
        targetMin = options.stretch ? optMin : (min > optMin ? min : optMin),
        range = targetMax - targetMin;
      if (targetMax < targetMin) {
          targetMax = optMax;
        range = targetMax - targetMin;
      }

      for (int i = 0; i < l; i++) {
        g[i] = options.easing.call((g[i] - min) / actualRange) * range + optMin;
      }
  }

  /**
   * Move the edges of the terrain up or down based on distance from the edge.
   *
   * Useful to make islands or enclosing walls/cliffs.
   *
   * @param {Float32Array} g
   *   The geometry's z-positions to modify with heightmap data.
   * @param {Object} options
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid values are the same as those for the `options` parameter
   *   of {@link THREE.Terrain}().
   * @param {Boolean} direction
   *   `true` if the edges should be turned up; `false` if they should be turned
   *   down.
   * @param {Number} distance
   *   The distance from the edge at which the edges should begin to be affected
   *   by this operation.
   * @param {Number/Function} [e=THREE.Terrain.EaseInOut]
   *   A function that determines how quickly the terrain will transition between
   *   its current height and the edge shape as distance to the edge decreases.
   *   It does this by interpolating the height of each vertex along a curve.
   *   Valid values include `THREE.Terrain.Linear`, `THREE.Terrain.EaseIn`,
   *   `THREE.Terrain.EaseOut`, `THREE.Terrain.EaseInOut`,
   *   `THREE.Terrain.InEaseOut`, and any custom function that accepts a float
   *   between 0 and 1 and returns a float between 0 and 1.
   * @param {Object} [edges={top: true, bottom: true, left: true, right: true}]
   *   Determines which edges should be affected by this function. Defaults to
   *   all edges. If passed, should be an object with `top`, `bottom`, `left`,
   *   and `right` Boolean properties specifying which edges to affect.
   */
  static edges(Float32List g, TerrainOptions options, [bool direction = false, double? distance, Easing? easing, TerrainEdges? edges]) {
    int numXSegments = distance != null?(distance / (options.xSize / options.xSegments)).floor() : 1;
    int numYSegments = distance != null?(distance / (options.ySize / options.ySegments)).floor() : 1;
    double peak = direction ? options.maxHeight! : options.minHeight!;
    Function max = direction ? math.max : math.min;
    int xl = options.xSegments + 1;
    int yl = options.ySegments + 1;
    int i, j, k1, k2;
    double multiplier;
    easing = easing ?? Easing.easeInOut;
    edges ??= TerrainEdges();
    
    for (i = 0; i < xl; i++) {
      for (j = 0; j < numYSegments; j++) {
        multiplier = easing.call(1 - j / numYSegments);
        k1 = j*xl + i;
        k2 = (options.ySegments-j)*xl + i;
        if (edges.top) {
          g[k1] = max(g[k1], (peak - g[k1]) * multiplier + g[k1]);
        }
        if (edges.bottom) {
          g[k2] = max(g[k2], (peak - g[k2]) * multiplier + g[k2]);
        }
      }
    }
    for (i = 0; i < yl; i++) {
      for (j = 0; j < numXSegments; j++) {
        multiplier = easing.call(1 - j / numXSegments);
        k1 = i*xl+j;
        k2 = (options.ySegments-i)*xl + (options.xSegments-j);
        if (edges.left) {
          g[k1] = max(g[k1], (peak - g[k1]) * multiplier + g[k1]);
        }
        if (edges.right) {
          g[k2] = max(g[k2], (peak - g[k2]) * multiplier + g[k2]);
        }
      }
    }
    clamp(
      g, 
      TerrainOptions(
        maxHeight: options.maxHeight,
        minHeight: options.minHeight,
        stretch: true,
      )
    );
  }

  /**
   * Move the edges of the terrain up or down based on distance from the center.
   *
   * Useful to make islands or enclosing walls/cliffs.
   *
   * @param {Float32Array} g
   *   The geometry's z-positions to modify with heightmap data.
   * @param {Object} options
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid values are the same as those for the `options` parameter
   *   of {@link THREE.Terrain}().
   * @param {Boolean} direction
   *   `true` if the edges should be turned up; `false` if they should be turned
   *   down.
   * @param {Number} distance
   *   The distance from the center at which the edges should begin to be
   *   affected by this operation.
   * @param {Number/Function} [e=THREE.Terrain.EaseInOut]
   *   A function that determines how quickly the terrain will transition between
   *   its current height and the edge shape as distance to the edge decreases.
   *   It does this by interpolating the height of each vertex along a curve.
   *   Valid values include `THREE.Terrain.Linear`, `THREE.Terrain.EaseIn`,
   *   `THREE.Terrain.EaseOut`, `THREE.Terrain.EaseInOut`,
   *   `THREE.Terrain.InEaseOut`, and any custom function that accepts a float
   *   between 0 and 1 and returns a float between 0 and 1.
   */
  static void radialEdges(Float32List g, TerrainOptions options, direction, distance, Easing easing) {
    double peak = direction ? options.maxHeight! : options.minHeight!;
    Function max = direction ? math.max : math.min;
    int xl = (options.xSegments + 1);
    int yl = (options.ySegments + 1);
    double xl2 = xl * 0.5;
    double yl2 = yl * 0.5;
    double xSegmentSize = options.xSize / options.xSegments;
    double ySegmentSize = options.ySize / options.ySegments;
    double edgeRadius = math.min(options.xSize, options.ySize) * 0.5 - distance;
    int i, j, k;
    double multiplier;
    double vertexDistance;

    for (i = 0; i < xl; i++) {
      for (j = 0; j < yl2; j++) {
        k = j*xl + i;
        vertexDistance = math.min(edgeRadius, math.sqrt((xl2-i)*xSegmentSize*(xl2-i)*xSegmentSize + (yl2-j)*ySegmentSize*(yl2-j)*ySegmentSize) - distance);
        if (vertexDistance < 0) continue;
        multiplier = easing.call(vertexDistance / edgeRadius);
        g[k] = max(g[k], (peak - g[k]) * multiplier + g[k]);
        // Use symmetry to reduce the number of iterations.
        k = (options.ySegments-j)*xl + i;
        g[k] = max(g[k], (peak - g[k]) * multiplier + g[k]);
      }
    }
  }

  /**
   * Smooth the terrain by setting each point to the mean of its neighborhood.
   *
   * @param {Float32Array} g
   *   The geometry's z-positions to modify with heightmap data.
   * @param {Object} options
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid values are the same as those for the `options` parameter
   *   of {@link THREE.Terrain}().
   * @param {Number} [weight=0]
   *   How much to weight the original vertex height against the average of its
   *   neighbors.
   */
  static void smooth(Float32List g, TerrainOptions options, [double? weight]) {
    final heightmap = Float32List(g.length);
    for (int i = 0, xl = options.xSegments + 1, yl = options.ySegments + 1; i < xl; i++) {
      for (int j = 0; j < yl; j++) {
        double sum = 0;
        int c = 0;
        for (int n = -1; n <= 1; n++) {
          for (int m = -1; m <= 1; m++) {
            final key = (j+n)*xl + i + m;
            if (i+m >= 0 && j+n >= 0 && i+m < xl && j+n < yl) {//typeof g[key] != 'undefined' && 
              sum += g[key];
              c++;
            }
          }
        }
        heightmap[j*xl + i] = sum / c;
      }
    }
    weight = weight ?? 0;
    final w = 1 / (1 + weight);
    for (int k = 0, l = g.length; k < l; k++) {
      g[k] = (heightmap[k] + g[k] * weight) * w;
    }
  }

  /**
   * Smooth the terrain by setting each point to the median of its neighborhood.
   *
   * @param {Float32Array} g
   *   The geometry's z-positions to modify with heightmap data.
   * @param {Object} options
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid values are the same as those for the `options` parameter
   *   of {@link THREE.Terrain}().
   */
  static void smoothMedian(Float32List g, TerrainOptions options) {
    final heightmap = Float32List(g.length);
    List<int> neighborValues = [],
      neighborKeys = [];
    int Function(dynamic,dynamic) sortByValue = (a, b) {
      return (neighborValues.get(a)??0) - (neighborValues.get(b) ?? 0);
    };
    for (int i = 0, xl = options.xSegments + 1, yl = options.ySegments + 1; i < xl; i++) {
      for (int j = 0; j < yl; j++) {
        neighborValues.length = 0;
        neighborKeys.length = 0;
        for (int n = -1; n <= 1; n++) {
          for (int m = -1; m <= 1; m++) {
            final key = (j+n)*xl + i + m;
            if (i+m >= 0 && j+n >= 0 && i+m < xl && j+n < yl) {//typeof g[key] != 'undefined' && 
              neighborValues.add(g[key].toInt());
              neighborKeys.add(key);
            }
          }
        }
        neighborKeys.sort(sortByValue);
        final halfKey = (neighborKeys.length*0.5).floor(),
            median;
        if (neighborKeys.length % 2 == 1) {
          median = g[neighborKeys[halfKey]];
        }
        else {
          median = (g[neighborKeys[halfKey-1]] + g[neighborKeys[halfKey]]) * 0.5;
        }
        heightmap[j*xl + i] = median;
      }
    }
    for (int k = 0, l = g.length; k < l; k++) {
      g[k] = heightmap[k];
    }
  }

  /**
   * Smooth the terrain by clamping each point within its neighbors' extremes.
   *
   * @param {Float32Array} g
   *   The geometry's z-positions to modify with heightmap data.
   * @param {Object} options
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid values are the same as those for the `options` parameter
   *   of {@link THREE.Terrain}().
   * @param {Number} [multiplier=1]
   *   By default, this filter clamps each point within the highest and lowest
   *   value of its neighbors. This parameter is a multiplier for the range
   *   outside of which the point will be clamped. Higher values mean that the
   *   point can be farther outside the range of its neighbors.
   */
  static void smoothConservative(Float32List g, TerrainOptions options, [double? multiplier]) {
    final heightmap = Float32List(g.length);
    for (int i = 0, xl = options.xSegments + 1, yl = options.ySegments + 1; i < xl; i++) {
      for (int j = 0; j < yl; j++) {
        double max = -double.infinity,
            min = double.infinity;
        for (int n = -1; n <= 1; n++) {
          for (int m = -1; m <= 1; m++) {
            final key = (j+n)*xl + i + m;
            if (n != 0 && m != 0 && i+m >= 0 && j+n >= 0 && i+m < xl && j+n < yl) {//typeof g[key] != 'undefined' && 
              if (g[key] < min) min = g[key];
              if (g[key] > max) max = g[key];
            }
          }
        }
        final kk = j*xl + i;
        if (multiplier != null) {
          final halfdiff = (max - min) * 0.5,
              middle = min + halfdiff;
          max = middle + halfdiff * multiplier;
          min = middle - halfdiff * multiplier;
        }
        heightmap[kk] = g[kk] > max ? max : (g[kk] < min ? min : g[kk]);
      }
    }
    for (int k = 0, l = g.length; k < l; k++) {
      g[k] = heightmap[k];
    }
  }

  /**
   * Partition a terrain into flat steps.
   *
   * @param {Float32Array} g
   *   The geometry's z-positions to modify with heightmap data.
   * @param {Number} [levels]
   *   The number of steps to divide the terrain into. Defaults to
   *   (g.length/2)^(1/4).
   */
  static void step(Float32List g, int? levels) {
    int i = 0,
      j = 0,
      l = g.length;
    levels ??= (math.pow(l*0.5, 0.25)).floor();
    // Calculate the max, min, and avg values for each bucket
    int inc = (l / levels).floor();
    List<double> heights = List.filled(l,0);
    List<Map<String,double>> buckets = List.filled(levels, {});

    for (i = 0; i < l; i++) {
      heights[i] = g[i];
    }
    heights.sort((a, b){ return (a - b).toInt(); });
    for (i = 0; i < levels; i++) {
        // Bucket by population (bucket size) not range size
        List<double> subset = heights.sublist(i*inc, (i+1)*inc);
        double sum = 0;
        int bl = subset.length;
        for (j = 0; j < bl; j++) {
            sum += subset[j];
        }
        buckets[i] = {
          'min': subset[0],
          'max': subset[subset.length-1],
          'avg': sum / bl,
        };
    }

    // Set the height of each vertex to the average height of its bucket
    for (i = 0; i < l; i++) {
      final startHeight = g[i];
      for (j = 0; j < levels; j++) {
        if (startHeight >= buckets[j]['min']! && startHeight <= buckets[j]['max']!) {
          g[i] = buckets[j]['avg']!;
          break;
        }
      }
    }
  }

  /**
   * Transform to turbulent noise.
   *
   * @param {Float32Array} g
   *   The geometry's z-positions to modify with heightmap data.
   * @param {Object} [options]
   *   The same map of settings you'd pass to {@link THREE.Terrain()}. Only
   *   `minHeight` and `maxHeight` are used (and required) here.
   */
  static void turbulence(Float32List g, TerrainOptions options) {
    final range = options.maxHeight! - options.minHeight!;
    for (int i = 0, l = g.length; i < l; i++) {
      g[i] = options.minHeight! + ((g[i] - options.minHeight!) * 2 - range).abs();
    }
  }

  /**
   * Convert an image-based heightmap into vertex-based height data.
   *
   * @param {Float32Array} g
   *   The geometry's z-positions to modify with heightmap data.
   * @param {Object} options
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid values are the same as those for the `options` parameter
   *   of {@link THREE.Terrain}().
   */
  static void fromHeightmap(Float32List g, TerrainOptions options) {
    // var canvas = document.createElement('canvas'),
    //     context = canvas.getContext('2d'),
    int rows = options.ySegments + 1;
    int cols = options.xSegments + 1;
    double spread = options.maxHeight! - options.minHeight!;
    // canvas.width = cols;
    // canvas.height = rows;
    // context.drawImage(options.heightmap, 0, 0, canvas.width, canvas.height);
    final data = options.heightmap!;//context.getImageData(0, 0, canvas.width, canvas.height).data;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        int i = row * cols + col;
        int idx = i * 4;
        g[i] = (data[idx] + data[idx+1] + data[idx+2]) / 765 * spread + (options.minHeight ?? 0);
      }
    }
  }

  /**
   * Convert a terrain plane into an image-based heightmap.
   *
   * Parameters are the same as for {@link THREE.Terrain.fromHeightmap} except
   * that if `options.heightmap` is a canvas element then the image will be
   * painted onto that canvas; otherwise a new canvas will be created.
   *
   * @param {Float32Array} g
   *   The vertex position array for the geometry to paint to a heightmap.
   * @param {Object} options
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid values are the same as those for the `options` parameter
   *   of {@link THREE.Terrain}().
   *
   * @return {HTMLCanvasElement}
   *   A canvas with the relevant heightmap painted on it.
   */
  static Uint8List toHeightmap(Float32List g, TerrainOptions options) {
      bool hasMax = options.maxHeight != null;
      bool hasMin = options.minHeight != null;

      double max = hasMax ? options.maxHeight! : -double.infinity;
      double min = hasMin ? options.minHeight! :  double.infinity;

      if (!hasMax || !hasMin) {
        var max2 = max,
          min2 = min;
        for (int k = 2, l = g.length; k < l; k += 3) {
          if (g[k] > max2) max2 = g[k];
          if (g[k] < min2) min2 = g[k];
        }
        if (!hasMax) max = max2;
        if (!hasMin) min = min2;
      }
      // var canvas = options.heightmap instanceof HTMLCanvasElement ? options.heightmap : document.createElement('canvas');
      // context = canvas.getContext('2d'),
      int rows = options.ySegments + 1;
      int cols = options.xSegments + 1;
      double spread = max - min;
      // canvas.width = cols;
      // canvas.height = rows;
      // var d = context.createImageData(canvas.width, canvas.height),
      Uint8List data = Uint8List(rows*cols*4);//d.data;
      for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
          var i = row * cols + col,
          idx = i * 4;
          data[idx] = data[idx+1] = data[idx+2] = (((g[i * 3 + 2] - min) / spread) * 255).round();
          data[idx+3] = 255;
        }
      }
      //context.putImageData(d, 0, 0);
      return data;
  }

  // Allows placing geometrically-described features on a terrain.
  // If you want these features to look a little less regular, apply them before a procedural pass.
  // If you want more complex influence, you can composite heightmaps.

  /**
   * Equations describing geographic features.
   */
  static Map<InfluenceType,double Function(double,[double?, double?])> influences = {
    InfluenceType.mesa: (double x,[double? y, double? z]) {
      return 1.25 * math.min(0.8, math.exp(-(x*x)));
    },
    InfluenceType.hole: (double x,[double? y, double? z]) {
      return -influences[InfluenceType.mesa]!(x);
    },
    InfluenceType.hill: (double x,[double? y, double? z]) {
      // Same curve as EaseInOut, but mirrored and translated.
      return x < 0 ? (x+1)*(x+1)*(3-2*(x+1)) : 1-x*x*(3-2*x);
    },
    InfluenceType.valley: (double x,[double? y, double? z]) {
      return -influences[InfluenceType.hill]!(x);
    },
    InfluenceType.dome: (double x,[double? y, double? z]) {
      // Parabola
      return -(x+1)*(x-1);
    },
    // Not meaningful in Additive or Subtractive mode
    InfluenceType.flat: (double x,[double? y, double? z]) {
      return 0;
    },
    InfluenceType.volcano: (double x,[double? y, double? z]) {
      return 0.94 - 0.32 * ((2 * x).abs() + math.cos(2 * math.pi * x.abs() + 0.4));
    },
  };

  /**
   * Place a geographic feature on the terrain.
   *
   * @param {THREE.Vector3[]} g
   *   The vertex array for plane geometry to modify with heightmap data. This
   *   method sets the `z` property of each vertex.
   * @param {Object} options
   *   A map of settings that control how the terrain is constructed and
   *   displayed. Valid values are the same as those for the `options` parameter
   *   of {@link THREE.Terrain}().
   * @param {Function} f
   *   A function describing the feature. The function should accept one
   *   parameter representing the distance from the feature's origin expressed as
   *   a number between -1 and 1 inclusive. Optionally it can accept a second and
   *   third parameter, which are the x- and y- distances from the feature's
   *   origin, respectively. It should return a number between -1 and 1
   *   representing the height of the feature at the given coordinate.
   *   `THREE.Terrain.Influences` contains some useful functions for this
   *   purpose.
   * @param {Number} [x=0.5]
   *   How far across the terrain the feature should be placed on the X-axis, in
   *   PERCENT (as a decimal) of the size of the terrain on that axis.
   * @param {Number} [y=0.5]
   *   How far across the terrain the feature should be placed on the Y-axis, in
   *   PERCENT (as a decimal) of the size of the terrain on that axis.
   * @param {Number} [r=64]
   *   The radius of the feature.
   * @param {Number} [h=64]
   *   The height of the feature.
   * @param {String} [t=THREE.NormalBlending]
   *   Determines how to layer the feature on top of the existing terrain. Valid
   *   values include `THREE.AdditiveBlending`, `THREE.SubtractiveBlending`,
   *   `THREE.MultiplyBlending`, `THREE.NoBlending`, `THREE.NormalBlending`, and
   *   any function that takes the terrain's current height, the feature's
   *   displacement at a vertex, and the vertex's distance from the feature
   *   origin, and returns the new height for that vertex. (If a custom function
   *   is passed, it can take optional fourth and fifth parameters, which are the
   *   x- and y-distances from the feature's origin, respectively.)
   * @param {Number/Function} [e=THREE.Terrain.EaseIn]
   *   A function that determines the "falloff" of the feature, i.e. how quickly
   *   the terrain will get close to its height before the feature was applied as
   *   the distance increases from the feature's location. It does this by
   *   interpolating the height of each vertex along a curve. Valid values
   *   include `THREE.Terrain.Linear`, `THREE.Terrain.EaseIn`,
   *   `THREE.Terrain.EaseOut`, `THREE.Terrain.EaseInOut`,
   *   `THREE.Terrain.InEaseOut`, and any custom function that accepts a float
   *   between 0 and 1 representing the distance to the feature origin and
   *   returns a float between 0 and 1 with the adjusted distance. (Custom
   *   functions can also accept optional second and third parameters, which are
   *   the x- and y-distances to the feature origin, respectively.)
   */
  static void influence(Float32List g, TerrainOptions options, [double Function(double,[double?,double?])? f, double? x, double? y, double? r, double? h, int? t, Easing? e]) {
    f = f ?? influences[InfluenceType.hill]; // feature shape
    x ??= 0.5; // x-location %
    y ??= 0.5; // y-location %
    r ??= 64; // radius
    h ??= 64; // height
    t ??= NormalBlending; // blending
    e = e ?? Easing.easeIn; // falloff
    // Find the vertex location of the feature origin
    var xl = options.xSegments + 1, // # x-vertices
        yl = options.ySegments + 1, // # y-vertices
        vx = xl * x, // vertex x-location
        vy = yl * y, // vertex y-location
        xw = options.xSize / options.xSegments, // width of x-segments
        yw = options.ySize / options.ySegments, // width of y-segments
        rx = r / xw, // radius of the feature in vertices on the x-axis
        ry = r / yw, // radius of the feature in vertices on the y-axis
        r1 = 1 / r, // for speed
        xs = (vx - rx).ceil(),  // starting x-vertex index
        xe = (vx + rx).floor(), // ending x-vertex index
        ys = (vy - ry).ceil(),  // starting y-vertex index
        ye = (vy + ry).floor(); // ending y-vertex index
    // Walk over the vertices within radius of origin
    for (int i = xs; i < xe; i++) {
      for (int j = ys; j < ye; j++) {
        int k = j * xl + i;
          // distance to the feature origin
        double fdx = (i - vx) * xw,
          fdy = (j - vy) * yw,
          fd = math.sqrt(fdx*fdx + fdy*fdy),
          fdr = fd * r1,
          fdxr = fdx * r1,
          fdyr = fdy * r1,
          // Get the displacement according to f, multiply it by h,
          // interpolate using e, then blend according to t.
          d = f!(fdr, fdxr, fdyr) * h * (1 - e(fdr, fdxr, fdyr));

        final k2 = g.getK(k);
        if (fd > r ) continue;//|| g[k] == null
        if      (t == AdditiveBlending)    g[k2] += d; // jscs:ignore requireSpaceAfterKeywords
        else if (t == SubtractiveBlending) g[k2] -= d;
        else if (t == MultiplyBlending)    g[k2] *= d;
        else if (t == NoBlending)          g[k2]  = d;
        else if (t == NormalBlending)      g[k2]  = e(fdr, fdxr, fdyr) * g[k] + d;
        //else if (typeof t == 'function')   g[k]  = t(g[k].z, d, fdr, fdxr, fdyr);
      }
    }
  }


  /**
   * Scatter a mesh across the terrain.
   *
   * @param {THREE.BufferGeometry} geometry
   *   The terrain's geometry (or the highest-resolution version of it).
   * @param {Object} options
   *   A map of settings that controls how the meshes are scattered, with the
   *   following properties:
   *   - `mesh`: A `THREE.Mesh` instance to scatter across the terrain.
   *   - `spread`: A number or a function that affects where meshes are placed.
   *     If it is a number, it represents the percent of faces of the terrain
   *     onto which a mesh should be placed. If it is a function, it takes a
   *     vertex from the terrain and the key of a related face and returns a
   *     boolean indicating whether to place a mesh on that face or not. An
   *     example could be `function(v, k) { return v.z > 0 && !(k % 4); }`.
   *     Defaults to 0.025.
   *   - `smoothSpread`: If the `spread` option is a number, this affects how
   *     much placement is "eased in." Specifically, if the `randomness` function
   *     returns a value for a face that is within `smoothSpread` percentiles
   *     above `spread`, then the probability that a mesh is placed there is
   *     interpolated between zero and `spread`. This creates a "thinning" effect
   *     near the edges of clumps, if the randomness function creates clumps.
   *   - `scene`: A `THREE.Object3D` instance to which the scattered meshes will
   *     be added. This is expected to be either a return value of a call to
   *     `THREE.Terrain()` or added to that return value; otherwise the position
   *     and rotation of the meshes will be wrong.
   *   - `sizeVariance`: The percent by which instances of the mesh can be scaled
   *     up or down when placed on the terrain.
   *   - `randomness`: If `options.spread` is a number, then this property is a
   *     function that determines where meshes are placed. Specifically, it
   *     returns an array of numbers, where each number is the probability that
   *     a mesh is NOT placed on the corresponding face. Valid values include
   *     `Math.random` and the return value of a call to
   *     `THREE.Terrain.ScatterHelper`.
   *   - `maxSlope`: The angle in radians between the normal of a face of the
   *     terrain and the "up" vector above which no mesh will be placed on the
   *     related face. Defaults to ~0.63, which is 36 degrees.
   *   - `maxTilt`: The maximum angle in radians a mesh can be tilted away from
   *     the "up" vector (towards the normal vector of the face of the terrain).
   *     Defaults to Infinity (meshes will point towards the normal).
   *   - `w`: The number of horizontal segments of the terrain.
   *   - `h`: The number of vertical segments of the terrain.
   *
   * @return {THREE.Object3D}
   *   An Object3D containing the scattered meshes. This is the value of the
   *   `options.scene` parameter if passed. This is expected to be either a
   *   return value of a call to `THREE.Terrain()` or added to that return value;
   *   otherwise the position and rotation of the meshes will be wrong.
   */
  static Object3D scatterMeshes(BufferGeometry geometry, ScatterOptions options) {
    options.scene ??= Object3D();

    var spreadIsNumber = options.spreadFunction == null,
        randomHeightmap,
        randomness,
        spreadRange = 1 / options.smoothSpread,
        doubleSizeVariance = options.sizeVariance * 2,
        vertex1 = Vector3.zero(),
        vertex2 = Vector3.zero(),
        vertex3 = Vector3.zero(),
        faceNormal = Vector3.zero(),
        up = options.mesh.up.clone().applyAxisAngle(Vector3(1, 0, 0), 0.5*math.pi);
    if (spreadIsNumber) {
      randomHeightmap = options.randomness;
      randomness = (k) { return randomHeightmap(k) ?? math.Random().nextDouble();};
    }

    geometry = geometry.toNonIndexed();
    var gArray = geometry.attributes['position'].array;
    for (int i = 0; i < geometry.attributes['position'].array.length; i += 9) {
      vertex1.setValues(gArray[i + 0], gArray[i + 1], gArray[i + 2]);
      vertex2.setValues(gArray[i + 3], gArray[i + 4], gArray[i + 5]);
      vertex3.setValues(gArray[i + 6], gArray[i + 7], gArray[i + 8]);
      Triangle.staticGetNormal(vertex1, vertex2, vertex3, faceNormal);

      var place = false;
      if (spreadIsNumber) {
        
        var rv = randomness(i/9);
        if (rv < options.spread) {
          place = true;
        }
        else if (rv < options.spread + options.smoothSpread) {
          // Interpolate rv between spread and spread + smoothSpread,
          // then multiply that "easing" value by the probability
          // that a mesh would get placed on a given face.
          place = Easing.easeInOut((rv - options.spread) * spreadRange) * options.spread > math.Random().nextDouble();
        }
      }
      else {
        place = options.spreadFunction!(vertex1, i / 9, faceNormal, i);
      }
      if (place) {
        // Don't place a mesh if the angle is too steep.
        if (faceNormal.angleTo(up) > options.maxSlope) {
          continue;
        }
        final mesh = options.mesh.clone();
        mesh.position.add2(vertex1, vertex2).add(vertex3).divideScalar(3);
        if (options.maxTilt > 0) {
          var normal = mesh.position.clone().add(faceNormal);
          mesh.lookAt(normal);
          var tiltAngle = faceNormal.angleTo(up);
          if (tiltAngle > options.maxTilt) {
            var ratio = options.maxTilt / tiltAngle;
            mesh.rotation.x *= ratio;
            mesh.rotation.y *= ratio;
            mesh.rotation.z *= ratio;
          }
        }
        mesh.rotation.x += 90 / 180 * math.pi;
        mesh.rotateY(math.Random().nextDouble() * 2 * math.pi);
        if (options.sizeVariance != 0) {
          var variance = math.Random().nextDouble() * doubleSizeVariance - options.sizeVariance;
          mesh.scale.x = mesh.scale.z = 1 + variance;
          mesh.scale.y += variance;
        }

        mesh.updateMatrix();
        options.scene?.add(mesh);
      }
    }

    return options.scene!;
  }

  /**
   * Generate a function that returns a heightmap to pass to ScatterMeshes.
   *
   * Specifically, this function generates a heightmap and then uses that
   * heightmap as a map of probabilities of where meshes will be placed.
   *
   * @param {Function} method
   *   A random terrain generation function (i.e. a valid value for the
   *   `options.heightmap` parameter of the `THREE.Terrain` function).
   * @param {Object} options
   *   A map of settings that control how the resulting noise should be generated
   *   (with the same parameters as the `options` parameter to the
   *   `THREE.Terrain` function). `options.minHeight` must equal `0` and
   *   `options.maxHeight` must equal `1` if they are specified.
   * @param {Number} skip
   *   The number of sequential faces to skip between faces that are candidates
   *   for placing a mesh. This avoid clumping meshes too closely together.
   *   Defaults to 1.
   * @param {Number} threshold
   *   The probability that, if a mesh can be placed on a non-skipped face due to
   *   the shape of the heightmap, a mesh actually will be placed there. Helps
   *   thin out placement and make it less regular. Defaults to 0.25.
   *
   * @return {Function}
   *   Returns a function that can be passed as the value of the
   *   `options.randomness` parameter to the {@link THREE.Terrain.ScatterMeshes}
   *   function.
   */
  static Float32List Function() scatterHelper(void Function(Float32List,TerrainOptions) method, TerrainOptions options, [int? skip, double? threshold]) {
    skip ??= 1;
    threshold ??= 0.25;
    options.frequency = options.frequency;

    final clonedOptions = TerrainOptions();
    for (final opt in options.keys) {
      clonedOptions[opt] = options[opt];
    }

    clonedOptions.xSegments *= 2;
    clonedOptions.stretch = true;
    clonedOptions.maxHeight = 1;
    clonedOptions.minHeight = 0;
    final heightmap = heightmapArray(method, clonedOptions);

    for (int i = 0, l = heightmap.length; i < l; i++) {
      if (i % skip != 0 || math.Random().nextDouble() > threshold) {
        heightmap[i] = 1; // 0 = place, 1 = don't place
      }
    }
    return () {
      return heightmap;
    };
  }

  /**
   * Generate a material that blends together textures based on vertex height.
   *
   * Inspired by http://www.chandlerprall.com/2011/06/blending-webgl-textures/
   *
   * Usage:
   *
   *    // Assuming the textures are already loaded
   *    var material = THREE.Terrain.generateBlendedMaterial([
   *      {texture: THREE.ImageUtils.loadTexture('img1.jpg')},
   *      {texture: THREE.ImageUtils.loadTexture('img2.jpg'), levels: [-80, -35, 20, 50]},
   *      {texture: THREE.ImageUtils.loadTexture('img3.jpg'), levels: [20, 50, 60, 85]},
   *      {texture: THREE.ImageUtils.loadTexture('img4.jpg'), glsl: '1.0 - smoothstep(65.0 + smoothstep(-256.0, 256.0, vPosition.x) * 10.0, 80.0, vPosition.z)'},
   *    ]);
   *
   * This material tries to behave exactly like a MeshLambertMaterial other than
   * the fact that it blends multiple texture maps together, although
   * ShaderMaterials are treated slightly differently by Three.js so YMMV. Note
   * that this means the texture will appear black unless there are lights
   * shining on it.
   *
   * @param {Object[]} textures
   *   An array of objects specifying textures to blend together and how to blend
   *   them. Each object should have a `texture` property containing a
   *   `THREE.Texture` instance. There must be at least one texture and the first
   *   texture does not need any other properties because it will serve as the
   *   base, showing up wherever another texture isn't blended in. Other textures
   *   must have either a `levels` property containing an array of four numbers
   *   or a `glsl` property containing a single GLSL expression evaluating to a
   *   float between 0.0 and 1.0. For the `levels` property, the four numbers
   *   are, in order: the height at which the texture will start blending in, the
   *   height at which it will be fully blended in, the height at which it will
   *   start blending out, and the height at which it will be fully blended out.
   *   The `vec3 vPosition` variable is available to `glsl` expressions; it
   *   contains the coordinates in Three-space of the texel currently being
   *   rendered.
   * @param {Three.Material} material
   *   An optional base material. You can use this to pick a different base
   *   material type such as `MeshStandardMaterial` instead of the default
   *   `MeshLambertMaterial`.
   */
  static Material generateBlendedMaterial(List<TerrainTextures> textures, [Material? material]) {
    // Convert numbers to strings of floats so GLSL doesn't barf on "1" instead of "1.0"
    String glslifyNumber(num n) {
      return n.toString();//n == (n.toInt()|0) ? '$n.0' : n.toString();
    }

    var declare = '',
        assign = '',
        t0Repeat = textures[0].texture.repeat,
        t0Offset = textures[0].texture.offset;

    for (int i = 0, l = textures.length; i < l; i++) {
      // Update textures
      textures[i].texture.wrapS = textures[i].texture.wrapT = RepeatWrapping;
      textures[i].texture.needsUpdate = true;

      // Shader fragments
      // Declare each texture, then mix them together.
      declare += 'uniform sampler2D texture_$i;\n';
      if (i != 0) {
        var v = textures[i].levels, // Vertex heights at which to blend textures in and out
            p = textures[i].glsl, // Or specify a GLSL expression that evaluates to a float between 0.0 and 1.0 indicating how opaque the texture should be at this texel
            useLevels = v != null, // Use levels if they exist; otherwise, use the GLSL expression
            tiRepeat = textures[i].texture.repeat,
            tiOffset = textures[i].texture.offset;
        if (useLevels) {
          // Must fade in; can't start and stop at the same point.
          // So, if levels are too close, move one of them slightly.
          if (v[1] - v[0] < 1) v[0] -= 1;
          if (v[3] - v[2] < 1) v[3] += 1;
          // for (var j = 0; j < v.length; j++) {
          //   v[j] = glslifyNumber(v[j]);
          // }
        }
        // The transparency of the new texture when it is layered on top of the existing color at this texel is
        // (how far between the start-blending-in and fully-blended-in levels the current vertex is) +
        // (how far between the start-blending-out and fully-blended-out levels the current vertex is)
        // So the opacity is 1.0 minus that.
        final blendAmount = !useLevels ? p :
            '1.0 - smoothstep(${v[0]}, ${v[1]}, vPosition.z) + smoothstep(${v[2]}, ${v[3]}, vPosition.z)';
        assign += '        color = mix( ' +
            'texture2D( texture_$i' + ', MyvUv * vec2( ' + glslifyNumber(tiRepeat.x) + ', ' + glslifyNumber(tiRepeat.y) + ' ) + vec2( ' + glslifyNumber(tiOffset.x) + ', ' + glslifyNumber(tiOffset.y) + ' ) ), ' +
            'color, ' +
            'max(min(' + blendAmount + ', 1.0), 0.0)' +
            ');\n';
        }
      }

    final fragBlend = 'float slope = acos(max(min(dot(myNormal, vec3(0.0, 0.0, 1.0)), 1.0), -1.0));\n' +
        '    diffuseColor = vec4( diffuse, opacity );\n' +
        '    vec4 color = texture2D( texture_0, MyvUv * vec2( ' + glslifyNumber(t0Repeat.x) + ', ' + glslifyNumber(t0Repeat.y) + ' ) + vec2( ' + glslifyNumber(t0Offset.x) + ', ' + glslifyNumber(t0Offset.y) + ' ) ); // base\n' +
            assign +
        '    diffuseColor = color;\n';

    final fragPars = declare + '\n' +
            'varying vec2 MyvUv;\n' +
            'varying vec3 vPosition;\n' +
            'varying vec3 myNormal;\n';

    final mat = material ?? MeshLambertMaterial();
    mat.onBeforeCompile = (WebGLParameters shader, WebGLRenderer renderer) {
      // Patch vertexShader to setup MyUv, vPosition, and myNormal
      shader.vertexShader = shader.vertexShader.replaceAll('#include <common>',
          'varying vec2 MyvUv;\nvarying vec3 vPosition;\nvarying vec3 myNormal;\n#include <common>');
      shader.vertexShader = shader.vertexShader.replaceAll('#include <uv_vertex>',
          'MyvUv = uv;\nvPosition = position;\nmyNormal = normal;\n#include <uv_vertex>');

      shader.fragmentShader = shader.fragmentShader.replaceAll('#include <common>', fragPars + '\n#include <common>');
      shader.fragmentShader = shader.fragmentShader.replaceAll('#include <map_fragment>', fragBlend);

      // Add our custom texture uniforms
      for (int i = 0, l = textures.length; i < l; i++) {
        shader.uniforms!['texture_$i'] = {
          'type': 't',
          'value': textures[i].texture,
        };
      }
    };

    return mat;
  }
}