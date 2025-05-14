import 'dart:async';
import 'package:example/src/geometry_utils.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLinesDashed extends StatefulWidget {
  const WebglLinesDashed({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglLinesDashed> {
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

  final List<three.Line> objects = [];

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 60, threeJs.width / threeJs.height, 1, 200 );
    threeJs.camera.position.z = 150;

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x111111 );
    threeJs.scene.fog = three.Fog( 0x111111, 150, 200 );

    const subdivisions = 6;
    const recursion = 1;

    final points = GeometryUtils.hilbert3D( three.Vector3( 0, 0, 0 ), 25.0, recursion, 0, 1, 2, 3, 4, 5, 6, 7 );
    final spline = three.CatmullRomCurve3(points: points );

    final samples = spline.getPoints( points.length * subdivisions );
    final geometrySpline = three.BufferGeometry().setFromPoints( samples );

    final line = three.Line( geometrySpline, three.LineDashedMaterial.fromMap( { 'color': 0xffffff, 'dashSize': 1, 'gapSize': 0.5 } ) );
    line.computeLineDistances();

    objects.add( line );
    threeJs.scene.add( line );

    final geometryBox = box( 50, 50, 50 );

    final lineSegments = three.LineSegments( geometryBox, three.LineDashedMaterial.fromMap( { 'color': 0xffaa00, 'dashSize': 3, 'gapSize': 1 } ) );
    lineSegments.computeLineDistances();

    objects.add( lineSegments );
    threeJs.scene.add( lineSegments );

    threeJs.addAnimationEvent((dt){
      final time = DateTime.now().millisecondsSinceEpoch * 0.001;

      threeJs.scene.traverse( ( object ) {
        if ( object is three.Line ) {
          object.rotation.x = 0.25 * time;
          object.rotation.y = 0.25 * time;
        }
      });
    });
  }

  three.BufferGeometry box(double width,double height,double depth ) {
    width = width * 0.5;
    height = height * 0.5;
    depth = depth * 0.5;

    final geometry = three.BufferGeometry();
    final List<double> position = [];

    position.addAll([
      - width, - height, - depth,
      - width, height, - depth,

      - width, height, - depth,
      width, height, - depth,

      width, height, - depth,
      width, - height, - depth,

      width, - height, - depth,
      - width, - height, - depth,

      - width, - height, depth,
      - width, height, depth,

      - width, height, depth,
      width, height, depth,

      width, height, depth,
      width, - height, depth,

      width, - height, depth,
      - width, - height, depth,

      - width, - height, - depth,
      - width, - height, depth,

      - width, height, - depth,
      - width, height, depth,

      width, height, - depth,
      width, height, depth,

      width, - height, - depth,
      width, - height, depth
    ]);

    geometry.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( position, 3 ) );
    return geometry;
  }
}
