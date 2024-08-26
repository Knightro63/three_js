import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_line/three_js_line.dart';

class WebglLinesFatRaycasting extends StatefulWidget {
  const WebglLinesFatRaycasting({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglLinesFatRaycasting> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  late Gui gui;
  late three.OrbitControls controls;

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
    gui = Gui((){setState(() {});});
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
          Statistics(data: data),
          if(threeJs.mounted)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: gui.render()
            )
          )  
        ],
      ) 
    );
  }

  late LineMaterial matLine;
  late LineMaterial matThresholdLine;

  final raycaster = three.Raycaster();

  late three.Mesh sphereInter;
  late three.Mesh sphereOnLine;
  late LineSegments2 segments;
  late LineSegments2 thresholdSegments;
  late Line2 line;
  late Line2 thresholdLine;

  final three.Vector2 pointer = three.Vector2();

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 1000 );
    threeJs.camera.position.setValues( - 40, 0, 60 );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 10;
    controls.maxDistance = 500;

    matLine = LineMaterial.fromMap( {
      'color': 0xffffff,
      'linewidth': 1, // in world units with size attenuation, pixels otherwise
      'vertexColors': true,
    } );
    matLine.worldUnits = true;
    matLine.alphaToCoverage = true;

    matThresholdLine = LineMaterial.fromMap( {
      'color': 0xffffff,
      'linewidth': matLine.linewidth, // in world units with size attenuation, pixels otherwise
      // vertexColors: true,
      'transparent': true,
      'opacity': 0.2,
      'depthTest': false,
      'visible': false,
    } );
    matThresholdLine.worldUnits = true;

    final sphereGeometry = three.SphereGeometry( 0.25, 8, 4 );
    final sphereInterMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0xff0000, 'depthTest': false } );
    final sphereOnLineMaterial = three.MeshBasicMaterial.fromMap( { 'color': 0x00ff00, 'depthTest': false } );

    sphereInter = three.Mesh( sphereGeometry, sphereInterMaterial );
    sphereOnLine = three.Mesh( sphereGeometry, sphereOnLineMaterial );
    sphereInter.visible = false;
    sphereOnLine.visible = false;
    sphereInter.renderOrder = 10;
    sphereOnLine.renderOrder = 10;
    threeJs.scene.add( sphereInter );
    threeJs.scene.add( sphereOnLine );

    // Position and THREE.Color Data

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

    segments = LineSegments2( segmentsGeometry, matLine );
    segments.computeLineDistances();
    segments.scale.setValues( 1, 1, 1 );
    threeJs.scene.add( segments );
    segments.visible = false;

    thresholdSegments = LineSegments2( segmentsGeometry, matThresholdLine );
    thresholdSegments.computeLineDistances();
    thresholdSegments.scale.setValues( 1, 1, 1 );
    threeJs.scene.add( thresholdSegments );
    thresholdSegments.visible = false;

    line = Line2( lineGeometry, matLine );
    line.computeLineDistances();
    line.scale.setValues( 1, 1, 1 );
    threeJs.scene.add( line );

    thresholdLine = Line2( lineGeometry, matThresholdLine );
    thresholdLine.computeLineDistances();
    thresholdLine.scale.setValues( 1, 1, 1 );
    threeJs.scene.add( thresholdLine );

    final geo = three.BufferGeometry();
    geo.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( positions, 3 ) );
    geo.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors, 3 ) );

    initGui();

    threeJs.domElement.addEventListener(three.PeripheralType.pointerHover, onPointerMove );

    threeJs.addAnimationEvent((dt){
      final obj = line.visible ? line : segments;
      thresholdLine.position.setFrom( line.position );
      thresholdLine.quaternion.setFrom( line.quaternion );
      thresholdSegments.position.setFrom( segments.position );
      thresholdSegments.quaternion.setFrom( segments.quaternion );

      if ( !threeJs.pause ) {
        line.rotation.y += dt * 0.1;
        segments.rotation.y = line.rotation.y;
      }

      raycaster.setFromCamera( pointer, threeJs.camera );

      final intersects = raycaster.intersectObject( obj, false );

      if ( intersects.length > 0 ) {

        sphereInter.visible = true;
        sphereOnLine.visible = true;

        sphereInter.position.setFrom( intersects[ 0 ].point! );
        sphereOnLine.position.setFrom( (intersects[ 0 ] as LineIntersection).pointOnLine! );

        final index = intersects[ 0 ].faceIndex;
        final colors = obj.geometry?.getAttributeFromString( 'instanceColorStart' );

        color.fromBuffer( colors, index! );

        sphereInter.material?.color?..setFrom( color )..offsetHSL( 0.3, 0, 0 );
        sphereOnLine.material?.color?..setFrom( color )..offsetHSL( 0.7, 0, 0 );
      } 
      else {
        sphereInter.visible = false;
        sphereOnLine.visible = false;
      }
    });
  }

  void onPointerMove( event ) {
    pointer.x = ( event.clientX / threeJs.width ) * 2 - 1;
    pointer.y = - ( event.clientY / threeJs.height ) * 2 + 1;
  }

  void initGui() {
    print(raycaster.params['Line2']);
    final params = {
      'line type': 'LineSegmentsGeometry',
      'world units': matLine.worldUnits,
      'visualize threshold': matThresholdLine.visible,
      'width': matLine.linewidth,
      'alphaToCoverage': matLine.alphaToCoverage,
      'threshold': raycaster.params['Line2']?.threshold ?? 0.0,
      'translation': raycaster.params['Line2']?.threshold ?? 0.0,
      'animate': !threeJs.pause
    };

    final folder = gui.addFolder('GUI')..open();

    folder.addDropDown( params, 'line type', ['LineGeometry', 'LineSegmentsGeometry']).onChange(( val ) {
			switch ( val ) {
        case 'LineGeometry':
          line.visible = true;
          thresholdLine.visible = true;
          segments.visible = false;
          thresholdSegments.visible = false;
          break;
        case 'LineSegmentsGeometry':
          line.visible = false;
          thresholdLine.visible = false;
          segments.visible = true;
          thresholdSegments.visible = true;
          break;
      }
    });

    folder.addButton( params, 'world units' ).onChange(( val ) {
      matLine.worldUnits = val;
      matLine.needsUpdate = true;

      matThresholdLine.worldUnits = val;
      matThresholdLine.needsUpdate = true;
    } );

    folder.addButton( params, 'visualize threshold' ).onChange(( val ) {
      matThresholdLine.visible = val;
    } );

    folder.addSlider( params, 'width', 1, 10 ).onChange(( val ) {
      matLine.linewidth = val;
      matThresholdLine.linewidth = matLine.linewidth! + raycaster.params['Line2'].threshold;
    } );

    folder.addButton( params, 'alphaToCoverage' ).onChange(( val ) {
      matLine.alphaToCoverage = val;
    } );

    folder.addSlider( params, 'threshold', 0, 10 ).onChange(( val ) {
      raycaster.params['Line2'].threshold = val;
      matThresholdLine.linewidth = matLine.linewidth! + raycaster.params['Line2'].threshold;
    } );

    folder.addSlider( params, 'translation', 0, 10 ).onChange(( val ) {
      line.position.x = val;
      segments.position.x = val;
    } );

    folder.addButton( params, 'animate' )..onChange((val){
      threeJs.pause = !val;
    });
  }
}