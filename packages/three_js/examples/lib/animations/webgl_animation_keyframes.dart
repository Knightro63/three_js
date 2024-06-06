import 'dart:async';

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglAnimationKeyframes extends StatefulWidget {
  final String fileName;
  const WebglAnimationKeyframes({super.key, required this.fileName});

  @override
  createState() => webgl_animation_keyframesState();
}

class webgl_animation_keyframesState extends State<WebglAnimationKeyframes> {
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
    three.loading.clear();
    threeJs.dispose();
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

  late three.AnimationMixer mixer;
  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 100);
    threeJs.camera.position.setValues(8, 4, 12);

    // scene
    threeJs.scene = three.Scene();

    final pmremGenerator = three.PMREMGenerator(threeJs.renderer!);
    threeJs.scene.background = three.Color.fromHex32(0xbfe3dd);
    threeJs.scene.environment = pmremGenerator.fromScene(RoomEnvironment(), 0.04).texture;

    final ambientLight = three.AmbientLight( 0xcccccc, 0.4 );
    threeJs.scene.add( ambientLight );

    final pointLight = three.PointLight( 0xffffff, 0.8 );
    threeJs.camera.add( pointLight );
    threeJs.scene.add(threeJs.camera);
    threeJs.camera.lookAt(threeJs.scene.position);

    controls= three.OrbitControls(threeJs.camera, threeJs.globalKey);

    final loader = three.GLTFLoader().setPath('assets/models/gltf/test/');

    final result = await loader.fromAsset('tokyo.gltf');
    // final result = await loader.loadAsync( 'animate7.gltf', null);
    // final result = await loader.loadAsync( 'untitled22.gltf', null);

    three.console.info("load gltf success result: $result ");
    final model = result!.scene;
    three.console.info(" load gltf success model: $model  ");

    model.position.setValues(1, 1, 0);
    model.scale.setValues(0.01, 0.01, 0.01);
    threeJs.scene.add(model);

    mixer = three.AnimationMixer(model);
    mixer.clipAction(result.animations![0], null, null)!.play();

    threeJs.addAnimationEvent((dt){
      mixer.update(dt);
      controls.update();
    });
  }
}
