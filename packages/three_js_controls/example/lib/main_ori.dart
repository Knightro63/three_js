import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js_controls/three_js_controls.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_math/three_js_math.dart' as tmath;

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
      home: const MiscControlsOrbit(),
    );
  }
}


class MiscControlsOrbit extends StatefulWidget {
  const MiscControlsOrbit({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MiscControlsOrbit> {
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
    controls.dispose();
    threeJs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: threeJs.build()
    );
  }

  late DeviceOrientationControls controls;

  void setup() {
    threeJs.scene = three.Scene();
    threeJs.scene.background = tmath.Color.fromHex32(0xcccccc);
    threeJs.scene.fog = three.FogExp2(0xcccccc, 0.002);

    threeJs.camera = three.PerspectiveCamera(60, threeJs.width / threeJs.height, 1, 1000);
    threeJs.camera.position.setValues(400, 200, 0);
    threeJs.camera.lookAt(threeJs.scene.position);

    // controls

    controls = DeviceOrientationControls(threeJs.camera, threeJs.globalKey);

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
