import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_audio/three_js_audio.dart';

class AudioTiming extends StatefulWidget {
  
  const AudioTiming({super.key});

  @override
  createState() => _State();
}

class _State extends State<AudioTiming> {
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
        enableShadowMap: true,
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
  final List<three.Object3D> objects = [];

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 7, 3, 7 );

    // lights

    final ambientLight = three.AmbientLight( 0xcccccc );
    threeJs.scene.add( ambientLight );

    final directionalLight = three.DirectionalLight( 0xffffff, 2.5 );
    directionalLight.position.setValues( 0, 5, 5 );
    threeJs.scene.add( directionalLight );

    const d = 5.0;
    directionalLight.castShadow = true;
    directionalLight.shadow?.camera?.left = - d;
    directionalLight.shadow?.camera?.right = d;
    directionalLight.shadow?.camera?.top = d;
    directionalLight.shadow?.camera?.bottom = - d;

    directionalLight.shadow?.camera?.near = 1;
    directionalLight.shadow?.camera?.far = 20;

    directionalLight.shadow?.mapSize.x = 1024;
    directionalLight.shadow?.mapSize.y = 1024;

    // floor

    final floorGeometry = three.PlaneGeometry( 10, 10 );
    final floorMaterial = three.MeshLambertMaterial.fromMap( { 'color': 0x4676b6 } );

    final floor = three.Mesh( floorGeometry, floorMaterial );
    floor.rotation.x = math.pi * - 0.5;
    floor.receiveShadow = true;
    threeJs.scene.add( floor );

    // objects

    const count = 5;
    const radius = 3;

    final ballGeometry = three.SphereGeometry( 0.3, 32, 16 );
    ballGeometry.translate( 0, 0.3, 0 );
    final ballMaterial = three.MeshLambertMaterial.fromMap( { 'color': 0xcccccc } );

    // create objects when audio buffer is loaded
    for (int i = 0; i < count; i ++ ) {
      final s = i / count * math.pi * 2;
      final ball = three.Mesh( ballGeometry, ballMaterial );
      ball.castShadow = true;
      ball.userData['down'] = false;

      ball.position.x = radius * math.cos( s );
      ball.position.z = radius * math.sin( s );

      final audio = Audio(path: 'sounds/ping_pong.mp3');
      ball.add( audio );

      threeJs.scene.add( ball );
      objects.add( ball );
    }

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey );
    controls.minDistance = 1;
    controls.maxDistance = 25;

    threeJs.addAnimationEvent((dt){
      controls.update();
      animate();
    });
  }

  void animate() {
  	const speed = 2.5;
		const height = 3;
		const offset = 0.5;
    final time = threeJs.clock.getElapsedTime();

    for (int i = 0; i < objects.length; i ++ ) {
      final ball = objects[ i ];

      final previousHeight = ball.position.y;
      ball.position.y = ( math.sin( i * offset + ( time * speed ) ) * height ).abs();

      if ( ball.position.y < previousHeight ) {
        ball.userData['down'] = true;
      } 
      else {
        if ( ball.userData['down'] == true ) {
          // ball changed direction from down to up
          final audio = ball.children[0] as Audio;
          audio.play(); // play audio with perfect timing when ball hits the surface
          ball.userData['down'] = false;
        }
      }
    }
  }
}
