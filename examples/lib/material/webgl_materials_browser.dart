import 'package:example/src/statistics.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglMaterialsBrowser extends StatefulWidget {
  
  const WebglMaterialsBrowser({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglMaterialsBrowser> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
      });
    });
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          threeJs.build(),
          Statistics(data: data)
        ],
      ) 
    );
  }

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2000);
    threeJs.camera.position.z = 250;

    // scene

    threeJs.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xcccccc, 1);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 200);
    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    // texture
    final geometry = TorusKnotGeometry(10, 3, 200, 32).toNonIndexed();
    final material = three.MeshPhysicalMaterial.fromMap({"color": 0xff0abb, "roughness": 0});

    final object = three.Mesh(geometry, material);

    threeJs.scene.add(object);
  }
}
