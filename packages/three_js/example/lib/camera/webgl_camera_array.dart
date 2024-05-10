import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglCameraArray extends StatefulWidget {
  final String fileName;
  const WebglCameraArray({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglCameraArray> {
  late Demo demo;

  @override
  void initState() {
    demo = Demo(
      fileName: widget.fileName,
      onSetupComplete: (){setState(() {});},
      setup: setup
    );
    super.initState();
  }
  @override
  void dispose() {
    demo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return demo.threeDart();
  }

  void setup() {
    late three.Mesh mesh;
    int amount = 4;
    var width = (demo.width / amount) * demo.dpr;
    var height = (demo.height / amount) * demo.dpr;

    List<three.Camera> cameras = [];

    for (var y = 0; y < amount; y++) {
      for (var x = 0; x < amount; x++) {
        var subcamera = three.PerspectiveCamera(40, demo.width / demo.height, 0.1, 10);
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

    demo.camera = three.ArrayCamera(cameras);
    // camera = new three.PerspectiveCamera(45, width / height, 1, 10);
    demo.camera.position.z = 3;
    demo.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xcccccc, 0.4);
    demo.scene.add(ambientLight);
    demo.camera.lookAt(demo.scene.position);

    final light = three.DirectionalLight(0xffffff, null);
    light.position.setValues(0.5, 0.5, 1);
    light.castShadow = true;
    light.shadow!.camera!.zoom = 4; // tighter shadow map
    demo.scene.add(light);

    final geometryBackground = three.PlaneGeometry(100, 100);
    final materialBackground = three.MeshPhongMaterial.fromMap({"color": 0x000066});

    final background = three.Mesh(geometryBackground, materialBackground);
    background.receiveShadow = true;
    background.position.setValues(0, 0, -1);
    demo.scene.add(background);

    final geometryCylinder = CylinderGeometry(0.5, 0.5, 1, 32);
    final materialCylinder = three.MeshPhongMaterial.fromMap({"color": 0xff0000});

    mesh = three.Mesh(geometryCylinder, materialCylinder);
    // mesh.castShadow = true;
    // mesh.receiveShadow = true;
    demo.scene.add(mesh);
     
    demo.addAnimationEvent(
      (delta){
        mesh.rotation.x += 0.1;
        mesh.rotation.y += 0.05;
      }
    );
  }
}
