import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderCollada extends StatefulWidget {
  
  const WebglLoaderCollada({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderCollada> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
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

  three.Object3D? elf;
  
  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 2000 );
    threeJs.camera.position.setValues( 8, 10, 8 );
    threeJs.camera.lookAt(three.Vector3(0, 3, 0 ));

    threeJs.scene = three.Scene();

    final loader = three.ColladaLoader();
    loader.setPath('assets/models/collada/elf/');
    await loader.fromAsset( 'elf.dae').then(( collada ) {
      elf = collada?.scene;
      threeJs.scene.add( elf );
    });

    final ambientLight = three.AmbientLight( 0xffffff );
    threeJs.scene.add( ambientLight );

    final directionalLight = three.DirectionalLight( 0xffffff, 0.5 );
    directionalLight.position.setValues( 1, 1, 0 ).normalize();
    threeJs.scene.add( directionalLight );
    
    threeJs.addAnimationEvent((dt){
      if ( elf != null ) {
        elf!.rotation.z += dt * 0.5;
      }
    });
  }
}
