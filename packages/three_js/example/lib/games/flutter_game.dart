import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class FlutterGame extends StatefulWidget {
  final String fileName;
  const FlutterGame({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<FlutterGame> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup,
      // postProcessor: ([dt]){
      //   threeJs.renderer!.clear(true, true, true);
      // },
      settings: three.Settings(
        clearAlpha: 0,
        clearColor: 0xffffff
      ),
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    controls.clearListeners();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: threeJs.build()
    );
  }

  late three.OrbitControls controls;
  late three.AnimationMixer mixer;
  
  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2200);
    threeJs.camera.position.setValues(3, 6, 10);
    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);
    threeJs.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xffffff, 0.3);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.1);

    pointLight.position.setValues(0, 0, 0);

    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    threeJs.camera.lookAt(threeJs.scene.position);

    three.GLTFLoader loader = three.GLTFLoader().setPath('assets/models/gltf/flutter/');

    //final result = await loader.fromAsset( 'coffeemat.glb' );
    var sky = await loader.fromAsset( 'sky_sphere.glb' );
    threeJs.scene.add(sky!.scene);
    var ground = await loader.fromAsset('ground.glb');
    threeJs.scene.add(ground!.scene);
    var coin = await loader.fromAsset('coin.glb');
    threeJs.scene.add(coin!.scene);
    var logo = await loader.fromAsset('flutter_logo.glb');
    threeJs.scene.add(logo!.scene);
    var dash = await loader.fromAsset('dash.glb');

    final object = dash!.scene;
    threeJs.scene.add(object);
    mixer = three.AnimationMixer(object);
    mixer.clipAction(dash.animations![4], null, null)!.play();

    threeJs.addAnimationEvent((dt){
      mixer.update(dt);
      controls.update();
    });
  }
}
