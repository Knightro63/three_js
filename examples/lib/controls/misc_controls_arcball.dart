import 'dart:async';

import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_transform_controls/three_js_transform_controls.dart';

class MiscControlsArcball extends StatefulWidget {
  
  const MiscControlsArcball({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MiscControlsArcball> {
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
        useOpenGL: true
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    controls.dispose();
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

  late ArcballControls controls;

  void setup() {

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xcccccc);
    threeJs.scene.fog = three.FogExp2(0xcccccc, 0.002);

    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2000);
    threeJs.camera.position.setValues(0, 0, 200);
    threeJs.camera.lookAt(threeJs.scene.position);

    // controls

    controls = ArcballControls(threeJs.camera, threeJs.globalKey, threeJs.scene, 1);
    controls.addEventListener('change', (event) {
      threeJs.render();
    });

    // world

    final geometry = three.BoxGeometry(30, 30, 30);
    final material =
        three.MeshPhongMaterial.fromMap({"color": 0xffff00, "flatShading": true});

    final mesh = three.Mesh(geometry, material);

    threeJs.scene.add(mesh);

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
