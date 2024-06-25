import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglLoaderColladaKinematics extends StatefulWidget {
  final String fileName;
  const WebglLoaderColladaKinematics({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderColladaKinematics> {
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
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: threeJs.build()
    );
  }

  three.Object3D? dae;
  
  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 1, 2000 );
    threeJs.camera.position.setValues( 2, 2, 3 );

    threeJs.scene = three.Scene();

    // Grid

    final grid = GridHelper( 20, 20, 0xc1c1c1, 0x8d8d8d );
    threeJs.scene.add( grid );

    // Add the COLLADA
		final loader = three.ColladaLoader();
		loader.fromAsset( 'assets/models/collada/abb_irb52_7_120.dae').then(( collada ) {
      dae = collada?.scene;

      dae?.traverse(( child ) {
        if ( child is three.Mesh ) {
          // model does not have normals
          child.material?.flatShading = true;
        }
      } );

      dae?.scale.x = 10.0;
      dae?.scale.y = 10.0;
      dae?.scale.z = 10.0;
      dae?.updateMatrix();

      //kinematics = collada.kinematics;
		});

    threeJs.scene.add( dae );

    // Lights

    final light = three.HemisphereLight( 0xfff7f7, 0x494966, 3 );
    threeJs.scene.add( light );

    setupTween();

    threeJs.addAnimationEvent((dt){
      //TWEEN.update();

      final timer = DateTime.now().millisecondsSinceEpoch * 0.0001;

      threeJs.camera.position.x = math.cos( timer ) * 20;
      threeJs.camera.position.y = 10;
      threeJs.camera.position.z = math.sin( timer ) * 20;

      threeJs.camera.lookAt(three.Vector3( 0, 5, 0 ));

    });
  }

  void setupTween() {
    // final duration = three.MathUtils.randInt( 1000, 5000 );
    // final target = {};

    // for ( final prop in kinematics.joints ) {
    //   if ( kinematics.joints.hasOwnProperty( prop ) ) {

    //     if ( ! kinematics.joints[ prop ].static ) {
    //       final joint = kinematics.joints[ prop ];
    //       final old = tweenParameters[ prop ];
    //       final position = old ? old : joint.zeroPosition;

    //       tweenParameters[ prop ] = position;
    //       target[ prop ] = three.MathUtils.randInt( joint.limits.min, joint.limits.max );
    //     }
    //   }
    // }

    // kinematicsTween = TWEEN.Tween( tweenParameters ).to( target, duration ).easing( TWEEN.Easing.Quadratic.Out );
    
    // kinematicsTween.onUpdate(( object ) {
    //   for ( final prop in kinematics.joints ) {
    //     if ( kinematics.joints.hasOwnProperty( prop ) ) {
    //       if ( ! kinematics.joints[ prop ].static ) {
    //         kinematics.setJointValue( prop, object[ prop ] );

    //       }
    //     }
    //   }
    // } );

    // kinematicsTween.start();

    // setTimeout( setupTween, duration );
  }
}
