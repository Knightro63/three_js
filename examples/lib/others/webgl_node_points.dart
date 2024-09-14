import 'dart:async';
import 'dart:math' as math;
import 'package:example/others/teapot_geometry.dart';
import 'package:example/src/statistics.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_nodes/three_js_nodes.dart';

class WebglNodesPoints extends StatefulWidget {
  
  const WebglNodesPoints({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglNodesPoints> {
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
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    controls.dispose();
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
    threeJs.camera = three.PerspectiveCamera( 55, threeJs.width/threeJs.height, 2, 2000 );
    threeJs.camera.position.x = 0;
    threeJs.camera.position.y = 100;
    threeJs.camera.position.z = - 300;

    threeJs.scene = three.Scene();
    threeJs.scene.fog = three.FogExp2( 0x000000, 0.001 );

    final teapotGeometry = TeapotGeometry(segments: 7 );
    final sphereGeometry = three.SphereGeometry( 50, 130, 16 );

    final geometry = three.BufferGeometry();

    // buffers

    final List<double> speed = [];
    final List<double> intensity = [];
    final List<double> size = [];

    final positionAttribute = teapotGeometry.getAttributeFromString( 'position' );
    final particleCount = positionAttribute.count;

    for (int i = 0; i < particleCount; i ++ ) {
      speed.add( 20 + math.Random().nextDouble() * 50 );
      intensity.add( math.Random().nextDouble() * .04 );
      size.add( 30 + math.Random().nextDouble() * 230 );
    }

    geometry.setAttributeFromString( 'position', positionAttribute );
    geometry.setAttributeFromString( 'targetPosition', sphereGeometry.getAttributeFromString( 'position' ) );
    geometry.setAttributeFromString( 'particleSpeed', three.Float32BufferAttribute.fromList( speed, 1 ) );
    geometry.setAttributeFromString( 'particleIntensity', three.Float32BufferAttribute.fromList( intensity, 1 ) );
    geometry.setAttributeFromString( 'particleSize', three.Float32BufferAttribute.fromList( size, 1 ) );

    // maps

    // Forked from: https://answers.unrealengine.com/questions/143267/emergency-need-help-with-fire-fx-weird-loop.html

    final fireMap = await three.TextureLoader().fromAsset( 'textures/sprites/firetorch_1.jpg' );
    fireMap?.colorSpace = three.SRGBColorSpace;

    // nodes

    final targetPosition = threeJs.renderer!.attributes.createBuffer( 'targetPosition',  3);//'vec3'
    final particleSpeed = attribute( 'particleSpeed', 'float' );
    final particleIntensity = attribute( 'particleIntensity', 'float' );
    final particleSize = attribute( 'particleSize', 'float' );

    final time = timerLocal();

    final fireUV = spritesheetUV(
      vec2( 6, 6 ), // count
      pointUV, // uv
      time.mul( particleSpeed ) // current frame
    );

    final fireSprite = texture( fireMap, fireUV );
    final fire = fireSprite.mul( particleIntensity );

    final lerpPosition = uniform( 0 );

    final positionNode = mix( positionLocal, targetPosition, lerpPosition );

    // material

    final material = PointsNodeMaterial.fromMap( {
      'depthWrite': false,
      'transparent': true,
      'sizeAttenuation': true,
      'blending': three.AdditiveBlending
    } );

    material.colorNode = fire;
    material.sizeNode = particleSize;
    material.positionNode = positionNode;

    final particles = three.Points( geometry, material );
    threeJs.scene.add( particles );

    // controls

    final controls = three.OrbitControls( threeJs.camera, threeJs.globalKey);
    controls.maxDistance = 1000;
    controls.update();

    threeJs.addAnimationEvent((dt){
      nodeFrame.update();
    });
  }
}