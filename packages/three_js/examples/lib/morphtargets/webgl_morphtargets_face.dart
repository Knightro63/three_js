import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglMorphtargetsFace extends StatefulWidget {
  final String fileName;
  const WebglMorphtargetsFace({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglMorphtargetsFace> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        toneMapping: three.ACESFilmicToneMapping
      )
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
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 1, 20 );
    threeJs.camera.position.setValues( - 1.8, 0.8, 3 );
    threeJs.scene = three.Scene();

    // final ktx2Loader = KTXLoader()
    //   .setTranscoderPath( 'jsm/libs/basis/' )
    //   .detectSupport( renderer );

    three.GLTFLoader()
      //.setKTX2Loader( ktx2Loader )
      //.setMeshoptDecoder( MeshoptDecoder )
      .fromAsset( 'assets/models/gltf/facecap.glb').then(( gltf ){
        final mesh = gltf!.scene.children[ 0 ];
        threeJs.scene.add( mesh );
        mixer = three.AnimationMixer( mesh );
        mixer?.clipAction(gltf.animations![ 0 ])!.play();
      });

    // final environment = RoomEnvironment();
    // final pmremGenerator = three.PMREMGenerator(threeJs.renderer!);

    threeJs.scene.background = three.Color.fromHex32( 0x666666 );
    //threeJs.scene.environment = pmremGenerator.fromScene( environment ).texture;

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.enableDamping = true;
    controls.minDistance = 2.5;
    controls.maxDistance = 5;
    controls.minAzimuthAngle = - math.pi / 2;
    controls.maxAzimuthAngle = math.pi / 2;
    controls.maxPolarAngle = math.pi / 1.8;
    controls.target.setValues( 0, 0.15, - 0.2 );

    threeJs.addAnimationEvent((dt){
      animate(dt);
    });
  }

  void animate(double delta) {
    mixer?.update(delta);
    controls.update();
  }
}
