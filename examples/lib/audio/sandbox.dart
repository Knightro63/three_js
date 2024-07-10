import 'dart:async';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_audio/positional_audio.dart';
import 'package:three_js_audio/three_js_audio.dart';
import 'package:three_js_helpers/three_js_helpers.dart';

class AudioSandbox extends StatefulWidget {
  
  const AudioSandbox({super.key});

  @override
  createState() => _State();
}

class _State extends State<AudioSandbox> {
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

  late three.FirstPersonControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width / threeJs.height, 1, 10000 );
    threeJs.camera.position.setValues( 0, 25, 0 );

    threeJs.scene = three.Scene();
    threeJs.scene.fog = three.FogExp2( 0x000000, 0.0025 );

    final light = three.DirectionalLight( 0xffffff, 3 );
    light.position.setValues( 0, 0.5, 1 ).normalize();
    threeJs.scene.add( light );

    final sphere = three.SphereGeometry( 20, 32, 16 );

    final material1 = three.MeshPhongMaterial.fromMap( { 'color': 0xffaa00, 'flatShading': true, 'shininess': 0 } );
    final material2 = three.MeshPhongMaterial.fromMap( { 'color': 0xff2200, 'flatShading': true, 'shininess': 0 } );
    final material3 = three.MeshPhongMaterial.fromMap( { 'color': 0x6622aa, 'flatShading': true, 'shininess': 0 } );

    // sound spheres

    final mesh1 = three.Mesh( sphere, material1 );
    mesh1.position.setValues( - 250, 30, 0 );
    threeJs.scene.add( mesh1 );

    final AudioLoader loader = AudioLoader();

    final sound1 = PositionalAudio( threeJs.camera );
    final songElement = await loader.fromAsset('assets/sounds/358232_j_s_song.mp3');//document.getElementById( 'song' );
    sound1.setBuffer( songElement! );
    sound1.refDistance = 20;
    sound1.play();
    mesh1.add( sound1 );

    //

    final mesh2 = three.Mesh( sphere, material2 );
    mesh2.position.setValues( 250, 30, 0 );
    threeJs.scene.add( mesh2 );

    final sound2 = PositionalAudio( threeJs.camera  );
    final skullbeatzElement = await loader.fromAsset('assets/sounds/376737_Skullbeatz___Bad_Cat_Maste.mp3');//document.getElementById( 'skullbeatz' );
    sound2.setBuffer( skullbeatzElement! );
    sound2.refDistance = 20;
    sound2.play();
    mesh2.add( sound2 );

    //

    final mesh3 = three.Mesh( sphere, material3 );
    mesh3.position.setValues( 0, 30, - 250 );
    threeJs.scene.add( mesh3 );

    final sound3 = PositionalAudio( threeJs.camera  );
    final oscillator = await loader.fromAsset('assets/sounds/Project_Utopia.mp3');//listener.context.createOscillator();
    sound3.setBuffer( oscillator! );
    sound3.refDistance = 20;
    sound3.setVolume( 0.5 );
    mesh3.add( sound3 );

    // global ambient audio

    // final sound4 = Audio();
    // const utopiaElement = document.getElementById( 'utopia' );
    // sound4.setMediaElementSource( utopiaElement );
    // sound4.setVolume( 0.5 );
    // utopiaElement.play();

    // ground

    final helper = GridHelper( 1000, 10, 0x444444, 0x444444 );
    helper.position.y = 0.1;
    threeJs.scene.add( helper );

    //

    controls = three.FirstPersonControls( camera: threeJs.camera, listenableKey: threeJs.globalKey );

    controls.movementSpeed = 70;
    controls.lookSpeed = 0.005;
    controls.lookType = three.LookType.position;

    threeJs.addAnimationEvent((dt){
      controls.update(dt);
      sound1.update();
    });
  }
}
