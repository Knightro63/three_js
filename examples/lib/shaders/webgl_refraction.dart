import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_objects/three_js_objects.dart';

class WebglRefraction extends StatefulWidget {
  const WebglRefraction({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglRefraction> {
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

  late final three.Mesh smallSphere;
  late final three.OrbitControls controls;
  late final Refractor refractor;

  Future<void> setup() async {
    threeJs.clock = three.Clock();

    // scene
    threeJs.scene = three.Scene();

    // camera
    threeJs.camera = three.PerspectiveCamera( 45,threeJs.width / threeJs.height, 1, 500 );
    threeJs.camera.position.setValues( 0, 75, 160 );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey);
    controls.target.setValues( 0, 40, 0 );
    controls.maxDistance = 400;
    controls.minDistance = 10;
    controls.update();

    // refractor

    final refractorGeometry = three.PlaneGeometry( 90, 90 );

    refractor = Refractor( refractorGeometry, {
      'color': 0xcbcbcb,
      'textureWidth': 1024,
      'textureHeight': 1024,
      'shader': waterRefractionShader
    } );

    refractor.position.setValues( 0, 50, 0 );

    threeJs.scene.add( refractor );

    // load dudv map for distortion effect

    final dudvMap = await three.TextureLoader().fromAsset( 'assets/textures/waterdudv.jpg');

    dudvMap!.wrapS = dudvMap.wrapT = three.RepeatWrapping;
    refractor.material!.uniforms['tDudv']['value'] = dudvMap;

    //

    final geometry = IcosahedronGeometry( 5, 0 );
    final material = three.MeshPhongMaterial.fromMap( { 'color': 0xffffff, 'emissive': 0x333333, 'flatShading': true } );
    smallSphere = three.Mesh( geometry, material );
    threeJs.scene.add( smallSphere );

    // walls
    final planeGeo = three.PlaneGeometry( 100.1, 100.1 );

    final planeTop = three.Mesh( planeGeo, three.MeshPhongMaterial.fromMap( { 'color': 0xffffff } ) );
    planeTop.position.y = 100;
    planeTop.rotateX( math.pi / 2 );
    threeJs.scene.add( planeTop );

    final planeBottom = three.Mesh( planeGeo, three.MeshPhongMaterial.fromMap( { 'color': 0xffffff } ) );
    planeBottom.rotateX( - math.pi / 2 );
    threeJs.scene.add( planeBottom );

    final planeBack = three.Mesh( planeGeo, three.MeshPhongMaterial.fromMap( { 'color': 0x7f7fff } ) );
    planeBack.position.z = - 50;
    planeBack.position.y = 50;
    threeJs.scene.add( planeBack );

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
    final mainLight = three.PointLight( 0xe7e7e7, .5, 250, 0 );
    mainLight.position.y = 60;
    threeJs.scene.add( mainLight );

    final greenLight = three.PointLight( 0x00ff00, 0.1, 1000, 0 );
    greenLight.position.setValues( 550, 50, 0 );
    threeJs.scene.add( greenLight );

    final redLight = three.PointLight( 0xff0000, 0.1, 1000, 0 );
    redLight.position.setValues( - 550, 50, 0 );
    threeJs.scene.add( redLight );

    final blueLight = three.PointLight( 0xbbbbfe, 0.1, 1000, 0 );
    blueLight.position.setValues( 0, 50, 550 );
    threeJs.scene.add( blueLight );

    threeJs.addAnimationEvent((dt){
      final time = threeJs.clock.elapsedTime;

      refractor.material!.uniforms['time']['value'] = time;

      smallSphere.position.setValues(
        math.cos( time ) * 30,
        ( math.cos( time * 2 ) ).abs() * 20 + 5,
        math.sin( time ) * 30
      );
      smallSphere.rotation.y = ( math.pi / 2 ) - time;
      smallSphere.rotation.z = time * 8;
      
    });
  }
}
