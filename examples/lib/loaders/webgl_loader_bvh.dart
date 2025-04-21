import 'dart:async';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglLoaderBVH extends StatefulWidget {
  const WebglLoaderBVH({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglLoaderBVH> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
      });
    });
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        useOpenGL: useOpenGL
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          threeJs.build(),
          Statistics(data: data)
        ],
      ) 
    );
  }

  late final three.OrbitControls controls;
  late final three.AnimationMixer mixer;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width / threeJs.height, 1, 1000 );
    threeJs.camera.position.setValues( 0, 200, 300 );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xeeeeee );

    threeJs.scene.add( GridHelper( 400, 10 ) );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 300;
    controls.maxDistance = 700;

    final loader = three.BVHLoader();
    await loader.fromAsset( 'assets/models/bvh/pirouette.bvh').then(( result ) {
      final skeletonHelper = SkeletonHelper( result!.skeleton!.bones[ 0 ] );
      threeJs.scene.add( result.skeleton!.bones[ 0 ] );
      threeJs.scene.add( skeletonHelper );

      // play animation
      mixer = three.AnimationMixer( result.skeleton!.bones[ 0 ] );
      mixer.clipAction( result.clip )!.play();
    });

    threeJs.addAnimationEvent((dt){
      controls.update();
      mixer.update( dt );
    });
  }
}
