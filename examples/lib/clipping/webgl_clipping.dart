import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglClipping extends StatefulWidget {
  
  const WebglClipping({super.key});
  
  @override
  createState() => _State();
}

class _State extends State<WebglClipping> {
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
        localClippingEnabled: true,
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

  late three.OrbitControls controls;
  late three.Object3D object;
  int startTime = 0;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(36, threeJs.width / threeJs.height, 0.25, 16);
    threeJs.camera.position.setValues(0, 1.3, 3);
    threeJs.scene = three.Scene();

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    threeJs.scene.add(three.AmbientLight(0x505050, 0.2));

    final spotLight = three.SpotLight(0xffffff);
    spotLight.angle = math.pi / 5;
    spotLight.penumbra = 0.2;
    spotLight.position.setValues(2, 3, 3);
    spotLight.castShadow = true;
    spotLight.shadow!.camera!.near = 3;
    spotLight.shadow!.camera!.far = 10;
    spotLight.shadow!.mapSize.width = 1024;
    spotLight.shadow!.mapSize.height = 1024;
    threeJs.scene.add(spotLight);

    final dirLight = three.DirectionalLight(0x55505a, 0.2);
    dirLight.position.setValues(0, 3, 0);
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.near = 1;
    dirLight.shadow!.camera!.far = 10;

    dirLight.shadow!.camera!.right = 1;
    dirLight.shadow!.camera!.left = -1;
    dirLight.shadow!.camera!.top = 1;
    dirLight.shadow!.camera!.bottom = -1;

    dirLight.shadow!.mapSize.width = 1024;
    dirLight.shadow!.mapSize.height = 1024;
    threeJs.scene.add(dirLight);

    // ***** Clipping planes: *****

    final localPlane = three.Plane(three.Vector3(0, -1, 0), 0.8);
    //final globalPlane = three.Plane(three.Vector3(-1, 0, 0), 0.1);

    // Geometry

    final material = three.MeshPhongMaterial.fromMap({
      "color": 0x80ee10,
      "shininess": 100,
      "side": three.DoubleSide,

      // ***** Clipping setup (material): *****
      "clippingPlanes": [localPlane],
      "clipShadows": true
    });

    final geometry = TorusKnotGeometry(0.4, 0.08, 95, 20);

    object = three.Mesh(geometry, material);
    object.castShadow = true;
    threeJs.scene.add(object);

    final ground = three.Mesh(three.PlaneGeometry(9, 9, 1, 1),
        three.MeshPhongMaterial.fromMap({"color": 0xa0adaf, "shininess": 150}));

    ground.rotation.x = -math.pi / 2; // rotates X/Y to X/Z
    ground.receiveShadow = true;
    threeJs.scene.add(ground);

    startTime = DateTime.now().millisecondsSinceEpoch;

    threeJs.addAnimationEvent((dt){
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final time = (currentTime - startTime) / 1000;

      object.position.y = 0.8;
      object.rotation.x = time * 0.5;
      object.rotation.y = time * 0.2;
      object.scale.setScalar(math.cos(time) * 0.125 + 0.875);
      controls.update();
    });
  }
}
