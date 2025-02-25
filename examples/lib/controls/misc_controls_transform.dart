
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';
import 'package:three_js_transform_controls/three_js_transform_controls.dart';

class MiscControlsTransform extends StatefulWidget {
  
  const MiscControlsTransform({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MiscControlsTransform> {
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
      windowResizeUpdate: (newSize){
        final aspect = newSize.width / newSize.height;

        cameraPersp.aspect = aspect;
        cameraPersp.updateProjectionMatrix();

        cameraOrtho.left = cameraOrtho.bottom * aspect;
        cameraOrtho.right = cameraOrtho.top * aspect;
        cameraOrtho.updateProjectionMatrix();
      }
    );
    super.initState();
  }
  @override
  void dispose() {
    control.dispose();
    timer.cancel();
    threeJs.dispose();
    orbit.clearListeners();
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

  late TransformControls control;
  late three.OrbitControls orbit;
  late three.PerspectiveCamera cameraPersp;
  late three.OrthographicCamera cameraOrtho;

  Future<void> setup() async{
    const frustumSize = 5.0;
    final aspect = threeJs.width / threeJs.height;
    cameraPersp = three.PerspectiveCamera( 50, aspect, 0.1, 100 );
    cameraOrtho = three.OrthographicCamera( - frustumSize * aspect, frustumSize * aspect, frustumSize, - frustumSize, 0.1, 100 );
    threeJs.camera = cameraPersp;

    threeJs.camera.position.setValues( 5, 2.5, 5 );

    threeJs.scene = three.Scene();
    threeJs.scene.add( GridHelper( 5, 10, 0x888888, 0x444444 ) );

    final ambientLight = three.AmbientLight( 0xffffff );
    threeJs.scene.add( ambientLight );

    final light = three.DirectionalLight( 0xffffff, 0.9 );
    light.position.setValues( 1, 1, 1 );
    threeJs.scene.add( light );

    final texture = await three.TextureLoader().fromAsset( 'assets/textures/crate.gif');
    //texture.colorSpace = three.SRGBColorSpace;
    texture!.anisotropy = threeJs.renderer!.capabilities.getMaxAnisotropy().toInt();

    final geometry = three.BoxGeometry();
    final material = three.MeshLambertMaterial.fromMap({ 'map': texture } );

    orbit = three.OrbitControls(threeJs.camera, threeJs.globalKey);
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
          control.setRotationSnap( three.MathUtils.degToRad( 15 ) );
          control.setScaleSnap( 0.25 );
          break;
        case 'w':
          control.setMode(GizmoType.translate );
          break;
        case 'e':
          control.setMode(GizmoType.rotate);
          break;
        case 'r':
          control.setMode(GizmoType.scale);
          break;
        case 'c':
          final position = threeJs.camera.position.clone();

          threeJs.camera = threeJs.camera is three.PerspectiveCamera ?cameraOrtho:cameraPersp;
          threeJs.camera.position.setFrom( position );

          orbit.object = threeJs.camera;
          control.camera = threeJs.camera;

          threeJs.camera.lookAt(orbit.target);
          threeJs.onWindowResize(context);
          break;
        case 'v':
          final randomFoV = math.Random().nextDouble() + 0.1;
          final randomZoom = math.Random().nextDouble() + 0.1;

          cameraPersp.fov = randomFoV * 160;
          cameraOrtho.bottom = - randomFoV * 500;
          cameraOrtho.top = randomFoV * 500;

          cameraPersp.zoom = randomZoom * 5;
          cameraOrtho.zoom = randomZoom * 5;
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
