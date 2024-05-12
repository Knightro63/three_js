import 'dart:async';
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderTextureBasis extends StatefulWidget {
  final String fileName;
  const WebglLoaderTextureBasis({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderTextureBasis> {
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
    
    demo.camera = three.PerspectiveCamera(60, demo.width / demo.height, 0.25, 20);
    demo.camera.position.setValues(-0.0, 0.0, 20.0);

    // scene

    demo.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xcccccc, 0.4);
    demo.scene.add(ambientLight);
    demo.camera.lookAt(demo.scene.position);

    final geometry = three.PlaneGeometry(10, 10);
    final material = three.MeshBasicMaterial.fromMap({"side": three.DoubleSide});

    final mesh = three.Mesh(geometry, material);

    demo.scene.add(mesh);

    final loader = three.TextureLoader(null);
    loader.flipY = true;
    final texture = await loader.fromAsset("assets/textures/758px-Canestra_di_frutta_(Caravaggio).jpg");

    material.map = texture;
    material.needsUpdate = true;
  }
}
