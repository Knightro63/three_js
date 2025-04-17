import 'package:example/src/statistics.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglCameraArray extends StatefulWidget {
  
  const WebglCameraArray({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglCameraArray> {
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
      setup: setup,
      settings: three.Settings(
        useOpenGL: useOpenGL
      )
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

  void setup() {
    late three.Mesh mesh;
    int amount = 4;
    final width = (threeJs.width / amount) * threeJs.dpr;
    final height = (threeJs.height / amount) * threeJs.dpr;

    List<three.Camera> cameras = [];

    for (int y = 0; y < amount; y++) {
      for (int x = 0; x < amount; x++) {
        final subcamera = three.PerspectiveCamera(40, threeJs.width / threeJs.height, 0.1, 10);
        subcamera.viewport = three.Vector4(
            (x * width).floorToDouble(),
            (y * height).floorToDouble(),
            (width).ceilToDouble(),
            (height).ceilToDouble());
        subcamera.position.x = (x / amount) - 0.5;
        subcamera.position.y = 0.5 - (y / amount);
        subcamera.position.z = 1.5;
        subcamera.position.scale(2);
        subcamera.lookAt(three.Vector3(0, 0, 0));
        subcamera.updateMatrixWorld(false);
        cameras.add(subcamera);
      }
    }

    threeJs.camera = three.ArrayCamera(cameras);
    // camera = new three.PerspectiveCamera(45, width / height, 1, 10);
    threeJs.camera.position.z = 3;
    threeJs.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xcccccc, 0.4);
    threeJs.scene.add(ambientLight);
    threeJs.camera.lookAt(threeJs.scene.position);

    final light = three.DirectionalLight(0xffffff);
    light.position.setValues(0.5, 0.5, 1);
    light.castShadow = true;
    light.shadow!.camera!.zoom = 4; // tighter shadow map
    threeJs.scene.add(light);

    final geometryBackground = three.PlaneGeometry(100, 100);
    final materialBackground = three.MeshPhongMaterial.fromMap({"color": 0x000066});

    final background = three.Mesh(geometryBackground, materialBackground);
    background.receiveShadow = true;
    background.position.setValues(0, 0, -1);
    threeJs.scene.add(background);

    final geometryCylinder = CylinderGeometry(0.5, 0.5, 1, 32);
    final materialCylinder = three.MeshPhongMaterial.fromMap({"color": 0xff0000});

    mesh = three.Mesh(geometryCylinder, materialCylinder);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    threeJs.scene.add(mesh);
     
    threeJs.addAnimationEvent(
      (delta){
        mesh.rotation.x += 0.1;
        mesh.rotation.y += 0.05;
      }
    );
  }
}
