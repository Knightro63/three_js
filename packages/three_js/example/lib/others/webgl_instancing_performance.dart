import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglInstancingPerformance extends StatefulWidget {
  final String fileName;
  const WebglInstancingPerformance({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglInstancingPerformance> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        renderOptions: {
          "minFilter": three.LinearFilter,
          "magFilter": three.LinearFilter,
          "format": three.RGBAFormat,
          "samples": 4
        }
      )
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: threeJs.build()
    );
  }

  late three.Material material;
  int count = 1000;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(70, threeJs.width / threeJs.height, 1, 100);
    threeJs.camera.position.z = 30;

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xffffff);

    material = three.MeshNormalMaterial();

    final geometry = three.BoxGeometry(5, 5, 5);
    makeNaive(geometry);

    threeJs.addAnimationEvent((dt){
      threeJs.scene.rotation.x += 0.002;
      threeJs.scene.rotation.y += 0.001;
    });
  }

  void makeInstanced(three.BufferGeometry geometry) {
    final matrix = three.Matrix4();
    final mesh = three.InstancedMesh(geometry, material, count);

    for (int i = 0; i < count; i++) {
      randomizeMatrix(matrix);
      mesh.setMatrixAt(i, matrix);
    }

    threeJs.scene.add(mesh);  
  }

  void makeNaive(three.BufferGeometry geometry) {
    final matrix = three.Matrix4();

    for (int i = 0; i < count; i++) {
      final mesh = three.Mesh(geometry, material);
      randomizeMatrix(matrix);
      mesh.applyMatrix4(matrix);
      threeJs.scene.add(mesh);
    }
  }

  final position = three.Vector3();
  final rotation = three.Euler(0, 0, 0);
  final quaternion = three.Quaternion();
  final scale = three.Vector3();

  void randomizeMatrix(matrix) {
    position.x = math.Random().nextDouble() * 40 - 20;
    position.y = math.Random().nextDouble() * 40 - 20;
    position.z = math.Random().nextDouble() * 40 - 20;

    rotation.x = math.Random().nextDouble() * 2 * math.pi;
    rotation.y = math.Random().nextDouble() * 2 * math.pi;
    rotation.z = math.Random().nextDouble() * 2 * math.pi;

    quaternion.setFromEuler(rotation, false);

    scale.x = scale.y = scale.z = math.Random().nextDouble() * 1;

    matrix.compose(position, quaternion, scale);
  }
}
