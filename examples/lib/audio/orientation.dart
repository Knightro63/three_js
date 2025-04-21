import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_audio/positional_audio.dart';
import 'package:three_js_audio/three_js_audio.dart';

class AudioOrientation extends StatefulWidget {
  
  const AudioOrientation({super.key});

  @override
  createState() => _State();
}

class _State extends State<AudioOrientation> {
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
    controls.dispose();
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

  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 3, 2, 3 );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xa0a0a0 );
    threeJs.scene.fog = three.Fog( 0xa0a0a0, 2, 20 );

    final hemiLight = three.HemisphereLight( 0xffffff, 0x8d8d8d, 3 );
    hemiLight.position.setValues( 0, 20, 0 );
    threeJs.scene.add( hemiLight );

    final dirLight = three.DirectionalLight( 0xffffff, 3 );
    dirLight.position.setValues( 5, 5, 0 );
    dirLight.castShadow = true;
    dirLight.shadow?.camera?.top = 1;
    dirLight.shadow?.camera?.bottom = - 1;
    dirLight.shadow?.camera?.left = - 1;
    dirLight.shadow?.camera?.right = 1;
    dirLight.shadow?.camera?.near = 0.1;
    dirLight.shadow?.camera?.far = 20;
    threeJs.scene.add( dirLight );

    final mesh = three.Mesh( three.PlaneGeometry( 50, 50 ), three.MeshPhongMaterial.fromMap( { 'color': 0xcbcbcb, 'depthWrite': false } ) );
    mesh.rotation.x = - math.pi / 2;
    mesh.receiveShadow = true;
    threeJs.scene.add( mesh );

    final positionalAudio = PositionalAudio(
      path: 'sounds/376737_Skullbeatz___Bad_Cat_Maste.mp3',
      listner: threeJs.camera,
      refDistance: 0.75,
      coneInnerAngle: 90,
      coneOuterAngle: 180,
      coneOuterGain: 0.1,
      maxDistance: 2
    );
    positionalAudio.play();

    final helper = PositionalAudioHelper( positionalAudio, 0.1 );
    positionalAudio.add( helper );
    
    //

    final gltfLoader = three.GLTFLoader();
    await gltfLoader.fromAsset( 'assets/models/gltf/BoomBox.glb').then(( gltf ) {

      final boomBox = gltf!.scene;
      boomBox.position.setValues( 0, 0.2, 0 );
      boomBox.scale.setValues( 20, 20, 20 );

      boomBox.traverse( ( object ) {
        if ( object is three.Mesh ) {
          object.geometry?.rotateY( - math.pi );
          object.castShadow = true;
        }
      } );

      boomBox.add( positionalAudio );
      threeJs.scene.add( boomBox );
    } );

    // sound is damped behind this wall

    final wallGeometry = three.BoxGeometry( 2, 1, 0.1 );
    final wallMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000, 'transparent': true, 'opacity': 0.5 } );

    final wall = three.Mesh( wallGeometry, wallMaterial );
    wall.position.setValues( 0, 0.5, - 0.5 );
    threeJs.scene.add( wall );

    //

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey);
    controls.target.setValues( 0, 0.1, 0 );
    controls.update();
    controls.minDistance = 0.5;
    controls.maxDistance = 10;
    controls.maxPolarAngle = 0.5 * math.pi;

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
