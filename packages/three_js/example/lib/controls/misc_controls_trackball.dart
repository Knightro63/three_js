import 'dart:math' as math;
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class MiscControlsTrackball extends StatefulWidget {
  final String fileName;
  const MiscControlsTrackball({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MiscControlsTrackball> {
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

  late three.TrackballControls controls;

  void setup() {
    demo.scene = three.Scene();
    demo.scene.background = three.Color.fromHex32(0xcccccc);
    demo.scene.fog = three.FogExp2(three.Color.fromHex32(0xcccccc), 0.002);

    demo.camera = three.PerspectiveCamera(60, demo.width / demo.height, 1, 1000);
    demo.camera.position.setValues(400, 200, 0);
    demo.camera.lookAt(demo.scene.position);

    // controls

    controls = three.TrackballControls(demo.camera, demo.globalKey);

    controls.rotateSpeed = 1.0;
    controls.zoomSpeed = 1.2;
    controls.panSpeed = 0.8;

    controls.keys = ['KeyA', 'KeyS', 'KeyD'];

    // world

    final geometry = CylinderGeometry(0, 10, 30, 4, 1);
    final material = three.MeshPhongMaterial.fromMap({"color": 0xffffff, "flatShading": true});

    for (int i = 0; i < 500; i++) {
      final mesh = three.Mesh(geometry, material);
      mesh.position.x = math.Random().nextDouble() * 1600 - 800;
      mesh.position.y = 0;
      mesh.position.z = math.Random().nextDouble() * 1600 - 800;
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
