import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglMorphtargetsSphere extends StatefulWidget {
  final String fileName;
  const WebglMorphtargetsSphere({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglMorphtargetsSphere> {
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
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: threeJs.build()
    );
  }

  late three.Object3D mesh;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 0.2, 100);
    threeJs.camera.position.setValues(0, 5, 5);

    threeJs.scene = three.Scene();

    threeJs.camera.lookAt(threeJs.scene.position);

    final light1 = three.PointLight(0xff2200, 0.7);
    light1.position.setValues(100, 100, 100);
    threeJs.scene.add(light1);

    final light2 = three.PointLight(0x22ff00, 0.7);
    light2.position.setValues(-100, -100, -100);
    threeJs.scene.add(light2);

    threeJs.scene.add(three.AmbientLight(0x111111, 1));

    final loader = three.GLTFLoader();

    final gltf = (await loader.fromAsset('assets/models/gltf/AnimatedMorphSphere/glTF/AnimatedMorphSphere.gltf'))!;
    mesh = gltf.scene.getObjectByName('AnimatedMorphSphere')!;

    mesh.rotation.z = math.pi / 2;
    threeJs.scene.add(mesh);

    three.console.verbose(" load sucess mesh: $mesh  ");
    three.console.verbose(mesh.geometry!.morphAttributes);

    final texture = await three.TextureLoader().fromAsset('assets/textures/sprites/disc.png');

    final pointsMaterial = three.PointsMaterial.fromMap({
      "size": 10,
      "sizeAttenuation": false,
      "map": texture,
      "alphaTest": 0.5
    });

    final points = three.Points(mesh.geometry!, pointsMaterial);
    points.morphTargetInfluences = mesh.morphTargetInfluences;
    points.morphTargetDictionary = mesh.morphTargetDictionary;
    mesh.add(points);

    int sign = 1;
    const speed = 0.5;

    threeJs.addAnimationEvent((dt){
      final step = dt * speed;
      mesh.rotation.y += step;

      mesh.morphTargetInfluences[1] = mesh.morphTargetInfluences[1] + step * sign;

      if (mesh.morphTargetInfluences[1] <= 0 ||
          mesh.morphTargetInfluences[1] >= 1) {
        sign *= -1;
      }
    });
  }
}
