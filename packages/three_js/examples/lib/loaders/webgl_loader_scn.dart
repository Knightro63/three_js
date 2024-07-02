import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderSCN extends StatefulWidget {
  
  const WebglLoaderSCN({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderSCN> {
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
  late three.AnimationMixer mixer;
  
  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2200);
    threeJs.camera.position.setValues(3, 6, 10);
    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);
    threeJs.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xffffff, 0.9);
    threeJs.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.8);

    pointLight.position.setValues(0, 0, 0);

    threeJs.camera.add(pointLight);
    threeJs.scene.add(threeJs.camera);

    threeJs.camera.lookAt(threeJs.scene.position);

    three.SCNLoader loader = three.SCNLoader().setPath('assets/models/scn/');
    dynamic result = await loader.fromAsset( 'scene.scn' );

    final object = result!.scene;
    threeJs.scene.add(object);
    mixer = three.AnimationMixer(object);
    mixer.clipAction(result.animations![4], null, null)!.play();
    
    threeJs.addAnimationEvent((dt){
      mixer.update(dt);
      controls.update();
    });
  }
}
