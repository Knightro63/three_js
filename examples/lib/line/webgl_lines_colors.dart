import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/geometry_utils.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLinesColors extends StatefulWidget {
  const WebglLinesColors({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglLinesColors> {
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

  double mouseX = 0;
  double mouseY = 0;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 33, threeJs.width / threeJs.height, 1, 10000 );
    threeJs.camera.position.z = 1000;

    threeJs.scene = three.Scene();

    final hilbertPoints = GeometryUtils.hilbert3D( three.Vector3( 0, 0, 0 ), 200.0, 1, 0, 1, 2, 3, 4, 5, 6, 7 );

    final geometry1 = three.BufferGeometry();
    final geometry2 = three.BufferGeometry();
    final geometry3 = three.BufferGeometry();

    const subdivisions = 6;

    List<double> vertices = [];
    List<double> colors1 = [];
    List<double> colors2 = [];
    List<double> colors3 = [];

    final point = three.Vector3();
    final color = three.Color();

    final spline = three.CatmullRomCurve3( points: hilbertPoints );

    for (int i = 0; i < hilbertPoints.length * subdivisions; i ++ ) {
      final t = i / ( hilbertPoints.length * subdivisions );
      spline.getPoint( t, point );

      vertices.addAll([ point.x, point.y, point.z ]);

      color.setHSL( 0.6, 1.0, math.max( 0, - point.x / 200 ) + 0.5, three.ColorSpace.srgb );
      colors1.addAll([ color.red, color.green, color.blue ]);

      color.setHSL( 0.9, 1.0, math.max( 0, - point.y / 200 ) + 0.5, three.ColorSpace.srgb );
      colors2.addAll([ color.red, color.green, color.blue ]);

      color.setHSL( i / ( hilbertPoints.length * subdivisions ), 1.0, 0.5, three.ColorSpace.srgb );
      colors3.addAll( [color.red, color.green, color.blue ]);
    }

    geometry1.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( vertices, 3 ) );
    geometry2.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( vertices, 3 ) );
    geometry3.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( vertices, 3 ) );

    geometry1.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors1, 3 ) );
    geometry2.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors2, 3 ) );
    geometry3.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors3, 3 ) );

    //

    final geometry4 = three.BufferGeometry();
    final geometry5 = three.BufferGeometry();
    final geometry6 = three.BufferGeometry();

    vertices = [];
    colors1 = [];
    colors2 = [];
    colors3 = [];

    for ( int i = 0; i < hilbertPoints.length; i ++ ) {
      final point = hilbertPoints[ i ];

      vertices.addAll([ point.x, point.y, point.z ]);

      color.setHSL( 0.6, 1.0, math.max( 0, ( 200 - hilbertPoints[ i ].x ) / 400 ) * 0.5 + 0.5, three.ColorSpace.srgb );
      colors1.addAll([ color.red, color.green, color.blue ]);

      color.setHSL( 0.3, 1.0, math.max( 0, ( 200 + hilbertPoints[ i ].x ) / 400 ) * 0.5, three.ColorSpace.srgb );
      colors2.addAll([ color.red, color.green, color.blue ]);

      color.setHSL( i / hilbertPoints.length, 1.0, 0.5, three.ColorSpace.srgb );
      colors3.addAll([ color.red, color.green, color.blue ]);

    }

    geometry4.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( vertices, 3 ) );
    geometry5.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( vertices, 3 ) );
    geometry6.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( vertices, 3 ) );

    geometry4.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors1, 3 ) );
    geometry5.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors2, 3 ) );
    geometry6.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors3, 3 ) );

    // Create lines and add to scene

    final material = three.LineBasicMaterial.fromMap( { 'color': 0xffffff, 'vertexColors': true } );

    three.Line line;
    List p;
    const scale = 0.3, d = 225;

    final parameters = [
      [ material, scale * 1.5, [ - d, - d / 2, 0 ], geometry1 ],
      [ material, scale * 1.5, [ 0, - d / 2, 0 ], geometry2 ],
      [ material, scale * 1.5, [ d, - d / 2, 0 ], geometry3 ],

      [ material, scale * 1.5, [ - d, d / 2, 0 ], geometry4 ],
      [ material, scale * 1.5, [ 0, d / 2, 0 ], geometry5 ],
      [ material, scale * 1.5, [ d, d / 2, 0 ], geometry6 ],
    ];

    for (int i = 0; i < parameters.length; i ++ ) {
      p = parameters[ i ];
      line = three.Line( p[ 3 ], p[ 0 ] );
      line.scale.x = line.scale.y = line.scale.z = p[ 1 ];
      line.position.x = p[ 2 ][ 0 ]*1.0;
      line.position.y = p[ 2 ][ 1 ]*1.0;
      line.position.z = p[ 2 ][ 2 ]*1.0;
      threeJs.scene.add( line );
    }

    threeJs.domElement.addEventListener( three.PeripheralType.pointermove, onPointerMove );


    threeJs.addAnimationEvent((dt){
      threeJs.camera.position.x += ( mouseX - threeJs.camera.position.x ) * 0.05;
      threeJs.camera.position.y += ( - mouseY + 200 - threeJs.camera.position.y ) * 0.05;

      threeJs.camera.lookAt( threeJs.scene.position );

      final time = DateTime.now().millisecondsSinceEpoch * 0.0005;

      for (int i = 0; i < threeJs.scene.children.length; i ++ ) {
        final object = threeJs.scene.children[ i ];
        if ( object is three.Line ) {
          object.rotation.y = time * ( i % 2 == 1? 1 : - 1 );
        }
      }
    });
  }

  void onPointerMove( event ) {
    if ( event.isPrimary == false ) return;
    mouseX = event.clientX - threeJs.width/2;
    mouseY = event.clientY - threeJs.height/2;
  }
}
