import 'dart:async';
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderObjMtl extends StatefulWidget {
  final String fileName;
  const WebglLoaderObjMtl({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderObjMtl> {
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

  late three.OrbitControls controls;
  late three.Object3D object;

  Future<void> setup() async {
    demo.camera = three.PerspectiveCamera(45, demo.width / demo.height, 1, 2000);
    demo.camera.position.z = 250;

    demo.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xcccccc, 0.4);
    demo.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.8);
    demo.camera.add(pointLight);
    demo.scene.add(demo.camera);

    controls = three.OrbitControls(demo.camera, demo.globalKey);

    // texture
    final manager = three.LoadingManager();

    final mtlLoader = three.MTLLoader(manager);
    mtlLoader.setPath('assets/models/obj/male02/');
    final materials = await mtlLoader.fromAsset('male02.mtl');
    await materials?.preload();

    final loader = three.OBJLoader();
    loader.setMaterials(materials);
    object = (await loader.fromAsset('assets/models/obj/male02/male02.obj'))!;


    object.scale.setValues(0.5, 0.5, 0.5);
    demo.scene.add(object);

    demo.addAnimationEvent((dt){
      controls.update();
    });
  }
}
