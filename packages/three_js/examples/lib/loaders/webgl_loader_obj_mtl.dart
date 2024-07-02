import 'dart:async';

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderObjMtl extends StatefulWidget {
  
  const WebglLoaderObjMtl({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderObjMtl> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup
    );
    super.initState();
  }
  @override
  void dispose() {
    controls.dispose();
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: threeJs.build()
    );
  }

  late three.OrbitControls controls;
  late three.Object3D object;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 0.1, 20);
    threeJs.camera.position.z = 2.5;

    threeJs.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xcccccc, 0.4);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.8);
    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    // texture
    final manager = three.LoadingManager();

    final mtlLoader = three.MTLLoader(manager);
    mtlLoader.setPath('assets/models/obj/male02/');
    final materials = await mtlLoader.fromAsset('male02.mtl');
    await materials?.preload();

    final loader = three.OBJLoader();
    loader.setMaterials(materials);
    object = (await loader.fromAsset('assets/models/obj/male02/male02.obj'))!;

    object.position.y = - 0.95;
    object.scale.setScalar( 0.01 );
    threeJs.scene.add(object);

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
