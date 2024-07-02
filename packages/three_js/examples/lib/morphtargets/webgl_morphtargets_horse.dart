import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglMorphtargetsHorse extends StatefulWidget {
  
  const WebglMorphtargetsHorse({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglMorphtargetsHorse> {
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

  Future<void> setup() async {
    late three.Object3D mesh;

    three.AnimationMixer? mixer;

    const radius = 600;
    double theta = 0;

    threeJs.camera = three.PerspectiveCamera(50, threeJs.width / threeJs.height, 1, 10000);
    threeJs.camera.position.y = 300;

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xf0f0f0);

    //

    final light1 = three.DirectionalLight(0xefefff, 1.5);
    light1.position.setValues(1, 1, 1).normalize();
    threeJs.scene.add(light1);

    final light2 = three.DirectionalLight(0xffefef, 1.5);
    light2.position.setValues(-1, -1, -1).normalize();
    threeJs.scene.add(light2);

    final loader = three.GLTFLoader();
    final gltf = (await loader.fromAsset('assets/models/gltf/Horse.gltf'))!;

    mesh = gltf.scene.children[0];
    mesh.scale.setValues(1.5, 1.5, 1.5);
    threeJs.scene.add(mesh);

    mixer = three.AnimationMixer(mesh);
    mixer.clipAction(gltf.animations![0])?.setDuration(1).play();

    threeJs.addAnimationEvent((dt){
      theta += 0.1;

      threeJs.camera.position.x = radius * math.sin(three.MathUtils.degToRad(theta));
      threeJs.camera.position.z = radius * math.cos(three.MathUtils.degToRad(theta));

      threeJs.camera.lookAt(three.Vector3(0, 150, 0));

      if (mixer != null) {
        mixer.update(dt);
      }
    });
  }
}
