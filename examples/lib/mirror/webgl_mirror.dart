import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_objects/water/reflector.dart';

class WebglMirror extends StatefulWidget {
  const WebglMirror({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglMirror> {
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
      setup: setup,      settings: three.Settings(
        toneMapping: three.ACESFilmicToneMapping,
        
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    cameraControls.dispose();
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

  late final three.OrbitControls cameraControls;

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    // camera
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 1, 500 );
    threeJs.camera.position.setValues( 0, 75, 160 );

    cameraControls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    cameraControls.target.setValues( 0, 40, 0 );
    cameraControls.maxDistance = 400;
    cameraControls.minDistance = 10;
    cameraControls.update();

    final planeGeo = three.PlaneGeometry( 100.1, 100.1 );

    three.BufferGeometry geometry = CircleGeometry( radius: 40, segments: 64 );
    final groundMirror = Reflector( geometry, {
      'clipBias': 0.003,
      'textureWidth': (threeJs.width * threeJs.dpr).toInt(),
      'textureHeight': (threeJs.height * threeJs.dpr).toInt(),
      'color': 0xb5b5b5
    } );
    groundMirror.position.y = 0.5;
    groundMirror.rotateX( - math.pi / 2 );
    groundMirror.renderType = three.RenderType.custom;
    threeJs.scene.add( groundMirror );

    geometry = three.PlaneGeometry( 100, 100 );
    final verticalMirror = Reflector( geometry, {
      'clipBias': 0.003,
      'textureWidth': (threeJs.width * threeJs.dpr).toInt(),
      'textureHeight': (threeJs.height * threeJs.dpr).toInt(),
      'color': 0xc1cbcb
    } );
    verticalMirror.position.y = 50;
    verticalMirror.position.z = - 50;
    verticalMirror.renderType = three.RenderType.custom;
    threeJs.scene.add( verticalMirror );

    final sphereGroup = three.Object3D();
    threeJs.scene.add( sphereGroup );

    geometry = CylinderGeometry( 0.1, 15 * math.cos( math.pi / 180 * 30 ), 0.1, 24, 1 );
    three.Material material = three.MeshPhongMaterial.fromMap( { 'color': 0xffffff, 'emissive': 0x8d8d8d } );
    final sphereCap = three.Mesh( geometry, material );
    sphereCap.position.y = - 15 * math.sin( math.pi / 180 * 30 ) - 0.05;
    sphereCap.rotateX( - math.pi );

    geometry = three.SphereGeometry( 15, 24, 24, math.pi / 2, math.pi * 2, 0, math.pi / 180 * 120 );
    final halfSphere = three.Mesh( geometry, material );
    halfSphere.add( sphereCap );
    halfSphere.rotateX( - math.pi / 180 * 135 );
    halfSphere.rotateZ( - math.pi / 180 * 20 );
    halfSphere.position.y = 7.5 + 15 * math.sin( math.pi / 180 * 30 );

    sphereGroup.add( halfSphere );

    geometry = IcosahedronGeometry( 5, 0 );
    material = three.MeshPhongMaterial.fromMap( { 'color': 0xffffff, 'emissive': 0x7b7b7b, 'flatShading': true } );
    
    final smallSphere = three.Mesh( geometry, material );
    threeJs.scene.add( smallSphere );

    // walls
    final planeTop = three.Mesh( planeGeo, three.MeshPhongMaterial.fromMap( { 'color': 0xffffff } ) );
    planeTop.position.y = 100;
    planeTop.rotateX( math.pi / 2 );
    threeJs.scene.add( planeTop );

    final planeBottom = three.Mesh( planeGeo, three.MeshPhongMaterial.fromMap( { 'color': 0xffffff } ) );
    planeBottom.rotateX( - math.pi / 2 );
    threeJs.scene.add( planeBottom );

    final planeFront = three.Mesh( planeGeo, three.MeshPhongMaterial.fromMap( { 'color': 0x7f7fff } ) );
    planeFront.position.z = 50;
    planeFront.position.y = 50;
    planeFront.rotateY( math.pi );
    threeJs.scene.add( planeFront );

    final planeRight = three.Mesh( planeGeo, three.MeshPhongMaterial.fromMap( { 'color': 0x00ff00 } ) );
    planeRight.position.x = 50;
    planeRight.position.y = 50;
    planeRight.rotateY( - math.pi / 2 );
    threeJs.scene.add( planeRight );

    final planeLeft = three.Mesh( planeGeo, three.MeshPhongMaterial.fromMap( { 'color': 0xff0000 } ) );
    planeLeft.position.x = - 50;
    planeLeft.position.y = 50;
    planeLeft.rotateY( math.pi / 2 );
    threeJs.scene.add( planeLeft );

    // lights
    final mainLight = three.PointLight( 0xe7e7e7, 0.35, 250, 0 );
    mainLight.position.y = 60;
    threeJs.scene.add( mainLight );

    final greenLight = three.PointLight( 0x00ff00, 0.15, 1000, 0 );
    greenLight.position.setValues( 550, 50, 0 );
    threeJs.scene.add( greenLight );

    final redLight = three.PointLight( 0xff0000, 0.15, 1000, 0 );
    redLight.position.setValues( - 550, 50, 0 );
    threeJs.scene.add( redLight );

    final blueLight = three.PointLight( 0xbbbbfe, 0.15, 1000, 0 );
    blueLight.position.setValues( 0, 50, 550 );
    threeJs.scene.add( blueLight );

    threeJs.postProcessor = ([dt]){
      threeJs.renderer?.setRenderTarget(threeJs.renderTarget);
      threeJs.renderer?.render( threeJs.scene, threeJs.camera );
      groundMirror.customRender?.call(renderer: threeJs.renderer,scene: threeJs.scene, camera: threeJs.camera);
      verticalMirror.customRender?.call(renderer: threeJs.renderer,scene: threeJs.scene, camera: threeJs.camera);
    };

    threeJs.addAnimationEvent((dt){
      final timer = DateTime.now().millisecondsSinceEpoch * 0.01;

      sphereGroup.rotation.y -= 0.002;

      smallSphere.position.setValues(
        math.cos( timer * 0.1 ) * 30,
        ( math.cos( timer * 0.2 ) ).abs() * 20 + 5,
        math.sin( timer * 0.1 ) * 30
      );
      smallSphere.rotation.y = ( math.pi / 2 ) - timer * 0.1;
      smallSphere.rotation.z = timer * 0.8;
    });
  }
}
