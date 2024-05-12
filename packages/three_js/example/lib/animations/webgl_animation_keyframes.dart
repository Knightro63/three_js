import 'dart:async';
import 'package:example/src/demo.dart';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return demo.threeDart();
  }

  late three.AnimationMixer mixer;
  late three.OrbitControls controls;

  Future<void> setup() async {
    demo.camera = three.PerspectiveCamera(45, demo.width / demo.height, 1, 100);
    demo.camera.position.setValues(8, 4, 12);

    // scene
    demo.scene = three.Scene();

    final pmremGenerator = three.PMREMGenerator(demo.renderer);
    demo.scene.background = three.Color.fromHex32(0xbfe3dd);
    demo.scene.environment = pmremGenerator.fromScene(RoomEnvironment(), 0.04).texture;

    final ambientLight = three.AmbientLight( 0xcccccc, 0.4 );
    demo.scene.add( ambientLight );

    final pointLight = three.PointLight( 0xffffff, 0.8 );
    demo.camera.add( pointLight );
    demo.scene.add(demo.camera);
    demo.camera.lookAt(demo.scene.position);

    controls= three.OrbitControls(demo.camera, demo.globalKey);

    final loader = three.GLTFLoader().setPath('assets/models/gltf/test/');

    final result = await loader.fromAsset('tokyo.gltf');
    // final result = await loader.loadAsync( 'animate7.gltf', null);
    // final result = await loader.loadAsync( 'untitled22.gltf', null);

    three.console.info("load gltf success result: $result ");
    final model = result!.scene;
    three.console.info(" load gltf success model: $model  ");

    model.position.setValues(1, 1, 0);
    model.scale.setValues(0.01, 0.01, 0.01);
    demo.scene.add(model);

    mixer = three.AnimationMixer(model);
    mixer.clipAction(result.animations![0], null, null)!.play();

    demo.addAnimationEvent((dt){
      mixer.update(dt);
      controls.update();
    });
  }
}
