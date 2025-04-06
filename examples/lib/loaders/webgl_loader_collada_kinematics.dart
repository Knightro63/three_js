import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglLoaderColladaKinematics extends StatefulWidget {
  
  const WebglLoaderColladaKinematics({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglLoaderColladaKinematics> {
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

  three.Object3D? dae;
  three.KinematicsData? kinematics;
  final tweenParameters = {};
  late final three.Tween kinematicsTween;
  
  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 1, 2000 );
    threeJs.camera.position.setValues( 2, 2, 3 );

    threeJs.scene = three.Scene();

    // Grid

    final grid = GridHelper( 20, 20, 0xc1c1c1, 0x8d8d8d );
    threeJs.scene.add( grid );

    // Add the COLLADA
		final loader = three.ColladaLoader();
		await loader.fromAsset( 'assets/models/collada/abb_irb52_7_120.dae').then(( collada ) {
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

      kinematics = collada?.kinematics;
		});

    threeJs.scene.add( dae );

    // Lights

    final light = three.HemisphereLight( 0xfff7f7, 0x494966, 3 );
    threeJs.scene.add( light );

    setupTween();

    threeJs.addAnimationEvent((dt){
      kinematicsTween.update();

      final timer = DateTime.now().millisecondsSinceEpoch * 0.0001;

      threeJs.camera.position.x = math.cos( timer ) * 20;
      threeJs.camera.position.y = 10;
      threeJs.camera.position.z = math.sin( timer ) * 20;

      threeJs.camera.lookAt(three.Vector3( 0, 5, 0 ));

    });
  }

  void setupTween() {
    if(kinematics != null){
      final duration = math.Random().nextInt(4000)+1000;//three.MathUtils.randInt( 1000, 5000 );
      final target = {};

      for ( final prop in kinematics!.joints.keys) {
        if (kinematics!.joints[ prop ]['static'] == false) {
          final joint = kinematics!.joints[ prop ];
          final old = tweenParameters[ prop ];
          final position = old ?? joint['zeroPosition'];
          tweenParameters[ prop ] = position;
          target[prop] = math.Random().nextInt(joint['limits']['max'].toInt()-joint['limits']['min'].toInt())+joint['limits']['min'].toInt();//three.MathUtils.randInt( joint.limits.min, joint.limits.max );
        }
      }

      kinematicsTween = three.Tween( tweenParameters ).to( target, duration ).easing( three.Easing.Quadratic[three.ETTypes.Out] );
      
      kinematicsTween.onUpdate(( object, g) {
        for ( final prop in kinematics!.joints.keys ) {
          if (!kinematics!.joints[ prop ]['static'] ) {
            kinematics!.setJointValue?.call( prop, object[ prop ] );
          }
        }
      } );

      kinematicsTween.start();

      //setTimeout( setupTween, duration );
    }
  }
}
