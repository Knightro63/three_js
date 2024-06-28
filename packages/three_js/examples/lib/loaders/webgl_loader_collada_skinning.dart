import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglLoaderColladaSkinning extends StatefulWidget {
  final String fileName;
  const WebglLoaderColladaSkinning({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderColladaSkinning> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings()
    );
    super.initState();
  }
  @override
  void dispose() {
    controls.dispose();
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

  late three.OrbitControls controls;
  three.AnimationMixer? mixer;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 25, threeJs.width / threeJs.height, 1, 1000 );
    threeJs.camera.position.setValues( 15, 10, - 15 );

    threeJs.scene = three.Scene();

    // collada

    final loader = three.ColladaLoader();
    loader.setPath('assets/models/collada/stormtrooper/');
    await loader.fromAsset( 'stormtrooper.dae').then(( collada ) {
      final avatar = collada!.scene!;
      final animations = collada.animations!;

      mixer = three.AnimationMixer( avatar );
      mixer?.clipAction( animations[0] )?.play();

      threeJs.scene.add( avatar );

      final skeleton = SkeletonHelper(avatar);
      skeleton.visible = true;
      threeJs.scene.add(skeleton);
    } );

    //

    final gridHelper = GridHelper( 10, 20, 0xc1c1c1, 0x8d8d8d );
    threeJs.scene.add( gridHelper );

    //

    final ambientLight = three.AmbientLight( 0xffffff, 0.6 );
    threeJs.scene.add( ambientLight );

    final directionalLight = three.DirectionalLight( 0xffffff, 3 );
    directionalLight.position.setValues( 1.5, 1, - 1.5 );
    threeJs.scene.add( directionalLight );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.screenSpacePanning = true;
    controls.minDistance = 5;
    controls.maxDistance = 40;
    controls.target.setValues( 0, 2, 0 );
    controls.update();

    threeJs.addAnimationEvent((dt){
      mixer?.update( dt );
      controls.update();
    });
  }
}
