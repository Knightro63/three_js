import 'package:flutter/material.dart';
import 'package:three_js_transform_controls/three_js_transform_controls.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_math/three_js_math.dart' as tmath;

import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/services.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MiscControlsArcball(),
    );
  }
}

class MiscControlsArcball extends StatefulWidget {
  const MiscControlsArcball({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MiscControlsArcball> {
  late three.ThreeJS threeJs;
  late TransformControls control;
  late ArcballControls orbit;
  late three.PerspectiveCamera cameraPersp;
  
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
    control.dispose();
    orbit.clearListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return threeJs.build();
  }

  Future<void> setup() async{
    final aspect = threeJs.width / threeJs.height;
    cameraPersp = three.PerspectiveCamera( 50, aspect, 0.1, 100 );
    threeJs.camera = cameraPersp;

    threeJs.camera.position.setValues( 5, 2.5, 5 );

    threeJs.scene = three.Scene();

    final ambientLight = three.AmbientLight( 0xffffff,0.3 );
    threeJs.scene.add( ambientLight );

    final light = three.DirectionalLight( 0xffffff, 0.3 );
    light.position = threeJs.camera.position;
    threeJs.scene.add( light );

    final geometry = three.BoxGeometry();
    final material = three.MeshLambertMaterial.fromMap();

    orbit = ArcballControls(threeJs.camera, threeJs.globalKey);
    orbit.update();
    orbit.addEventListener('change', (event) {
      threeJs.render();
    });

    control = TransformControls(threeJs.camera, threeJs.globalKey);
    control.addEventListener('change', (event) {
      threeJs.render();
    });

    control.addEventListener( 'dragging-changed', (event) {
      orbit.enabled = ! event.value;
    });

    final mesh = three.Mesh( geometry, material );
    threeJs.scene.add( mesh );

    control.attach( mesh );
    threeJs.scene.add( control );

    threeJs.domElement.addEventListener(
      three.PeripheralType.resize, 
      threeJs.onWindowResize
    );

    threeJs.domElement.addEventListener(three.PeripheralType.keydown,(event) {
      event as LogicalKeyboardKey;
      switch (event.keyLabel.toLowerCase()) {
        case 'q':
          control.setSpace( control.space == 'local' ? 'world' : 'local' );
          break;
        case 'shift right':
        case 'shift left':
          control.setTranslationSnap( 1 );
          control.setRotationSnap( tmath.MathUtils.degToRad( 15 ) );
          control.setScaleSnap( 0.25 );
          break;
        case 'w':
          control.setMode(GizmoType.translate);
          break;
        case 'e':
          control.setMode(GizmoType.rotate);
          break;
        case 'r':
          control.setMode(GizmoType.scale);
          break;
        case 'c':
          final position = threeJs.camera.position.clone();

          threeJs.camera = cameraPersp;
          threeJs.camera.position.setFrom( position );

          //orbit.object = threeJs.camera;
          control.camera = threeJs.camera;

          threeJs.camera.lookAt(orbit.target);
          threeJs.onWindowResize(context);
          break;
        case 'v':
          final randomFoV = math.Random().nextDouble() + 0.1;
          final randomZoom = math.Random().nextDouble() + 0.1;

          cameraPersp.fov = randomFoV * 160;

          cameraPersp.zoom = randomZoom * 5;
          threeJs.onWindowResize(context);
          break;
        case '+':
        case '=':
          control.setSize( control.size + 0.1 );
          break;
        case '-':
        case '_':
          control.setSize( math.max( control.size - 0.1, 0.1 ) );
          break;
        case 'x':
          control.showX = ! control.showX;
          break;
        case 'y':
          control.showY = ! control.showY;
          break;
        case 'z':
          control.showZ = !control.showZ;
          break;
        case ' ':
          control.enabled = ! control.enabled;
          break;
        case 'escape':
          //control.reset();
          break;
      }
    });

    threeJs.domElement.addEventListener(three.PeripheralType.keyup, (event) {
      event as LogicalKeyboardKey;
      switch ( event.keyLabel.toLowerCase() ) {
        case 'shift right':
        case 'shift left':
          control.setTranslationSnap( null );
          control.setRotationSnap( null );
          control.setScaleSnap( null );
          break;
      }
    });
  }
}
