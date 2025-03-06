import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_postprocessing/post/index.dart';

class MiscControlsFly extends StatefulWidget {
  
  const MiscControlsFly({super.key});

  @override
  createState() => _State();
}

class _State extends State<MiscControlsFly> {
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
          Statistics(data: data)
        ],
      ) 
    );
  }

  late three.FlyControls controls;

  Future<void> setup() async {
    const radius = 6371.0;
    const tilt = 0.41;

    const cloudsScale = 1.005;
    const moonScale = 0.23;

    final textureLoader = three.TextureLoader()..flipY = true;

    threeJs.camera = three.PerspectiveCamera( 25, threeJs.width / threeJs.height, 50, 1e7 );
    threeJs.camera.position.z = radius * 5;

    threeJs.scene = three.Scene();
    threeJs.scene.fog = three.FogExp2(0x000000, 0.00000025 );

    final dirLight = three.DirectionalLight( 0xffffff, 0.9 );
    dirLight.position.setValues( - 1, 0, 1 ).normalize();
    threeJs.scene.add( dirLight );

    final materialNormalMap = three.MeshPhongMaterial.fromMap( {
      'specular': 0x7c7c7c,
      'shininess': 15,
      'map': await textureLoader.fromAsset( 'assets/textures/planets/earth_atmos_2048.jpg' ),
      'specularMap': await textureLoader.fromAsset( 'assets/textures/planets/earth_specular_2048.jpg' ),
      'normalMap': await textureLoader.fromAsset( 'assets/textures/planets/earth_normal_2048.jpg' ),

      // y scale is negated to compensate for normal map handedness.
      'normalScale': three.Vector2( 0.85, - 0.85 )
    });
    //materialNormalMap.map.colorSpace = THREE.SRGBColorSpace;

    // planet

    final geometry = three.SphereGeometry( radius, 100, 50 );

    final meshPlanet = three.Mesh( geometry, materialNormalMap );
    meshPlanet.rotation.y = 0;
    meshPlanet.rotation.z = tilt;
    threeJs.scene.add( meshPlanet );

    // clouds

    final materialClouds = three.MeshLambertMaterial.fromMap( {
      'map': await textureLoader.fromAsset( 'assets/textures/planets/earth_clouds_1024.png' ),
      'transparent': true
    });
    //materialClouds.map.colorSpace = THREE.SRGBColorSpace;

    final meshClouds = three.Mesh( geometry, materialClouds );
    meshClouds.scale.setValues( cloudsScale, cloudsScale, cloudsScale );
    meshClouds.rotation.z = tilt;
    threeJs.scene.add( meshClouds );

    // moon

    final materialMoon = three.MeshPhongMaterial.fromMap( {
      'map': await textureLoader.fromAsset( 'assets/textures/planets/moon_1024.jpg' )
    });
    //materialMoon.map.colorSpace = THREE.SRGBColorSpace;

    final meshMoon = three.Mesh( geometry, materialMoon );
    meshMoon.position.setValues( radius * 5, 0, 0 );
    meshMoon.scale.setValues( moonScale, moonScale, moonScale );
    threeJs.scene.add( meshMoon );

    // stars
    final starsGeometry = [ three.BufferGeometry(), three.BufferGeometry() ];
    final List<double> vertices1 = [];
    final List<double> vertices2 = [];
    final vertex = three.Vector3();

    for(int i = 0; i < 250; i ++ ) {
      vertex.x = math.Random().nextDouble() * 2 - 1;
      vertex.y = math.Random().nextDouble() * 2 - 1;
      vertex.z = math.Random().nextDouble() * 2 - 1;
      vertex.scale( radius );

      vertices1.addAll([vertex.x, vertex.y, vertex.z]);
    }

    for (int i = 0; i < 1500; i ++ ) {
      vertex.x = math.Random().nextDouble() * 2 - 1;
      vertex.y = math.Random().nextDouble() * 2 - 1;
      vertex.z = math.Random().nextDouble() * 2 - 1;
      vertex.scale( radius );
      vertices2.addAll([vertex.x, vertex.y, vertex.z]);
    }

    starsGeometry[ 0 ].setAttributeFromString( 'position', three.Float32BufferAttribute.fromList(vertices1 , 3 ) );
    starsGeometry[ 1 ].setAttributeFromString( 'position', three.Float32BufferAttribute.fromList(vertices2 , 3 ) );

    final starsMaterials = [
      three.PointsMaterial.fromMap( { 'color': 0x9c9c9c, 'size': 2, 'sizeAttenuation': false } ),
      three.PointsMaterial.fromMap( { 'color': 0x9c9c9c, 'size': 1, 'sizeAttenuation': false } ),
      three.PointsMaterial.fromMap( { 'color': 0x7c7c7c, 'size': 2, 'sizeAttenuation': false } ),
      three.PointsMaterial.fromMap( { 'color': 0x838383, 'size': 1, 'sizeAttenuation': false } ),
      three.PointsMaterial.fromMap( { 'color': 0x5a5a5a, 'size': 2, 'sizeAttenuation': false } ),
      three.PointsMaterial.fromMap( { 'color': 0x5a5a5a, 'size': 1, 'sizeAttenuation': false } )
    ];

    for (int i = 10; i < 30; i ++ ) {

      final stars = three.Points( starsGeometry[ i % 2 ], starsMaterials[ i % 6 ] );

      stars.rotation.x = math.Random().nextDouble() * 6;
      stars.rotation.y = math.Random().nextDouble() * 6;
      stars.rotation.z = math.Random().nextDouble() * 6;
      stars.scale.setScalar( i * 10 );

      stars.matrixAutoUpdate = false;
      stars.updateMatrix();

      threeJs.scene.add( stars );
    }

    controls = three.FlyControls(threeJs.camera, threeJs.globalKey);
    controls.movementSpeed = 1000;
    controls.rollSpeed = math.pi / 24;
    controls.autoForward = false;
    controls.dragToLook = false;

    final dMoonVec = three.Vector3.zero();

    final composer = EffectComposer(threeJs.renderer!);
    if(kIsWeb){
      final renderModel = RenderPass(threeJs.scene, threeJs.camera);
      final effectFilm = FilmPass(noiseIntensity: 0.35 );
      final outputPass = OutputPass();

      composer.addPass( renderModel );
      composer.addPass( effectFilm );
      composer.addPass( outputPass );
    }
    
    threeJs.addAnimationEvent((delta){
      const rotationSpeed = 0.02;
      double d = 1.0;

      meshPlanet.rotation.y += rotationSpeed * delta;
      meshClouds.rotation.y += 1.25 * rotationSpeed * delta;

      // slow down as we approach the surface

      final dPlanet = threeJs.camera.position.length;

      dMoonVec.sub2(threeJs.camera.position, meshMoon.position );
      final dMoon = dMoonVec.length;

      if (dMoon < dPlanet) {
        d = ( dMoon - radius * moonScale * 1.01 );
      } 
      else {
        d = ( dPlanet - radius * 1.01 );
      }

      controls.movementSpeed = 0.033 * d;
      controls.update(delta);
      composer.render(delta );
    });
  }
}
