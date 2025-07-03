import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglHelpers extends StatefulWidget {
  
  const WebglHelpers({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglHelpers> {
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
    controls.dispose();
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
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

  late three.Object3D object;
  late three.Texture texture;
  late three.PointLight light;

  VertexNormalsHelper? vnh;
  VertexTangentsHelper? vth;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(70, threeJs.width / threeJs.height, 1, 1000);
    threeJs.camera.position.z = 400;
    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    // scene

    threeJs.scene = three.Scene();

    light = three.PointLight(0xffffff);
    light.position.setValues(200, 100, 150);
    threeJs.scene.add(light);

    threeJs.scene.add(PointLightHelper(light, 15, 0xffffff));

    final gridHelper = GridHelper(400, 40, 0x0000ff, 0x808080);
    gridHelper.position.y = -150;
    gridHelper.position.x = -150;
    threeJs.scene.add(gridHelper);

    final polarGridHelper = PolarGridHelper(200, 16, 8, 64, three.Color.fromHex32(0x0000ff), three.Color.fromHex32(0x808080));
    polarGridHelper.position.y = -150;
    polarGridHelper.position.x = 200;
    threeJs.scene.add(polarGridHelper);

    threeJs.camera.lookAt(threeJs.scene.position);

    final loader = three.GLTFLoader().setPath('assets/models/gltf/');

    final result = await loader.fromAsset('LeePerrySmith.gltf');
    // final result = await loader.loadAsync( 'animate7.gltf';
    // final result = await loader.loadAsync( 'untitled22.gltf');

    three.console.info(" load gltf success result: $result  ");
    final model = result!.scene;
    final mesh = model.children[2];
    three.console.info(" load gltf success mesh: $mesh  ");

    mesh.geometry?.computeTangents(); // generates bad data due to degenerate UVs

    final group = three.Group();
    group.scale.scale(50);
    threeJs.scene.add(group);

    // To make sure that the matrixWorld is up to date for the boxhelpers
    group.updateMatrixWorld(true);

    group.add(mesh);

    vnh = VertexNormalsHelper(mesh, 5);
    threeJs.scene.add(vnh!);

    vth = VertexTangentsHelper(mesh, 5);
    threeJs.scene.add(vth!);

    threeJs.scene.add(BoxHelper(mesh));

    final wireframe = WireframeGeometry(mesh.geometry!);

    three.LineSegments line = three.LineSegments(wireframe, null);

    line.material?.depthTest = false;
    line.material?.opacity = 0.25;
    line.material?.transparent = true;
    line.position.x = 4;
    group.add(line);
    threeJs.scene.add(BoxHelper(line));

    final edges = EdgesGeometry(mesh.geometry!, null);
    line = three.LineSegments(edges, null);
    line.material?.depthTest = false;
    line.material?.opacity = 0.25;
    line.material?.transparent = true;
    line.position.x = -4;
    group.add(line);
    threeJs.scene.add(BoxHelper(line));

    threeJs.scene.add(BoxHelper(group));
    threeJs.scene.add(BoxHelper(threeJs.scene));

    threeJs.addAnimationEvent((dt){
      animate();
      controls.update();
    });
  }

  void animate() {
    final time = -DateTime.now().millisecondsSinceEpoch * 0.00003;

    threeJs.camera.position.x = 400 * math.cos(time);
    threeJs.camera.position.z = 400 * math.sin(time);
    threeJs.camera.lookAt(threeJs.scene.position);

    light.position.x = math.sin(time * 1.7) * 300;
    light.position.y = math.cos(time * 1.5) * 400;
    light.position.z = math.cos(time * 1.3) * 300;

    if (vnh != null) vnh!.update();
    if (vth != null) vth!.update();
  }
}
