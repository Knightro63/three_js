import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglGeometryNurbs extends StatefulWidget {
  const WebglGeometryNurbs({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglGeometryNurbs> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  late final three.OrbitControls controls;

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
    controls.dispose();
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

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width / threeJs.height, 1, 2000 );
    threeJs.camera.position.setValues( 0, 150, 750 );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xf0f0f0 );

    threeJs.scene.add( three.AmbientLight( 0xffffff ) );

    final light = three.DirectionalLight( 0xffffff, 0.3 );
    light.position.setValues( 1, 1, 1 );
    threeJs.scene.add( light );

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    final group = three.Group();
    group.position.y = 50;
    threeJs.scene.add( group );

    // NURBS curve

    final List<three.Vector> nurbsControlPoints = [];
    final List<double> nurbsKnots = [];
    const nurbsDegree = 3;

    for (int i = 0; i <= nurbsDegree; i ++ ) {
      nurbsKnots.add( 0 );
    }

    for (int i = 0, j = 20; i < j; i ++ ) {
      nurbsControlPoints.add(
        three.Vector4(
          math.Random().nextDouble() * 400 - 200,
          math.Random().nextDouble() * 400,
          math.Random().nextDouble() * 400 - 200,
          1 // weight of control point: higher means stronger attraction
        )
      );

      final knot = ( i + 1 ) / ( j - nurbsDegree );
      nurbsKnots.add( three.MathUtils.clamp( knot, 0, 1 ) );
    }

    final nurbsCurve = three.NURBSCurve( nurbsDegree, nurbsKnots, nurbsControlPoints );

    final nurbsGeometry = three.BufferGeometry();
    nurbsGeometry.setFromPoints( nurbsCurve.getPoints( 200 ) );

    final nurbsMaterial = three.LineBasicMaterial.fromMap( { 'color': 0x333333 } );

    final nurbsLine = three.Line( nurbsGeometry, nurbsMaterial );
    nurbsLine.position.setValues( 200, - 100, 0 );
    group.add( nurbsLine );

    final nurbsControlPointsGeometry = three.BufferGeometry();
    nurbsControlPointsGeometry.setFromPoints( nurbsCurve.controlPoints );

    final nurbsControlPointsMaterial = three.LineBasicMaterial.fromMap( { 'color': 0x333333, 'opacity': 0.25, 'transparent': true } );

    final nurbsControlPointsLine = three.Line( nurbsControlPointsGeometry, nurbsControlPointsMaterial );
    nurbsControlPointsLine.position.setFrom( nurbsLine.position );
    group.add( nurbsControlPointsLine );

    // NURBS surface

    final List<List<three.Vector4>> nsControlPoints = [
      [
        three.Vector4( - 200, - 200, 100, 1 ),
        three.Vector4( - 200, - 100, - 200, 1 ),
        three.Vector4( - 200, 100, 250, 1 ),
        three.Vector4( - 200, 200, - 100, 1 )
      ],
      [
        three.Vector4( 0, - 200, 0, 1 ),
        three.Vector4( 0, - 100, - 100, 5 ),
        three.Vector4( 0, 100, 150, 5 ),
        three.Vector4( 0, 200, 0, 1 )
      ],
      [
        three.Vector4( 200, - 200, - 100, 1 ),
        three.Vector4( 200, - 100, 200, 1 ),
        three.Vector4( 200, 100, - 250, 1 ),
        three.Vector4( 200, 200, 100, 1 )
      ]
    ];

    const degree1 = 2;
    const degree2 = 3;
    const List<double> knots1 = [ 0, 0, 0, 1, 1, 1 ];
    const List<double> knots2 = [ 0, 0, 0, 0, 1, 1, 1, 1 ];
    final nurbsSurface = three.NURBSSurface( degree1, degree2, knots1, knots2, nsControlPoints );

    //final map = (await three.TextureLoader(flipY: true).fromNetwork(Uri.parse("https://storage.googleapis.com/cms-storage-bucket/a9d6ce81aee44ae017ee.png")))!;
    final map = (await three.TextureLoader().fromAsset( 'assets/textures/uv_grid_opengl.jpg' ))!;
    map.wrapS = map.wrapT = three.RepeatWrapping;
    map.anisotropy = 16;
    map.colorSpace = three.SRGBColorSpace;

    getSurfacePoint( u, v, target ) {
      return nurbsSurface.getPoint( u, v, target );
    }

    final geometry = ParametricGeometry( getSurfacePoint, 20, 20 );
    final material = three.MeshLambertMaterial.fromMap( { 'map': map, 'side': three.DoubleSide } );
    final object = three.Mesh( geometry, material );
    object.position.setValues( - 200, 100, 0 );
    object.scale.scale( 1 );
    group.add( object );

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
