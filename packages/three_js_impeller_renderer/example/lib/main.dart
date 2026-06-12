import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_math/three_js_math.dart' as tmath;
import 'package:three_js_impeller_renderer/three_js_impeller_renderer.dart';
import 'dart:math' as math;

void main() {
  //Console.isVerbose = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebglGeometries(),
    );
  }
}

class WebglGeometries extends StatefulWidget {
  const WebglGeometries({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglGeometries> {
  late ThreeJS threeJs;

  @override
  void initState() {
    threeJs = ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return threeJs.build();
  }

  int startTime = 0;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2000);
    threeJs.camera.position.y = 400;

    threeJs.scene = three.Scene();
    threeJs.scene.background = tmath.Color.fromHex32( 0x111111 );
    //threeJs.scene.fog = three.Fog( 0xa0a0a0, 500, 1200 );

    three.Mesh object;

    final ambientLight = three.AmbientLight(0xffffff, 0.3);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.8);
    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    // const subdivisions = 6;
    // const recursion = 1;

    // final points = GeometryUtils.hilbert3D( tmath.Vector3( 0, 0, 0 ), 25.0, recursion, 0, 1, 2, 3, 4, 5, 6, 7 );
    // final spline = CatmullRomCurve3(points: points );

    // final samples = spline.getPoints( points.length * subdivisions );
    // final geometrySpline = three.BufferGeometry().setFromPoints( samples );

    // final line = three.Line( geometrySpline, three.LineDashedMaterial.fromMap( { 'color': 0xffffff, 'dashSize': 1, 'gapSize': 0.5 } ) );
    // line.computeLineDistances();
    // threeJs.scene.add( line );

    // final geometryBox = box( 50, 50, 50 );

    // final lineSegments = three.LineSegments( geometryBox, three.LineDashedMaterial.fromMap( { 'color': 0xffaa00, 'dashSize': 3, 'gapSize': 1 } ) );
    // lineSegments.computeLineDistances();
    // threeJs.scene.add( lineSegments );

    final material = three.MeshNormalMaterial.fromMap({
      "color": 0xff00ff,
      "side": tmath.DoubleSide,
      // "transparent": true,
      // "opacity": 0.5,
      // 'wireframe': true
    });

    object = three.Mesh(three.SphereGeometry(75, 20, 10), material);
    object.position.setValues(-300, 0, 200);
    threeJs.scene.add(object);

    object = three.Mesh(three.PlaneGeometry(120, 100, 4, 4), material);
    object.position.setValues(-300, 0, 0);
    threeJs.scene.add(object);

    object = three.Mesh(three.BoxGeometry(100, 100, 100, 4, 4, 4), material);
    object.position.setValues(-100, 0, 0);
    threeJs.scene.add(object);

    startTime = DateTime.now().millisecondsSinceEpoch;

    threeJs.addAnimationEvent((dt){
      final timer = DateTime.now().millisecondsSinceEpoch * 0.0001;

      threeJs.camera.position.x = math.cos(timer) * 800;
      threeJs.camera.position.z = math.sin(timer) * 800;
      threeJs.camera.lookAt(threeJs.scene.position);

      threeJs.scene.traverse((object) {
        final time = DateTime.now().millisecondsSinceEpoch * 0.001;

        if (object is three.Mesh) {
          object.rotation.x = 0.25 * time;
          object.rotation.y = 0.25 * time;
        }
      });
    });
  }

  three.BufferGeometry box(double width,double height,double depth ) {
    width = width * 0.5;
    height = height * 0.5;
    depth = depth * 0.5;

    final geometry = three.BufferGeometry();
    final List<double> position = [];

    position.addAll([
      - width, - height, - depth,
      - width, height, - depth,

      - width, height, - depth,
      width, height, - depth,

      width, height, - depth,
      width, - height, - depth,

      width, - height, - depth,
      - width, - height, - depth,

      - width, - height, depth,
      - width, height, depth,

      - width, height, depth,
      width, height, depth,

      width, height, depth,
      width, - height, depth,

      width, - height, depth,
      - width, - height, depth,

      - width, - height, - depth,
      - width, - height, depth,

      - width, height, - depth,
      - width, height, depth,

      width, height, - depth,
      width, height, depth,

      width, - height, - depth,
      width, - height, depth
    ]);

    geometry.setAttributeFromString( 'position', tmath.Float32BufferAttribute.fromList( position, 3 ) );
    return geometry;
  }

