import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglPointsSprites extends StatefulWidget {
  
  const WebglPointsSprites({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglPointsSprites> {
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
          Statistics(data: data)
        ],
      ) 
    );
  }

  final List<three.Material> materials = [];
  double windowHalfX = 0;
  double windowHalfY = 0;
  final three.Vector2 mouse = three.Vector2.zero();
  late List<dynamic> parameters;

  Future<void> setup() async {
    windowHalfX = threeJs.width/2;
    windowHalfY = threeJs.height/2;
    threeJs.camera = three.PerspectiveCamera( 75, threeJs.width/threeJs.height, 1, 2000 );
    threeJs.camera.position.z = 1000;

    threeJs.scene = three.Scene();
    threeJs.scene.fog = three.FogExp2( 0x000000, 0.0008 );

    final geometry = three.BufferGeometry();
    final List<double> vertices = [];

    final textureLoader = three.TextureLoader();

    final sprite1 = await textureLoader.fromAsset( 'assets/textures/sprites/snowflake1.png' );
    final sprite2 = await textureLoader.fromAsset( 'assets/textures/sprites/snowflake2.png' );
    final sprite3 = await textureLoader.fromAsset( 'assets/textures/sprites/snowflake3.png' );
    final sprite4 = await textureLoader.fromAsset( 'assets/textures/sprites/snowflake4.png' );
    final sprite5 = await textureLoader.fromAsset( 'assets/textures/sprites/snowflake5.png' );

    for (int i = 0; i < 10000; i ++ ) {

      final x = math.Random().nextDouble() * 2000 - 1000;
      final y = math.Random().nextDouble() * 2000 - 1000;
      final z = math.Random().nextDouble() * 2000 - 1000;

      vertices.addAll([ x, y, z ]);
    }

    geometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( vertices, 3 ) );

    parameters = [
      [[ 1.0, 0.2, 0.5 ], sprite2, 20 ],
      [[ 0.95, 0.1, 0.5 ], sprite3, 15 ],
      [[ 0.90, 0.05, 0.5 ], sprite1, 10 ],
      [[ 0.85, 0.0, 0.5 ], sprite5, 8 ],
      [[ 0.80, 0.0, 0.5 ], sprite4, 5 ]
    ];

    for (int i = 0; i < parameters.length; i ++ ) {

      final color = parameters[ i ][ 0 ];
      final sprite = parameters[ i ][ 1 ];
      final size = parameters[ i ][ 2 ];

      materials.add(three.PointsMaterial.fromMap( { 'size': size, 'map': sprite, 'blending': three.AdditiveBlending, 'depthTest': false, 'transparent': true } ));
      materials[ i ].color.setHSL( color[0], color[1], color[2], three.ColorSpace.srgb );

      final particles = three.Points( geometry, materials[ i ] );

      particles.rotation.x = math.Random().nextDouble() * 6;
      particles.rotation.y = math.Random().nextDouble() * 6;
      particles.rotation.z = math.Random().nextDouble() * 6;

      threeJs.scene.add( particles );

    }

    threeJs.domElement.addEventListener(three.PeripheralType.pointerHover, onPointerMove);
    threeJs.addAnimationEvent((dt){
      render();
    });
  }

  void onPointerMove( event ) {
    if ( event.isPrimary == false ) return;
    mouse.x = event.clientX - windowHalfX;
    mouse.y = event.clientY - windowHalfY;
  }

  void render() {
    final time = DateTime.now().millisecondsSinceEpoch * 0.00005;

    threeJs.camera.position.x += ( mouse.x - threeJs.camera.position.x ) * 0.05;
    threeJs.camera.position.y += ( - mouse.y - threeJs.camera.position.y ) * 0.05;

    threeJs.camera.lookAt( threeJs.scene.position );

    for (int i = 0; i < threeJs.scene.children.length; i ++ ) {
      final object = threeJs.scene.children[ i ];
      if ( object is three.Points ) {
        object.rotation.y = time * ( i < 4 ? i + 1 : - ( i + 1 ) );
      }
    }

    for (int i = 0; i < materials.length; i ++ ) {
      final color = parameters[ i ][ 0 ];
      final h = ( 360 * ( color[ 0 ] + time ) % 360 ) / 360;
      materials[ i ].color.setHSL( h, color[ 1 ], color[ 2 ], three.ColorSpace.srgb );

    }
  }
}
