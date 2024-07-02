import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglShadowmapViewer extends StatefulWidget {
  
  const WebglShadowmapViewer({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglShadowmapViewer> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        useSourceTexture: true,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: threeJs.build()
    );
  }

  void setup() {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 1000);
    threeJs.camera.position.setValues(0, 15, 70);

    threeJs.scene = three.Scene();
    threeJs.camera.lookAt(threeJs.scene.position);

    // Lights

    threeJs.scene.add(three.AmbientLight(0x404040));

    final spotLight = three.SpotLight(0xffffff);
    spotLight.name = 'Spot Light';
    spotLight.angle = math.pi / 5;
    spotLight.penumbra = 0.3;
    spotLight.position.setValues(10, 10, 5);
    spotLight.castShadow = true;
    spotLight.shadow!.camera!.near = 8;
    spotLight.shadow!.camera!.far = 30;
    spotLight.shadow!.mapSize.width = 1024;
    spotLight.shadow!.mapSize.height = 1024;
    threeJs.scene.add(spotLight);

    threeJs.scene.add(CameraHelper(spotLight.shadow!.camera!));

    final dirLight = three.DirectionalLight(0xffffff, 1);
    dirLight.name = 'Dir. Light';
    dirLight.position.setValues(0, 10, 0);
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.near = 1;
    dirLight.shadow!.camera!.far = 10;
    dirLight.shadow!.camera!.right = 15;
    dirLight.shadow!.camera!.left = -15;
    dirLight.shadow!.camera!.top = 15;
    dirLight.shadow!.camera!.bottom = -15;
    dirLight.shadow!.mapSize.width = 1024;
    dirLight.shadow!.mapSize.height = 1024;
    threeJs.scene.add(dirLight);

    threeJs.scene.add(CameraHelper(dirLight.shadow!.camera!));

    // Geometry
    final geometry = TorusKnotGeometry(25, 8, 75, 20);
    three.MeshPhongMaterial material = three.MeshPhongMaterial.fromMap({
      "color": 0xff0000,
      "shininess": 150,
      "specular": three.Color.fromHex32(0x222222)
    });

    final torusKnot = three.Mesh(geometry, material);
    torusKnot.scale.scale(1 / 18);
    torusKnot.position.y = 3;
    torusKnot.castShadow = true;
    torusKnot.receiveShadow = true;
    threeJs.scene.add(torusKnot);

    final geometry2 = three.BoxGeometry(3, 3, 3);
    final cube = three.Mesh(geometry2, material);
    cube.position.setValues(8, 3, 8);
    cube.castShadow = true;
    cube.receiveShadow = true;
    threeJs.scene.add(cube);

    final geometry3 = three.BoxGeometry(10, 0.15, 10);
    material = three.MeshPhongMaterial.fromMap({"color": 0xa0adaf, "shininess": 150, "specular": 0x111111});

    final ground = three.Mesh(geometry3, material);
    ground.scale.scale(3);
    ground.castShadow = false;
    ground.receiveShadow = true;
    threeJs.scene.add(ground);

    threeJs.addAnimationEvent((dt){
      torusKnot.rotation.x += 0.025;
      torusKnot.rotation.y += 0.2;
      torusKnot.rotation.z += 0.1;

      cube.rotation.x += 0.025;
      cube.rotation.y += 0.2;
      cube.rotation.z += 0.1;
    });
  }
}