  late three.PointLight pointLight;
  final objects = [], materials = [];

  Future<void> setup2() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2000);
    threeJs.camera.position.setValues(0, 200, 800);
    threeJs.scene = three.Scene();
    threeJs.scene.background = threeJs.scene.environment = three.DataTexture(generateTexture().data, 256~/4, 256~/4);

    // Grid

    final helper = GridHelper(1000, 40, 0x303030, 0x303030);
    helper.position.y = -75;
    threeJs.scene.add(helper);

    // Materials
    final three.DataTexture texture = three.DataTexture(generateTexture().data, 256~/4, 256~/4);
    texture.needsUpdate = true;

    materials.add(three.MeshLambertMaterial.fromMap({
      "map": texture,
      "color": 0xff0000,
      "transparent": true,
    }));
    materials.add(three.MeshLambertMaterial.fromMap({"color": 0xdddddd,}));
    materials.add(three.MeshPhongMaterial.fromMap({
      "color": 0xdddddd,
      "specular": 0x009900,
      "shininess": 30,
      "flatShading": true
    }));
    materials.add(three.MeshNormalMaterial());
    materials.add(three.MeshBasicMaterial.fromMap({
      "color": 0xffaa00,
      "transparent": true,
      "blending": tmath.AdditiveBlending
    }));
    materials.add(three.MeshLambertMaterial.fromMap({"color": 0xdddddd}));
    materials.add(three.MeshStandardMaterial.fromMap({
      "color": 0xffffff,
      "specular": 0x009900,
      "shininess": 30,
      "map": texture,
      "transparent": true,
      "blending": tmath.AdditiveBlending
    }));
    materials.add(three.MeshNormalMaterial.fromMap({"flatShading": true}));
    materials.add(three.MeshBasicMaterial.fromMap({"color": 0xffaa00, "wireframe": true}));
    materials.add(three.MeshDepthMaterial());
    materials.add(three.MeshLambertMaterial.fromMap({"color": 0x666666, "emissive": 0xff0000}));
    materials.add(three.MeshPhongMaterial.fromMap({
      "color": 0x000000,
      "specular": 0x666666,
      "emissive": 0xff0000,
      "shininess": 10,
      "opacity": 0.9,
      "transparent": true,
    }));
    materials.add(three.MeshStandardMaterial.fromMap({"map": texture, "transparent": true}));

    // Spheres geometry

    final geometry = three.SphereGeometry(70, 32, 16);

    for (int i = 0, l = materials.length; i < l; i++) {
      addMesh(geometry, materials[i]);
    }

    // Lights

    threeJs.scene.add(three.AmbientLight(0x111111, 1));

    final directionalLight = three.DirectionalLight(0xffffff, 0.125);

    directionalLight.position.x = math.Random().nextDouble() - 0.5;
    directionalLight.position.y = math.Random().nextDouble() - 0.5;
    directionalLight.position.z = math.Random().nextDouble() - 0.5;
    directionalLight.position.normalize();

    threeJs.scene.add(directionalLight);

    pointLight = three.PointLight(0xffffff, 1);
    threeJs.scene.add(pointLight);

    pointLight.add(three.Mesh(three.SphereGeometry(4, 8, 8),three.MeshBasicMaterial.fromMap({"color": 0xffffff})));

    threeJs.addAnimationEvent((dt){
      animate(dt);
    });
  }

  three.ImageElement generateTexture() {
    final pixels = Uint8List(256 * 256 * 4);

    int x = 0, y = 0, l = pixels.length;

    for (int i = 0, j = 0; i < l; i += 4, j++) {
      x = j % 256;
      y = (x == 0) ? y + 1 : y;

      pixels[i] = 255;
      pixels[i + 1] = 255;
      pixels[i + 2] = 255;
      pixels[i + 3] = (x ^ y).floor();
    }

    return three.ImageElement(data: pixels, width: 256, height: 256);
  }

  addMesh(geometry, material) {
    final mesh = three.Mesh(geometry, material);

    mesh.position.x = (objects.length % 4) * 200 - 400;
    mesh.position.z = (objects.length / 4).floor() * 200 - 200;

    mesh.rotation.x = math.Random().nextDouble() * 200 - 100;
    mesh.rotation.y = math.Random().nextDouble() * 200 - 100;
    mesh.rotation.z = math.Random().nextDouble() * 200 - 100;

    objects.add(mesh);

    threeJs.scene.add(mesh);
  }

  void animate(double dt) {
    final timer = 0.0001 * DateTime.now().millisecondsSinceEpoch;

    threeJs.camera.position.x = math.cos(timer) * 1000;
    threeJs.camera.position.z = math.sin(timer) * 1000;

    threeJs.camera.lookAt(threeJs.scene.position);

    for (int i = 0, l = objects.length; i < l; i++) {
      final object = objects[i];

      object.rotation.x += 0.01;
      object.rotation.y += 0.01;
    }

    materials[materials.length - 2]
        .emissive
        .setHSL(0.54, 1.0, 0.35 * (0.5 + 0.5 * math.sin(35 * timer)));
    materials[materials.length - 3]
        .emissive
        .setHSL(0.04, 1.0, 0.35 * (0.5 + 0.5 * math.cos(35 * timer)));

    pointLight.position.x = math.sin(timer * 7) * 300;
    pointLight.position.y = math.cos(timer * 5) * 400;
    pointLight.position.z = math.cos(timer * 3) * 300;
  }
}

