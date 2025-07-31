import 'dart:async';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderObj extends StatefulWidget {
  
  const WebglLoaderObj({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderObj> {
  late three.OrbitControls controls;
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
      settings: three.Settings(
        enableShadowMap: false,
        
      ),
      
      onSetupComplete: (){setState(() {});},
      setup: setup
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

  Future<void> setup() async {
    late three.Object3D object;
    late three.Texture texture;
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 0.1, 20);
    threeJs.camera.position.z = 2.5;

    threeJs.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xcccccc, 0.4);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.8);
    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    final textureLoader = three.TextureLoader();
    textureLoader.flipY = false;
    texture = (await textureLoader.fromAsset('assets/textures/uv_grid_opengl.jpg'))!;

    texture.magFilter = three.LinearFilter;
    texture.minFilter = three.LinearMipmapLinearFilter;
    texture.generateMipmaps = true;
    texture.needsUpdate = true;
    texture.flipY = true; // this flipY is only for web

    final loader = three.OBJLoader();
    object = (await loader.fromAsset('assets/models/obj/male02/male02.obj'))!;

    object.traverse((child) {
      if (child is three.Mesh) {
        child.material?.map = texture;
      }
    });

    object.position.y = - 0.95;
    object.scale.setScalar( 0.01 );
    threeJs.scene.add(object);

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
