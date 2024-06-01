import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_objects/three_js_objects.dart';

class WebglWater extends StatefulWidget {
  final String fileName;
  const WebglWater({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglWater> {
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
    controls.clearListeners();
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

  late three.OrbitControls controls;

  final Map<String,dynamic> params = {
    'color': '#ffffff',
    'scale': 4,
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
      //map.colorSpace = three.SRGBColorSpace;
      groundMaterial.map = map;
      groundMaterial.needsUpdate = true;
    });

    // water

    // final waterGeometry = three.PlaneGeometry( 20, 20 );

    // final water = Water( waterGeometry, {
    //   'color': params['color'],
    //   'scale': params['scale'],
    //   'flowDirection': three.Vector2( params['flowX'], params['flowY'] ),
    //   'textureWidth': 1024,
    //   'textureHeight': 1024
    // } );

    // water.position.y = 1;
    // water.rotation.x = math.pi * - 0.5;
    // threeJs.scene.add( water );

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
    //directionalLight.position.setValues( - 1, 1, 1 );
    threeJs.scene.add( directionalLight );

    //

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey);
    controls.minDistance = 5;
    controls.maxDistance = 50;

    threeJs.addAnimationEvent((delta){
      controls.update();
      torusKnot.rotation.x += delta;
      torusKnot.rotation.y += delta * 0.5;
    });

  }
}