class GeometryUtils{
  static List<tmath.Vector3> hilbert3D([tmath.Vector3? center, double? size, int? iterations,int? v0,int? v1,int? v2,int? v3,int? v4,int? v5,int? v6,int? v7]) {
    // Default Vars
    center ??= tmath.Vector3(0, 0, 0);
    size ??= 10;

    var half = size / 2;
    iterations ??= 1;
    v0 ??= 0;
    v1 ??= 1;
    v2 ??= 2;
    v3 ??= 3;
    v4 ??= 4;
    v5 ??= 5;
    v6 ??= 6;
    v7 ??= 7;

    var vecS = [
      tmath.Vector3(center.x - half, center.y + half, center.z - half),
      tmath.Vector3(center.x - half, center.y + half, center.z + half),
      tmath.Vector3(center.x - half, center.y - half, center.z + half),
      tmath.Vector3(center.x - half, center.y - half, center.z - half),
      tmath.Vector3(center.x + half, center.y - half, center.z - half),
      tmath.Vector3(center.x + half, center.y - half, center.z + half),
      tmath.Vector3(center.x + half, center.y + half, center.z + half),
      tmath.Vector3(center.x + half, center.y + half, center.z - half)
    ];

    var vec = [
      vecS[v0],
      vecS[v1],
      vecS[v2],
      vecS[v3],
      vecS[v4],
      vecS[v5],
      vecS[v6],
      vecS[v7]
    ];

    // Recurse iterations
    if (--iterations >= 0) {
      List<tmath.Vector3> tmp = [];

      tmp.addAll(hilbert3D(
          vec[0], half, iterations, v0, v3, v4, v7, v6, v5, v2, v1));
      tmp.addAll(hilbert3D(
          vec[1], half, iterations, v0, v7, v6, v1, v2, v5, v4, v3));
      tmp.addAll(hilbert3D(
          vec[2], half, iterations, v0, v7, v6, v1, v2, v5, v4, v3));
      tmp.addAll(hilbert3D(
          vec[3], half, iterations, v2, v3, v0, v1, v6, v7, v4, v5));
      tmp.addAll(hilbert3D(
          vec[4], half, iterations, v2, v3, v0, v1, v6, v7, v4, v5));
      tmp.addAll(hilbert3D(
          vec[5], half, iterations, v4, v3, v2, v5, v6, v1, v0, v7));
      tmp.addAll(hilbert3D(
          vec[6], half, iterations, v4, v3, v2, v5, v6, v1, v0, v7));
      tmp.addAll(hilbert3D(
          vec[7], half, iterations, v6, v5, v2, v1, v0, v3, v4, v7));

      // Return recursive call
      return tmp;
    }

    // Return complete Hilbert Curve.
    return vec;
  }
}