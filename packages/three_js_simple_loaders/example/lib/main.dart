import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_simple_loaders/three_js_simple_loaders.dart';

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
      home: const WebglLoaderObjMtl(),
    );
  }
}

class WebglLoaderObjMtl extends StatefulWidget {
  const WebglLoaderObjMtl({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderObjMtl> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup
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

  late three.Object3D object;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 0.1, 20);
    threeJs.camera.position.z = 2.5;

    threeJs.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xcccccc, 0.4);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.8);
    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    // texture
    final manager = LoadingManager();

    final mtlLoader = MTLLoader(manager);
    mtlLoader.setPath('assets/obj/male02/');
    final materials = await mtlLoader.fromAsset('male02.mtl');
    await materials?.preload();

    final loader = OBJLoader();
    loader.setMaterials(materials);
    object = (await loader.fromAsset('assets/obj/male02/male02.obj'))!;

    object.position.y = - 0.95;
    object.scale.setScalar( 0.01 );
    threeJs.scene.add(object);
  }
}

