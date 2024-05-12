import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglClipping extends StatefulWidget {
  final String fileName;
  const WebglClipping({super.key, required this.fileName});
  
  @override
  createState() => _State();
}

class _State extends State<WebglClipping> {
  late Demo demo;

  @override
  void initState() {
    demo = Demo(
      fileName: widget.fileName,
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: DemoSettings(
        localClippingEnabled: true
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

  late three.OrbitControls controls;
  late three.Object3D object;
  int startTime = 0;

  Future<void> setup() async {
    demo.camera = three.PerspectiveCamera(36, demo.width / demo.height, 0.25, 16);
    demo.camera.position.setValues(0, 1.3, 3);
    demo.scene = three.Scene();

    controls = three.OrbitControls(demo.camera, demo.globalKey);

    demo.scene.add(three.AmbientLight(0x505050, 1));

    var spotLight = three.SpotLight(0xffffff);
    spotLight.angle = math.pi / 5;
    spotLight.penumbra = 0.2;
    spotLight.position.setValues(2, 3, 3);
    spotLight.castShadow = true;
    spotLight.shadow!.camera!.near = 3;
    spotLight.shadow!.camera!.far = 10;
    spotLight.shadow!.mapSize.width = 1024;
    spotLight.shadow!.mapSize.height = 1024;
    demo.scene.add(spotLight);

    var dirLight = three.DirectionalLight(0x55505a, 1);
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
    demo.scene.add(dirLight);

    // ***** Clipping planes: *****

    var localPlane = three.Plane(three.Vector3(0, -1, 0), 0.8);
    //var globalPlane = three.Plane(three.Vector3(-1, 0, 0), 0.1);

    // Geometry

    var material = three.MeshPhongMaterial.fromMap({
      "color": 0x80ee10,
      "shininess": 100,
      "side": three.DoubleSide,

      // ***** Clipping setup (material): *****
      "clippingPlanes": [localPlane],
      "clipShadows": true
    });

    var geometry = TorusKnotGeometry(0.4, 0.08, 95, 20);

    object = three.Mesh(geometry, material);
    object.castShadow = true;
    demo.scene.add(object);

    var ground = three.Mesh(three.PlaneGeometry(9, 9, 1, 1),
        three.MeshPhongMaterial.fromMap({"color": 0xa0adaf, "shininess": 150}));

    ground.rotation.x = -math.pi / 2; // rotates X/Y to X/Z
    ground.receiveShadow = true;
    demo.scene.add(ground);

    startTime = DateTime.now().millisecondsSinceEpoch;

    demo.addAnimationEvent((dt){
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
