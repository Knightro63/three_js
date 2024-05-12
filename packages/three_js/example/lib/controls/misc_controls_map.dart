import 'dart:math' as math;
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class MiscControlsMap extends StatefulWidget {
  final String fileName;
  const MiscControlsMap({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MiscControlsMap> {
  late Demo demo;

  @override
  void initState() {
    demo = Demo(
      fileName: widget.fileName,
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: DemoSettings(
        renderOptions: {
          "minFilter": three.LinearFilter,
          "magFilter": three.LinearFilter,
          "format": three.RGBAFormat,
          "samples": 4
        }
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    demo.dispose();
    controls.clearListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return demo.threeDart();
  }

  late three.MapControls controls;

  void setup() {
    demo.scene = three.Scene();
    demo.scene.background = three.Color.fromHex32(0xcccccc);
    demo.scene.fog = three.FogExp2(three.Color.fromHex32(0xcccccc), 0.002);

    demo.camera = three.PerspectiveCamera(60, demo.width / demo.height, 1, 1000);
    demo.camera.position.setValues(400, 200, 0);
    demo.camera.lookAt(demo.scene.position);

    // controls

    controls = three.MapControls(demo.camera, demo.globalKey);

    controls.enableDamping =
        true; // an animation loop is required when either damping or auto-rotation are enabled
    controls.dampingFactor = 0.05;

    controls.screenSpacePanning = false;

    controls.minDistance = 100;
    controls.maxDistance = 500;

    controls.maxPolarAngle = math.pi / 2;

    // world
    final geometry = three.BoxGeometry(1, 1, 1);
    geometry.translate(0, 0.5, 0);
    final material =
        three.MeshPhongMaterial.fromMap({'color': 0xffffff, 'flatShading': true});

    for (int i = 0; i < 500; i++) {
      final mesh = three.Mesh(geometry, material);
      mesh.position.x = math.Random().nextDouble() * 1600 - 800;
      mesh.position.y = 0;
      mesh.position.z = math.Random().nextDouble() * 1600 - 800;
      mesh.scale.x = 20;
      mesh.scale.y = math.Random().nextDouble() * 80 + 10;
      mesh.scale.z = 20;
      mesh.updateMatrix();
      mesh.matrixAutoUpdate = false;
      demo.scene.add(mesh);
    }
    // lights

    final dirLight1 = three.DirectionalLight(0xffffff);
    dirLight1.position.setValues(1, 1, 1);
    demo.scene.add(dirLight1);

    final dirLight2 = three.DirectionalLight(0x002288);
    dirLight2.position.setValues(-1, -1, -1);
    demo.scene.add(dirLight2);

    final ambientLight = three.AmbientLight(0x222222);
    demo.scene.add(ambientLight);


    demo.addAnimationEvent((dt){
      controls.update();
    });
  }
}
