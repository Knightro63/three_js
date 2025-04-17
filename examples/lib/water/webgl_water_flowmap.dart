import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_objects/water/water2.dart';

class WebglWaterFlowmap extends StatefulWidget {
  const WebglWaterFlowmap({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglWaterFlowmap> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late Gui panel;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    panel = Gui((){setState(() {});});
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
          Statistics(data: data),
          if(threeJs.mounted)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: panel.render(context)
            )
          )
        ],
      ) 
    );
  }

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    // camera

    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 200 );
    threeJs.camera.position.setValues( 0, 25, 0 );
    threeJs.camera.lookAt( threeJs.scene.position );

    // ground

    final groundGeometry = three.PlaneGeometry( 20, 20, 10, 10 );
    final groundMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xe7e7e7 } );
    final ground = three.Mesh( groundGeometry, groundMaterial );
    ground.rotation.x = math.pi * - 0.5;
    threeJs.scene.add( ground );

    final textureLoader = three.TextureLoader();
    await textureLoader.fromAsset( 'assets/textures/floors/FloorsCheckerboard_S_Diffuse.jpg').then(( map ) {
      map?.wrapS = three.RepeatWrapping;
      map?.wrapT = three.RepeatWrapping;
      map?.anisotropy = 16;
      map?.repeat.setValues( 4, 4 );
      map?.colorSpace = three.SRGBColorSpace;
      groundMaterial.map = map;
      groundMaterial.needsUpdate = true;

    } );

    // water

    final waterGeometry = three.PlaneGeometry( 20, 20 );
    final flowMap = await textureLoader.fromAsset( 'assets/textures/water/Water_1_M_Flow.jpg' );

    final water = Water( waterGeometry, WaterOptions(
      scale: 2,
      textureWidth: 1024,
      textureHeight: 1024,
      flowMap: flowMap
    ));

    water.position.y = 1;
    water.rotation.x = math.pi * - 0.5;
    threeJs.scene.add( water );

    // flow map helper

    final helperGeometry = three.PlaneGeometry( 20, 20 );
    final helperMaterial = three.MeshBasicMaterial.fromMap( { 'map': flowMap } );
    final helper = three.Mesh( helperGeometry, helperMaterial );
    helper.position.y = 1.01;
    helper.rotation.x = math.pi * - 0.5;
    helper.visible = false;
    threeJs.scene.add( helper );

    final gui = panel.addFolder('GUI')..open();
    gui.addButton({'visible':false},'visible' )
    ..onChange((f){
      helper.visible = f;
    })
    ..name = 'Show Flow Map';

    final controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 5;
    controls.maxDistance = 50;
  }
}
