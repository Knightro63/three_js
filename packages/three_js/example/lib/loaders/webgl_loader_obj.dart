import 'dart:async';
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderObj extends StatefulWidget {
  final String fileName;
  const WebglLoaderObj({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderObj> {
  late Demo demo;

  @override
  void initState() {
    demo = Demo(
      settings: DemoSettings(
        enableShadowMap: false,
        animate: false
      ),
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
    late three.Object3D object;
    late three.Texture texture;
    demo.camera = three.PerspectiveCamera(45, demo.width / demo.height, 1, 2000);
    demo.camera.position.z = 250;

    demo.scene = three.Scene();

    final ambientLight = three.AmbientLight(0xcccccc, 0.4);
    demo.scene.add(ambientLight);

    final pointLight = three.PointLight(0xffffff, 0.8);
    demo.camera.add(pointLight);
    demo.scene.add(demo.camera);


    final textureLoader = three.TextureLoader();
    textureLoader.flipY = false;
    texture = (await textureLoader.fromAsset('assets/textures/uv_grid_opengl.jpg'))!;

    texture.magFilter = three.LinearFilter;
    texture.minFilter = three.LinearMipmapLinearFilter;
    texture.generateMipmaps = true;
    texture.needsUpdate = true;
    texture.flipY = true; // this flipY is only for web

    final loader = three.OBJLoader();
    object = (await loader.fromAsset('assets/models/obj/male02/male02.obj'))!;

    object.traverse((child) {
      if (child is three.Mesh) {
        child.material?.map = texture;
      }
    });

    object.scale.setValues(0.5, 0.5, 0.5);
    demo.scene.add(object);
  }
}
