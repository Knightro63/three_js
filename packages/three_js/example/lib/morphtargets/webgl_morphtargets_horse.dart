import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglMorphtargetsHorse extends StatefulWidget {
  final String fileName;
  const WebglMorphtargetsHorse({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglMorphtargetsHorse> {
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

  Future<void> setup() async {
    late three.Object3D mesh;

    three.AnimationMixer? mixer;

    const radius = 600;
    double theta = 0;
    int prevTime = DateTime.now().millisecondsSinceEpoch;

    demo.camera = three.PerspectiveCamera(50, demo.width / demo.height, 1, 10000);
    demo.camera.position.y = 300;

    demo.scene = three.Scene();
    demo.scene.background = three.Color.fromHex32(0xf0f0f0);

    //

    final light1 = three.DirectionalLight(0xefefff, 1.5);
    light1.position.setValues(1, 1, 1).normalize();
    demo.scene.add(light1);

    final light2 = three.DirectionalLight(0xffefef, 1.5);
    light2.position.setValues(-1, -1, -1).normalize();
    demo.scene.add(light2);

    final loader = three.GLTFLoader(null);
    final gltf = (await loader.fromAsset('assets/models/gltf/Horse.gltf'))!;

    mesh = gltf.scene.children[0];
    mesh.scale.setValues(1.5, 1.5, 1.5);
    demo.scene.add(mesh);

    mixer = three.AnimationMixer(mesh);

    mixer.clipAction(gltf.animations![0])?.setDuration(1).play();

    demo.addAnimationEvent((dt){
      theta += 0.1;

      demo.camera.position.x = radius * math.sin(three.MathUtils.degToRad(theta));
      demo.camera.position.z = radius * math.cos(three.MathUtils.degToRad(theta));

      demo.camera.lookAt(three.Vector3(0, 150, 0));

      if (mixer != null) {
        final time = DateTime.now().millisecondsSinceEpoch;
        mixer.update((time - prevTime) * 0.001);
        prevTime = time;
      }
    });
  }
}
