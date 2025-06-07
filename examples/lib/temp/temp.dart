import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart';
import 'package:three_js/three_js.dart' as three;

class Temp extends StatefulWidget {
  const Temp({super.key});
  @override
  createState() => _State();
}

class _State extends State<Temp> {
  late three.ThreeJS threeJs;
  three.Joystick? joystick;
  String status = "No model loaded.";

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: initThree,
      settings: three.Settings(
        enableShadowMap: false,
        useSourceTexture: false,
        useOpenGL: true,
        clearAlpha: 1.0,
        clearColor: 0x000000,
        autoClear: false
      )
    );
    super.initState();
  }

  @override
  void dispose() {
    threeJs.dispose();
    three.loading.clear();
    joystick?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final renderWidget = ;
    return Scaffold(
      appBar: AppBar(title: const Text('Three.js Windows Loader')),
      body: SingleChildScrollView(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 800,
            height: 600,
            child: threeJs.build(),
          ),
          ElevatedButton(
            onPressed: pickAndLoadGLB,
            child: const Text("Load GLTF / GLB File"),
          ),
        ]),
      ),
    );
  }

  Future initThree() async {
    threeJs.scene = three.Scene();
    threeJs.scene.castShadow = false;
    threeJs.scene.autoUpdate = true;

    threeJs.camera = three.PerspectiveCamera(75, threeJs.width / threeJs.height, 0.1, 1000);
    threeJs.camera.position.z = 2;
    threeJs.camera.position.y = -100;

    // AngleConsole.isVerbose = true;

    final light = three.DirectionalLight(0xffffff, 1);
    light.position.setValues(1, 1, 1);
    light.castShadow = false;
    threeJs.scene.add(light);
    
    // three.GLTFLoader loader = three.GLTFLoader(flipY: true);
    // final sky = await loader.fromPath();//'C:/Users/Atharva/StudioProjects/model_trials/assets/Welded Wall Mounting Box 1.glb');

    three.GLTFLoader loader = three.GLTFLoader(flipY: true).setPath('assets/models/gltf/flutter/');
    final sky = await loader.fromAsset( 'sky_sphere.glb' );
    threeJs.scene.add(sky!.scene);
    threeJs.scene.add(sky.scene);

    if(joystick != null) {
      threeJs.postProcessor = ([double? dt]) {
      threeJs.renderer!.setViewport(0, 0, threeJs.width, threeJs.height);
      threeJs.renderer!.clear();
      threeJs.renderer!.render(threeJs.scene, threeJs.camera);
      threeJs.renderer!.clearDepth();
      threeJs.renderer!.render(joystick!.scene, joystick!.camera);
      };
    }
  }

  Future pickAndLoadGLB() async {
    final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['glb', 'gltf'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      try {
        final loader = GLTFLoader();
        final gltf = await loader.fromFile(File(path));
        final scene = gltf?.scene;
        // This means the model loaded successfully
        setState(() {
          status = "Model loaded: ${scene?.children.length} children in scene.";
          threeJs.scene.add(scene);
        });
      } catch (e) {
        setState(() {
          status = "Failed to load: $e";
        });
      }
    }else{
      initThree();
    }
  }

}
