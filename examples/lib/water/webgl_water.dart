import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_objects/three_js_objects.dart';

class WebglWater extends StatefulWidget {
  
  const WebglWater({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglWater> {
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

  late three.OrbitControls controls;

  final Map<String,dynamic> params = {
    'color': 0xffffff,
    'scale': 4.0,
    'flowX': 1.0,
    'flowY': 1.0
  };

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width/threeJs.height, 0.1, 200 );
    threeJs.camera.position.setValues( - 15, 7, 15 );
    threeJs.camera.lookAt( threeJs.scene.position );

    final torusKnotGeometry = TorusKnotGeometry( 3, 1, 256, 32 );
    final torusKnotMaterial = three.MeshNormalMaterial();

    final torusKnot = three.Mesh( torusKnotGeometry, torusKnotMaterial );
    torusKnot.position.y = 4;
    torusKnot.scale.setValues( 0.5, 0.5, 0.5 );
    threeJs.scene.add( torusKnot );

    // ground

    final groundGeometry = three.PlaneGeometry( 20, 20 );
    final groundMaterial = three.MeshStandardMaterial.fromMap( { 'roughness': 0.8, 'metalness': 0.4 } );
    final ground = three.Mesh( groundGeometry, groundMaterial );
    ground.rotation.x = math.pi * - 0.5;
    threeJs.scene.add( ground );

    final textureLoader = three.TextureLoader();
    textureLoader.fromAsset( 'assets/textures/hardwood2_diffuse.jpg').then(( map ) {
      map!.wrapS = three.RepeatWrapping;
      map.wrapT = three.RepeatWrapping;
      map.anisotropy = 16;
      map.repeat.setValues( 4, 4 );
      map.colorSpace = three.SRGBColorSpace;
      groundMaterial.map = map;
      groundMaterial.needsUpdate = true;
    });

    // water

    final waterGeometry = three.PlaneGeometry( 20, 20 );

    final water = Water( waterGeometry, WaterOptions(
      color: params['color'],
      scale: params['scale'],
      flowDirection: three.Vector2( params['flowX'], params['flowY'] ),
      textureWidth: 1024,
      textureHeight: 1024
    ));

    water.position.y = 1;
    water.rotation.x = math.pi * - 0.5;
    threeJs.scene.add( water );

    // skybox

    final cubeTextureLoader = three.CubeTextureLoader();
    cubeTextureLoader.setPath( 'assets/textures/cube/Park2/' );

    final cubeTexture = await cubeTextureLoader.fromAssetList( [
      'posx.jpg', 'negx.jpg',
      'posy.jpg', 'negy.jpg',
      'posz.jpg', 'negz.jpg'
    ]);

    threeJs.scene.background = cubeTexture;

    // light

    final ambientLight = three.AmbientLight( 0xe7e7e7, 0.4 );
    threeJs.scene.add( ambientLight );

    final directionalLight = three.DirectionalLight( 0xffffff, 0.4 );
    directionalLight.position.setValues( - 1, 1, 1 );
    threeJs.scene.add( directionalLight );

    final gui = panel.addFolder('GUI')..open();
    gui.addColor( params, 'color' ).onChange( ( value ) {
      (water.material?.uniforms[ 'color' ]['value'] as three.Color).setFromHex32( value );
    } );
    gui.addSlider( params, 'scale', 1, 10 ).onChange( ( value ) {
      water.material?.uniforms[ 'config' ]['value'].w = value;
    } );
    gui.addSlider( params, 'flowX', - 1, 1 )..step( 0.01 )..onChange( ( value ) {
      water.material?.uniforms[ 'flowDirection' ]['value'].x = value;
      water.material?.uniforms[ 'flowDirection' ]['value'].normalize();
    } );
    gui.addSlider( params, 'flowY', - 1, 1 )..step( 0.01 )..onChange( ( value ) {
      water.material?.uniforms[ 'flowDirection' ]['value'].y = value;
      water.material?.uniforms[ 'flowDirection' ]['value'].normalize();
    } ); 

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey);
    controls.minDistance = 5;
    controls.maxDistance = 50;

    threeJs.postProcessor = ([dt]){
      threeJs.renderer?.render(threeJs.scene, threeJs.camera);
    };

    threeJs.addAnimationEvent((delta){
      controls.update();
      torusKnot.rotation.x += delta;
      torusKnot.rotation.y += delta * 0.5;
    });

  }
}
