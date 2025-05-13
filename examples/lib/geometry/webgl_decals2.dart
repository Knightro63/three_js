import 'dart:async';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglDecals2 extends StatefulWidget {
  
  const WebglDecals2({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglDecals2> {
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
    three.loading.clear();
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

  int startTime = 0;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 0.1, 10);
    threeJs.camera.position.z = 3;

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xFFFFFF);
    threeJs.scene.add(threeJs.camera);

    final ambientLight = three.AmbientLight(0xffffff);
    threeJs.scene.add(ambientLight);

    // Configure a simple box.
    final boxGeometry =  three.BoxGeometry(0.6, 0.6, 0.6);
    final boxMaterial =  three.MeshStandardMaterial({
      three.MaterialProperty.color: 0x00FF00,
      three.MaterialProperty.side: three.DoubleSide,
    });
    final boxModel =  three.Mesh(boxGeometry, boxMaterial);
    threeJs.scene.add(boxModel);

    // Configure a decal
    final textureLoader = three.TextureLoader();
    final imageTexture = await textureLoader.fromAsset('assets/textures/sprite.png');
    imageTexture?.colorSpace = three.SRGBColorSpace;
    imageTexture?.flipY = true;
    final imageMaterial = three.MeshStandardMaterial({
      three.MaterialProperty.map: imageTexture,
      three.MaterialProperty.side: three.DoubleSide,
      three.MaterialProperty.transparent: true,
      three.MaterialProperty.depthTest: true,
      three.MaterialProperty.depthWrite: false,
      three.MaterialProperty.polygonOffset: true,
      three.MaterialProperty.polygonOffsetFactor: -1,
    });

    final boxPosition = three.Vector3(0, 0, 0);
    final boxOrientation = three.Euler(0, 0, 0);
    final boxSize = three.Vector3(1, 1, 1);

    final decalGeometry = three.DecalGeometry(
      boxModel,
      boxPosition,
      boxOrientation,
      boxSize,
    );
    final boxImageMesh = three.Mesh(decalGeometry, imageMaterial);
    boxModel.attach(boxImageMesh);

    three.OrbitControls(
      threeJs.camera,
      threeJs.globalKey,
    )
      ..maxDistance = 4
      ..minDistance = 0.5;
  }
}
