import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglMaterialsCar extends StatefulWidget {
  const WebglMaterialsCar({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglMaterialsCar> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late Gui pannel;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    pannel = Gui((){setState(() {});});
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
        enableShadowMap: true,
        toneMapping: three.ACESFilmicToneMapping,
        toneMappingExposure: 0.85
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
              child: pannel.render(context)
            )
          )
        ],
      ) 
    );
  }

  late final three.OrbitControls controls;
  late final GridHelper grid;
  final List<three.Object3D> wheels = [];

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 4.25, 1.4, - 4.5 );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.maxDistance = 9;
    controls.maxPolarAngle = three.MathUtils.degToRad( 90 );
    controls.target.setValues( 0, 0.5, 0 );
    controls.update();

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x333333 );
    threeJs.scene.environment = await three.RGBELoader().fromAsset( 'assets/textures/equirectangular/venice_sunset_1k.hdr' );
    threeJs.scene.environment?.mapping = three.EquirectangularReflectionMapping;
    threeJs.scene.fog = three.Fog( 0x333333, 10, 15 );

    grid = GridHelper( 20, 40, 0xffffff, 0xffffff );
    grid.material?.opacity = 0.2;
    grid.material?.depthWrite = false;
    grid.material?.transparent = true;
    threeJs.scene.add( grid );

    // materials

    final bodyMaterial = three.MeshPhysicalMaterial.fromMap( {
      'color': 0xff0000, 'metalness': 1.0, 'roughness': 0.5, 'clearcoat': 1.0, 'clearcoatRoughness': 0.03
    } );

    final detailsMaterial = three.MeshStandardMaterial.fromMap( {
      'color': 0xffffff, 'metalness': 1.0, 'roughness': 0.5
    } );

    final glassMaterial = three.MeshPhysicalMaterial.fromMap( {
      'color': 0xffffff, 'metalness': 0.25, 'roughness': 0, 'transmission': 1.0
    } );
    // Car

    final shadow = await three.TextureLoader().fromAsset( 'assets/models/gltf/ferrari/ferrari_ao.png' );
    final loader = three.GLTFLoader();

    await loader.fromAsset( 'assets/models/gltf/ferrari/ferrari.gltf').then((gltf ) {
      final carModel = gltf!.scene.children[ 0 ];

      carModel.getObjectByName( 'body' )?.material = bodyMaterial;

      carModel.getObjectByName( 'rim_fl' )?.material = detailsMaterial;
      carModel.getObjectByName( 'rim_fr' )?.material = detailsMaterial;
      carModel.getObjectByName( 'rim_rr' )?.material = detailsMaterial;
      carModel.getObjectByName( 'rim_rl' )?.material = detailsMaterial;
      carModel.getObjectByName( 'trim' )?.material = detailsMaterial;
      carModel.getObjectByName( 'glass' )?.material = glassMaterial;

      wheels.addAll([
        carModel.getObjectByName( 'wheel_fl' )!,
        carModel.getObjectByName( 'wheel_fr' )!,
        carModel.getObjectByName( 'wheel_rl' )!,
        carModel.getObjectByName( 'wheel_rr' )!
      ]);

      // shadow
      final mesh = three.Mesh(
        three.PlaneGeometry( 0.655 * 4, 1.3 * 4 ),
        three.MeshBasicMaterial.fromMap( {
          'map': shadow, 'blending': three.MultiplyBlending, 'toneMapped': false, 'transparent': true
        } )
      );
      mesh.rotation.x = - math.pi / 2;
      mesh.renderOrder = 2;
      carModel.add( mesh );

      threeJs.scene.add( carModel );
    } );

    threeJs.addAnimationEvent((dt){
      controls.update();
      final time = -  three.now()/ 1000;
      for ( int i = 0; i < wheels.length; i ++ ) {
        wheels[ i ].rotation.x = time * math.pi * 2;
      }
      grid.position.z = - ( time ) % 1;
    });

    final params = {
      'body-color': bodyMaterial.color.getHex(),
      'details-color': detailsMaterial.color.getHex(),
      'glass-color': glassMaterial.color.getHex(),
    };

    final gui = pannel.addFolder('GUI')..open();

    gui.addColor( params, 'body-color' ).onChange((val) {
      bodyMaterial.color.setFromHex32( val );
    } );
    gui.addColor( params, 'details-color' ).onChange((val) {
      detailsMaterial.color.setFromHex32( val );
    } );
    gui.addColor( params, 'glass-color' ).onChange((val) {
      glassMaterial.color.setFromHex32( val );
    } );
  }
}
