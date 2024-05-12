import 'dart:async';
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglAnimationSkinningBlending extends StatefulWidget {
  final String fileName;
  const WebglAnimationSkinningBlending({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglAnimationSkinningBlending> {
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
  late three.Object3D model;

  Future<void> setup() async {
    demo.camera = three.PerspectiveCamera(45, demo.width / demo.height, 0.1, 1000);
    demo.camera.position.setValues(-1, -4, -2);
    demo.scene = three.Scene();

    controls = three.OrbitControls(demo.camera, demo.globalKey);
    demo.camera.lookAt( demo.scene.position );

    demo.scene.background = three.Color.fromHex32(0xffffff);
    demo.scene.fog = three.Fog(three.Color.fromHex32(0xa0a0a0), 10, 50);

    final hemiLight = three.HemisphereLight(0xffffff, 0x444444);
    hemiLight.position.setValues(0, -4, -2);
    demo.scene.add(hemiLight);

    final dirLight = three.DirectionalLight(0xffffff);
    dirLight.position.setValues(-0, -4, -2);
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.top = 2;
    dirLight.shadow!.camera!.bottom = -2;
    dirLight.shadow!.camera!.left = -2;
    dirLight.shadow!.camera!.right = 2;
    dirLight.shadow!.camera!.near = 0.1;
    dirLight.shadow!.camera!.far = 40;
    demo.scene.add(dirLight);

    // scene.add( new three.CameraHelper( dirLight.shadow.camera ) );

    // ground

    final loader = three.GLTFLoader();
    final gltf = await loader.fromAsset('assets/models/gltf/Soldier.gltf');

    model = gltf!.scene;

    three.console.info(" load model success " );
    three.console.info(model);

    demo.scene.add(model);

    model.traverse((object) {
      if (object is three.Mesh) object.castShadow = true;
    });


    final skeleton = SkeletonHelper(model);
    skeleton.visible = true;
    demo.scene.add(skeleton);

    final animations = gltf.animations!;

    mixer = three.AnimationMixer(model);

    //final idleAction = mixer.clipAction(animations[0]);
    final walkAction = mixer.clipAction(animations[3]);
    //final runAction = mixer.clipAction(animations[1]);

    walkAction!.play();

    demo.addAnimationEvent((dt){
      mixer.update(dt);
      controls.update();
    });

  }
}
