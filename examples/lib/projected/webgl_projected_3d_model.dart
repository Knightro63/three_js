import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_tjs_loader/buffer_geometry_loader.dart';

class WebglProjected3DModel extends StatefulWidget {
  const WebglProjected3DModel({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglProjected3DModel> {
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
    threeJs.scene.background = three.Color.fromHex32(0xE6E6E6);

    // create a new camera from which to project
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width/threeJs.height, 0.01, 100);
    threeJs.camera.position.setValues(0,1.2,4);
    threeJs.camera.lookAt(three.Vector3(0, 0, 0));

    // load the example texture
    final texture = await three.TextureLoader().fromAsset('assets/textures/uv_grid_directx.jpg');

    // create the mesh with the projected material
    final geometry = await BufferGeometryLoader().fromAsset( 'assets/models/json/suzanne_buffergeometry.json');
    geometry?.computeVertexNormals();
    geometry?.scale( 0.5, 0.5, 0.5 );

    final material = three.ProjectedMaterial(
      camera: threeJs.camera,
      texture: texture!,
      textureScale: 0.8,
      options: {'color': 0xcccccc}
    );
    final mesh = three.Mesh(geometry, material);
    threeJs.scene.add(mesh);

    // and when you're ready project the texture!
    material.project(mesh);

    // move the mesh any way you want!
    mesh.rotation.y = -math.pi / 4;

    // add lights
    final directionalLight = three.DirectionalLight(0xffffff, 0.6);
    directionalLight.position.setValues(0, 10, 10);
    threeJs.scene.add(directionalLight);

    final ambientLight = three.AmbientLight(0xffffff, 0.6);
    threeJs.scene.add(ambientLight);

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);
  }
}
