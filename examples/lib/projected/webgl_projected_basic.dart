import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglProjectedBasic extends StatefulWidget {
  const WebglProjectedBasic({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglProjectedBasic> {
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
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    controls.dispose();
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

  late three.OrbitControls controls;

  Future<void> setup() async {
    // scene
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0x222222);

    // create a new camera from which to project
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width/threeJs.height, 0.01, 100);
    threeJs.camera.position.setValues(0,1.2,4);
    threeJs.camera.lookAt(three.Vector3(0, 0, 0));

    // load the example texture
    final texture = await three.TextureLoader().fromAsset('assets/textures/uv_grid_directx.jpg');
    final camera = three.PerspectiveCamera(45, 1, 0.01, 3);
    camera.position.setValues(-1, 1.2, 2);
    camera.lookAt(three.Vector3(0, 0, 0));

    // add a camer frustum helper just for demostration purposes
    final helper = CameraHelper(camera);
    threeJs.scene.add(helper);

    // create the mesh with the projected material
    final geometry = three.BoxGeometry(1, 1, 1);
    final material = three.ProjectedMaterial(
      camera: camera,
      texture: texture!,
      options: {'color': 0x37E140}
    );
    final box = three.Mesh(geometry, material);
    threeJs.scene.add(box);

    // move the mesh any way you want!
    box.rotation.y = -math.pi / 4;

    // and when you're ready project the texture!
    material.project(box);

    // add lights
    final ambientLight = three.AmbientLight(0xffffff, 0.8);
    threeJs.scene.add(ambientLight);

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);
  }
}
