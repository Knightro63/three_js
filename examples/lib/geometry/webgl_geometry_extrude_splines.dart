import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:example/src/statistics.dart';
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_geometry/tube_geometry.dart';
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglGeometryExtrudeSplines extends StatefulWidget {
  
  const WebglGeometryExtrudeSplines({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglGeometryExtrudeSplines> {
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
  late three.OrbitControls controls;
  late CameraHelper cameraHelper;

  late three.Camera splineCamera;
  late three.Mesh cameraEye;

  final direction = three.Vector3();
  final binormal = three.Vector3();
  final normal = three.Vector3();
  final position = three.Vector3();
  final lookAt = three.Vector3();

  static final pipeSpline = three.CatmullRomCurve3( points:[
    three.Vector3( 0, 10, - 10 ), three.Vector3( 10, 0, - 10 ),
    three.Vector3( 20, 0, 0 ), three.Vector3( 30, 0, 10 ),
    three.Vector3( 30, 0, 20 ), three.Vector3( 20, 0, 30 ),
    three.Vector3( 10, 0, 30 ), three.Vector3( 0, 0, 30 ),
    three.Vector3( - 10, 10, 30 ), three.Vector3( - 10, 20, 30 ),
    three.Vector3( 0, 30, 30 ), three.Vector3( 10, 30, 30 ),
    three.Vector3( 20, 30, 15 ), three.Vector3( 10, 30, 10 ),
    three.Vector3( 0, 30, 10 ), three.Vector3( - 10, 20, 10 ),
    three.Vector3( - 10, 10, 10 ), three.Vector3( 0, 0, 10 ),
    three.Vector3( 10, - 10, 10 ), three.Vector3( 20, - 15, 10 ),
    three.Vector3( 30, - 15, 10 ), three.Vector3( 40, - 15, 10 ),
    three.Vector3( 50, - 15, 10 ), three.Vector3( 60, 0, 10 ),
    three.Vector3( 70, 0, 0 ), three.Vector3( 80, 0, 0 ),
    three.Vector3( 90, 0, 0 ), three.Vector3( 100, 0, 0 )
  ] );

  static final sampleClosedSpline = three.CatmullRomCurve3( points: [
    three.Vector3( 0, - 40, - 40 ),
    three.Vector3( 0, 40, - 40 ),
    three.Vector3( 0, 140, - 40 ),
    three.Vector3( 0, 40, 40 ),
    three.Vector3( 0, - 40, 40 )
  ] );

  // Keep a dictionary of Curve instances
  final splines = {
    'GrannyKnot': three.GrannyKnot(),
    'HeartCurve': three.HeartCurve( 3.5 ),
    'VivianiCurve': three.VivianiCurve( 70 ),
    'KnotCurve': three.KnotCurve(),
    'HelixCurve': three.HelixCurve(),
    'TrefoilKnot': three.TrefoilKnot(),
    'TorusKnot': three.TorusKnot( 20 ),
    'CinquefoilKnot': three.CinquefoilKnot( 20 ),
    'TrefoilPolynomialKnot': three.TrefoilPolynomialKnot( 14 ),
    'FigureEightPolynomialKnot': three.FigureEightPolynomialKnot(),
    'DecoratedTorusKnot4a': three.DecoratedTorusKnot4a(),
    'DecoratedTorusKnot4b': three.DecoratedTorusKnot4b(),
    'DecoratedTorusKnot5a': three.DecoratedTorusKnot5a(),
    'DecoratedTorusKnot5c': three.DecoratedTorusKnot5c(),
    'PipeSpline': pipeSpline,
    'SampleClosedSpline': sampleClosedSpline
  };

  late three.Object3D parent;
  late TubeGeometry tubeGeometry;
  three.Mesh? mesh;

  final Map<String,dynamic> params = {
    'spline': 'GrannyKnot',
    'scale': 4.0,
    'extrusionSegments': 100,
    'radiusSegments': 3,
    'closed': true,
    'animationView': false,
    'lookAhead': false,
    'cameraHelper': false,
  };

  final material = three.MeshLambertMaterial.fromMap( { 'color': 0xff00ff } );

  final wireframeMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0x000000, 'opacity': 0.3, 'wireframe': true, 'transparent': true } );

  void addTube() {
    if ( mesh != null ) {
      parent.remove( mesh! );
      mesh!.geometry?.dispose();
    }

    final extrudePath = splines[ params['spline'] ];
    tubeGeometry = TubeGeometry( extrudePath, params['extrusionSegments'], 2, params['radiusSegments'], params['closed'] );
    addGeometry( tubeGeometry );
    setScale();
  }

  void setScale() {
    mesh?.scale.setValues( params['scale'], params['scale'], params['scale'] );
  }


  void addGeometry( geometry ) {
    mesh = three.Mesh( geometry, material );
    final wireframe = three.Mesh( geometry, wireframeMaterial );
    mesh?.add( wireframe );
    parent.add( mesh );
  }

  void animateCamera() {
    cameraHelper.visible = params['cameraHelper'];
    cameraEye.visible = params['cameraHelper'];
  }

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width / threeJs.height, 0.01, 10000 );
    threeJs.camera.position.setValues( 0, 50, 500 );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xf0f0f0 );

    // light

    threeJs.scene.add( three.AmbientLight( 0xffffff ) );

    final light = three.DirectionalLight( 0xffffff, 1.5 );
    light.position.setValues( 0, 0, 1 );
    threeJs.scene.add( light );

    // tube

    parent = three.Object3D();
    threeJs.scene.add( parent );

    splineCamera = three.PerspectiveCamera( 84, threeJs.width / threeJs.height, 0.01, 1000 );
    parent.add( splineCamera );

    cameraHelper = CameraHelper( splineCamera );
    threeJs.scene.add( cameraHelper );

    addTube();

    // debug threeJs.camera

    cameraEye = three.Mesh( three.SphereGeometry( 5 ), three.MeshBasicMaterial.fromMap( { 'color': 0xdddddd } ) );
    parent.add( cameraEye );

    cameraHelper.visible = params['cameraHelper'];
    cameraEye.visible = params['cameraHelper'];


    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 100;
    controls.maxDistance = 2000;

    threeJs.addAnimationEvent((dt){
      render();
      controls.update();
    });
  }

  void render() {
    sampleClosedSpline.curveType = 'catmullrom';
    sampleClosedSpline.closed = true;
    // animate threeJs.camera along spline

    final time = DateTime.now().millisecondsSinceEpoch;
    const looptime = 20 * 1000;
    final t = ( time % looptime ) / looptime;

    tubeGeometry.parameters?['path'].getPointAt( t, position );
    position.scale( params['scale'] );

    // interpolation

    final segments = tubeGeometry.tangents.length;
    final pickt = t * segments;
    final pick = pickt.floor();
    final pickNext = ( pick + 1 ) % segments;

    binormal.sub2( tubeGeometry.binormals[ pickNext ], tubeGeometry.binormals[ pick ] );
    binormal.scale( pickt - pick ).add( tubeGeometry.binormals[ pick ] );

    tubeGeometry.parameters?['path'].getTangentAt( t, direction );
    const offset = 15;

    normal.setFrom( binormal ).cross( direction );

    // we move on a offset on its binormal

    position.add( normal.clone().scale( offset ) );

    splineCamera.position.setFrom( position );
    cameraEye.position.setFrom( position );

    // using arclength for stablization in look ahead

    tubeGeometry.parameters?['path'].getPointAt( ( t + 30 / tubeGeometry.parameters!['path'].getLength() ) % 1, lookAt );
    lookAt.scale( params['scale'] );

    // threeJs.camera orientation 2 - up orientation via normal

    if (!params['lookAhead']) lookAt.setFrom( position ).add( direction );
    splineCamera.matrix.lookAt( splineCamera.position, lookAt, normal );
    splineCamera.quaternion.setFromRotationMatrix( splineCamera.matrix );

    cameraHelper.update();

    //renderer.render( threeJs.scene, params.animationView == true ? splineCamera : threeJs.camera );
  }
}

