import 'dart:async';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglAnimationKeyframes extends StatefulWidget {
  const WebglAnimationKeyframes({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglAnimationKeyframes> {
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
        useOpenGL: useOpenGL
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    three.loading.clear();
    timer.cancel();
    threeJs.dispose();
    controls.dispose();
    mixer.dispose();
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

  late three.AnimationMixer mixer;
  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    final pmremGenerator = three.PMREMGenerator(threeJs.renderer!);
    threeJs.scene.environment = pmremGenerator.fromScene(RoomEnvironment(), sigma: 0.04).texture;
    threeJs.scene.background = three.Color.fromHex32(0xbfe3dd);

    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 100);
    threeJs.camera.position.setValues(8, 4, 12);
    
    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);
    controls.target.setValues( 0, 0.5, 0 );
    controls.update();
    controls.enablePan = false;
    controls.enableDamping = true;

    final result = await three.GLTFLoader().setPath('assets/models/gltf/test/').fromAsset('tokyo.gltf');
    final model = result!.scene;

    model.position.setValues(1, 1, 0);
    model.scale.setValues(0.01, 0.01, 0.01);
    threeJs.scene.add(model);

    mixer = three.AnimationMixer(model);
    mixer.clipAction(result.animations![0])!.play();

    threeJs.addAnimationEvent((dt){
      mixer.update(dt);
      controls.update();
    });
  }
}
