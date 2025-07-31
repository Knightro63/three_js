import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_objects/three_js_objects.dart';

class WebglShaderOcean extends StatefulWidget {
  const WebglShaderOcean({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglShaderOcean> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late Gui gui;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    gui = Gui((){setState(() {});});
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
        toneMappingExposure: 0.5,

        //useSourceTexture: true
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
              child: gui.render(context)
            )
          )
        ],
      ) 
    );
  }

  late final three.OrbitControls controls;
  late final Sky sky;
  late final Water water;
  late final three.Mesh mesh;
  final three.Vector3 sun = three.Vector3();

  final Map<String,dynamic> params = {
    'color': 0xa6ceec,
    'scale': 80.0,
    'flowX': 1.0,
    'flowY': 1.0
  };

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 55, threeJs.width /threeJs.height, 1, 20000 );
    threeJs.camera.position.setValues( 30, 30, 100 );

    threeJs.scene.add(three.AmbientLight(0xffffff,0.8));
    final pointLight = three.PointLight( 0xffffff, 20 );
    threeJs.camera.add( pointLight );
    threeJs.scene.add(threeJs.camera);
    threeJs.camera.lookAt(threeJs.scene.position);

    // Water
    final waterGeometry = three.PlaneGeometry( 10000, 10000 );

    // water = Water(
    //   waterGeometry,
    //   {
    //     'textureWidth': 512,
    //     'textureHeight': 512,
    //     'waterNormals': await three.TextureLoader().fromAsset( 'assets/textures/waternormals.jpg').then( ( texture ) {
    //       texture!.wrapS = texture.wrapT = three.RepeatWrapping;
    //     }),
    //     'sunDirection': three.Vector3(),
    //     'sunColor': 0xffffff,
    //     'waterColor': 0x001e0f,
    //     'distortionScale': 3.7,
    //     'fog': threeJs.scene.fog != null
    //   }
    // );

    // water.rotation.x = - math.pi / 2;
    // threeJs.scene.add( water );

    final textureLoader = three.TextureLoader();

    final water = Water( waterGeometry, WaterOptions(
      color: params['color'],
      scale: params['scale'],
      flowDirection: three.Vector2( params['flowX'], params['flowY'] ),
      textureWidth: 1024,
      textureHeight: 1024,
      normalMap0: await textureLoader.fromAsset( 'assets/textures/water/Water_1_M_Normal.jpg'),
      normalMap1: await textureLoader.fromAsset( 'assets/textures/water/Water_2_M_Normal.jpg')
    ));

    water.rotation.x = math.pi * - 0.5;
    threeJs.scene.add( water );

    sky = Sky.create();
    sky.scale.setScalar( 10000 );
    threeJs.scene.add( sky );

    final skyUniforms = sky.material!.uniforms;

    skyUniforms[ 'turbidity' ]['value'] = 10;
    skyUniforms[ 'rayleigh' ]['value'] = 2;
    skyUniforms[ 'mieCoefficient' ]['value'] = 0.005;
    skyUniforms[ 'mieDirectionalG' ]['value'] = 0.8;

    final parameters = {
      'elevation': 2.0,
      'azimuth': 180.0
    };

    final sceneEnv = three.Scene();
    sceneEnv.add( sky );
    threeJs.scene.add( sky );

    void updateSun(r) {
      final phi = three.MathUtils.degToRad( 90 - parameters['elevation']!);
      final theta = three.MathUtils.degToRad( parameters['azimuth']!);

      sun.setFromSphericalCoords( 1, phi, theta );

      sky.material!.uniforms[ 'sunPosition' ]['value'].setFrom( sun );
      //water.material!.uniforms[ 'sunDirection' ]['value'].setFrom( sun ).normalize();
    }

    updateSun('');

    final geometry = three.BoxGeometry( 30, 30, 30 );
    final material = three.MeshStandardMaterial.fromMap( { 'roughness': 0 } );

    mesh = three.Mesh( geometry, material );
    threeJs.scene.add( mesh );
    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.maxPolarAngle = math.pi * 0.495;
    controls.target.setValues( 0, 10, 0 );
    controls.minDistance = 40.0;
    controls.maxDistance = 200.0;
    controls.update();

    threeJs.postProcessor = ([dt]){
      threeJs.renderer!.render(threeJs.scene, threeJs.camera);
    };

    threeJs.addAnimationEvent((dt){
      controls.update();
      final time = three.now() * 0.001;

      mesh.position.y = math.sin( time ) * 20 + 5;
      mesh.rotation.x = time * 0.5;
      mesh.rotation.z = time * 0.51;

      //water.material!.uniforms[ 'time' ]['value'] += 1.0 / 60.0;
    });

    final folderSky = gui.addFolder( 'Sky' );
    folderSky.addSlider( parameters, 'elevation', 0, 90, 0.1 ).onChange( updateSun );
    folderSky.addSlider( parameters, 'azimuth', - 180, 180, 0.1 ).onChange( updateSun );
    folderSky.open();

    // final waterUniforms = water.material!.uniforms;
    // final folderWater = gui.addFolder( 'Water' );
    // folderWater.addSlider( waterUniforms['distortionScale'], 'value', 0, 8, 0.1 ).name = 'distortion';
    // folderWater.addSlider( waterUniforms['size'], 'value', 0.1, 10, 0.1 ).name ='size';
    // folderWater.open();

    final folderWater = gui.addFolder('GUI')..open();
    // folderWater.addColor( params, 'color' ).onChange( ( value ) {
    //   (water.material?.uniforms[ 'color' ]['value'] as three.Color).setFromHex32( value );
    // } );
    folderWater.addSlider( params, 'scale', 80, 200 ).onChange( ( value ) {
      water.material?.uniforms[ 'config' ]['value'].w = value;
    } );
    folderWater.addSlider( params, 'flowX', - 1, 1 )..step( 0.01 )..onChange( ( value ) {
      water.material?.uniforms[ 'flowDirection' ]['value'].x = value;
      water.material?.uniforms[ 'flowDirection' ]['value'].normalize();
    } );
    folderWater.addSlider( params, 'flowY', - 1, 1 )..step( 0.01 )..onChange( ( value ) {
      water.material?.uniforms[ 'flowDirection' ]['value'].y = value;
      water.material?.uniforms[ 'flowDirection' ]['value'].normalize();
    } ); 
  }
}
