import 'dart:math' as math;

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
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
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
    threeJs.dispose();
    controls.clearListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: threeJs.build()
    );
  }

  late three.TrackballControls controls;

  void setup() {
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xcccccc);
    threeJs.scene.fog = three.FogExp2(three.Color.fromHex32(0xcccccc), 0.002);

    threeJs.camera = three.PerspectiveCamera(60, threeJs.width / threeJs.height, 1, 1000);
    threeJs.camera.position.setValues(400, 200, 0);
    threeJs.camera.lookAt(threeJs.scene.position);

    // controls

    controls = three.TrackballControls(threeJs.camera, threeJs.globalKey);

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
      threeJs.scene.add(mesh);
    }

    // lights

    final dirLight1 = three.DirectionalLight(0xffffff);
    dirLight1.position.setValues(1, 1, 1);
    threeJs.scene.add(dirLight1);

    final dirLight2 = three.DirectionalLight(0x002288);
    dirLight2.position.setValues(-1, -1, -1);
    threeJs.scene.add(dirLight2);

    final ambientLight = three.AmbientLight(0x222222);
    threeJs.scene.add(ambientLight);

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
