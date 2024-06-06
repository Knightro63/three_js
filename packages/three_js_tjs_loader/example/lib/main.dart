import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_math/three_js_math.dart' as tmath;
import 'package:three_js_tjs_loader/three_js_tjs_loader.dart';

enum Method {
  instance,
  merged,
  native
}

void main() {
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
      home: const WebglInstancingPerformance(),
    );
  }
}

class WebglInstancingPerformance extends StatefulWidget {
  const WebglInstancingPerformance({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglInstancingPerformance> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        renderOptions: {
          "minFilter": tmath.LinearFilter,
          "magFilter": tmath.LinearFilter,
          "format": tmath.RGBAFormat,
          "samples": 4
        }
      )
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

  late three.Material material;

  final Map<String,dynamic> api = {
    'method': Method.instance,
    'count': 1000
  };

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(70, threeJs.width / threeJs.height, 1, 100);
    threeJs.camera.position.z = 30;

    threeJs.scene = three.Scene();
    threeJs.scene.background = tmath.Color.fromHex32(0xffffff);

    material = three.MeshNormalMaterial();

    //final geometry = three.BoxGeometry(5, 5, 5);
		BufferGeometryLoader()
      .fromAsset( 'assets/suzanne_buffergeometry.json')
      .then((geometry ) {
        geometry as three.BufferGeometry;
        material = three.MeshNormalMaterial();
        geometry.computeVertexNormals();

        switch ( api['method'] ) {
          case Method.instance:
            makeInstanced( geometry );
            break;
          // case Method.merged:
          //   makeMerged( geometry );
          //   break;
          case Method.native:
            makeNaive( geometry );
            break;
        }
      });

    threeJs.addAnimationEvent((dt){
      threeJs.scene.rotation.x += 0.002;
      threeJs.scene.rotation.y += 0.001;
    });
  }

  void makeInstanced(three.BufferGeometry geometry) {
    final matrix = tmath.Matrix4();
    final mesh = three.InstancedMesh(geometry, material, api['count']);

    for (int i = 0; i < api['count']; i++) {
      randomizeMatrix(matrix);
      mesh.setMatrixAt(i, matrix);
    }

    threeJs.scene.add(mesh);  
  }

  void makeNaive(three.BufferGeometry geometry) {
    final matrix = tmath.Matrix4();

    for (int i = 0; i < api['count']; i++) {
      final mesh = three.Mesh(geometry, material);
      randomizeMatrix(matrix);
      mesh.applyMatrix4(matrix);
      threeJs.scene.add(mesh);
    }
  }

  final position = tmath.Vector3();
  final rotation = tmath.Euler(0, 0, 0);
  final quaternion = tmath.Quaternion();
  final scale = tmath.Vector3();

  void randomizeMatrix(tmath.Matrix4 matrix) {
    position.x = math.Random().nextDouble() * 40 - 20;
    position.y = math.Random().nextDouble() * 40 - 20;
    position.z = math.Random().nextDouble() * 40 - 20;

    rotation.x = math.Random().nextDouble() * 2 * math.pi;
    rotation.y = math.Random().nextDouble() * 2 * math.pi;
    rotation.z = math.Random().nextDouble() * 2 * math.pi;

    quaternion.setFromEuler(rotation, false);

    scale.x = scale.y = scale.z = math.Random().nextDouble() * 1;

    matrix.compose(position, quaternion, scale);
  }
}
