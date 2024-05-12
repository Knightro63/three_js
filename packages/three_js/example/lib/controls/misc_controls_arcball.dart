import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_transform_controls/three_js_transform_controls.dart';

class MiscControlsArcball extends StatefulWidget {
  final String fileName;
  const MiscControlsArcball({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MiscControlsArcball> {
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
    controls.clearListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return demo.threeDart();
  }

  late ArcballControls controls;

  void setup() {

    demo.scene = three.Scene();
    demo.scene.background = three.Color.fromHex32(0xcccccc);
    demo.scene.fog = three.FogExp2(three.Color.fromHex32(0xcccccc), 0.002);

    demo.camera = three.PerspectiveCamera(45, demo.width / demo.height, 1, 2000);
    demo.camera.position.setValues(0, 0, 200);
    demo.camera.lookAt(demo.scene.position);

    // controls

    controls = ArcballControls(demo.camera, demo.globalKey, demo.scene, 1);
    controls.addEventListener('change', (event) {
      demo.render();
    });

    // world

    final geometry = three.BoxGeometry(30, 30, 30);
    final material =
        three.MeshPhongMaterial.fromMap({"color": 0xffff00, "flatShading": true});

    final mesh = three.Mesh(geometry, material);

    demo.scene.add(mesh);

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
