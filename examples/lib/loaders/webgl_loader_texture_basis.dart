import 'dart:async';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderTextureBasis extends StatefulWidget {
  
  const WebglLoaderTextureBasis({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderTextureBasis> {
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
        useOpenGL: true
      )
    );
    super.initState();
  }
  @override
  void dispose() {
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

  Future<void> setup() async {
    
    threeJs.camera = three.PerspectiveCamera(60, threeJs.width / threeJs.height, 0.25, 20);
    threeJs.camera.position.setValues(-0.0, 0.0, 20.0);

    // scene

    threeJs.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xcccccc, 0.4);
    threeJs.scene.add(ambientLight);
    threeJs.camera.lookAt(threeJs.scene.position);

    final geometry = three.PlaneGeometry(10, 10);
    final material = three.MeshBasicMaterial.fromMap({"side": three.DoubleSide});

    final mesh = three.Mesh(geometry, material);

    threeJs.scene.add(mesh);

    final loader = three.TextureLoader();
    loader.flipY = true;
    final texture = await loader.fromAsset("assets/textures/758px-Canestra_di_frutta_(Caravaggio).jpg");

    material.map = texture;
    material.needsUpdate = true;
  }
}
