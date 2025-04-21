import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_line/three_js_line.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        useOpenGL: true
      )
    );
    super.initState();
  }
  @override
  void dispose() {
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
        ],
      ) 
    );
  }

  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 1000 );
    threeJs.camera.position.setValues( - 40, 0, 60 );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 10;
    controls.maxDistance = 500;

    final matLine = LineMaterial.fromMap( {
      'linewidth': 5, // in world units with size attenuation, pixels otherwise
      'vertexColors': true,
    } );

    final matThresholdLine = LineMaterial.fromMap( {
      'linewidth': matLine.linewidth, // in world units with size attenuation, pixels otherwise
      // vertexColors: true,
      'transparent': true,
      'opacity': 0.2,
      'depthTest': false,
      'visible': false,
    } );

    final List<double> positions = [];
    final List<double> colors = [];
    final List<three.Vector3> points = [];

    for ( int i = - 50; i < 50; i ++ ) {
      final t = i / 3;
      points.add( three.Vector3( t * math.sin( 2 * t ), t, t * math.cos( 2 * t ) ) );
    }

    final spline = three.CatmullRomCurve3( points: points );
    final divisions = ( 3 * points.length ).round();
    final point = three.Vector3();
    final color = three.Color();

    for (int i = 0, l = divisions; i < l; i ++ ) {
      final t = i / l;

      spline.getPoint( t, point );
      positions.addAll( [point.x, point.y, point.z] );

      color.setHSL( t, 1.0, 0.5, three.ColorSpace.srgb );
      colors.addAll([ color.red, color.green, color.blue ]);
    }

    final lineGeometry = LineGeometry();
    lineGeometry.setPositions(three.Float32Array.fromList(positions));
    lineGeometry.setColors(three.Float32Array.fromList(colors));

    final segmentsGeometry = LineSegmentsGeometry();
    segmentsGeometry.setPositions(three.Float32Array.fromList(positions));
    segmentsGeometry.setColors(three.Float32Array.fromList(colors));

    final segments = LineSegments2( segmentsGeometry, matLine );
    segments.computeLineDistances();
    segments.scale.setValues( 1, 1, 1 );
    threeJs.scene.add( segments );
    segments.visible = false;

    final thresholdSegments = LineSegments2( segmentsGeometry, matThresholdLine );
    thresholdSegments.computeLineDistances();
    thresholdSegments.scale.setValues( 1, 1, 1 );
    threeJs.scene.add( thresholdSegments );
    thresholdSegments.visible = false;

    final line = Line2( lineGeometry, matLine );
    line.computeLineDistances();
    line.scale.setValues( 1, 1, 1 );
    threeJs.scene.add( line );

    final thresholdLine = Line2( lineGeometry, matThresholdLine );
    thresholdLine.computeLineDistances();
    thresholdLine.scale.setValues( 1, 1, 1 );
    threeJs.scene.add( thresholdLine );

    final geo = three.BufferGeometry();
    geo.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( positions, 3 ) );
    geo.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors, 3 ) );

    threeJs.addAnimationEvent((dt){
      thresholdLine.position.setFrom( line.position );
      thresholdLine.quaternion.setFrom( line.quaternion );
      thresholdSegments.position.setFrom( segments.position );
      thresholdSegments.quaternion.setFrom( segments.quaternion );
    });
  }
}
