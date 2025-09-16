import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_advanced_loaders/three_js_advanced_loaders.dart';
import 'package:three_js_animations/three_js_animations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebglLoaderGlb(),
    );
  }
}

class WebglLoaderGlb extends StatefulWidget {
  const WebglLoaderGlb({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderGlb> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,      
      settings: three.Settings(
        clearAlpha: 0,
        clearColor: 0xffffff,
      ),
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
    return threeJs.build();
  }

  late AnimationMixer mixer;
  
  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2200);
    threeJs.camera.position.setValues(3, 6, 10);
    threeJs.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xffffff, 0.9);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.8);

    pointLight.position.setValues(0, 0, 0);

    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    threeJs.camera.lookAt(threeJs.scene.position);

    GLTFLoader loader = GLTFLoader();

    final result = await loader.fromAsset( 'assets/dash.glb' );

    final object = result!.scene;
    threeJs.scene.add(object);
    mixer = AnimationMixer(object);
    mixer.clipAction(result.animations![4], null, null)!.play();
    
    threeJs.addAnimationEvent((dt){
      mixer.update(dt);
    });
  }
}

