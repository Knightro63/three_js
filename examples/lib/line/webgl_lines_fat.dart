import 'dart:async';
import 'package:example/src/geometry_utils.dart';
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_line/three_js_line.dart';

class WebglLinesFat extends StatefulWidget {
  const WebglLinesFat({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglLinesFat> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  late Gui gui;

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

  late three.OrbitControls controls;
  late LineMaterial matLine;
  late Line2 line;
  late three.PerspectiveCamera camera2;

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 1000 );
    threeJs.camera.position.setValues( - 40, 0, 60 );

    camera2 = three.PerspectiveCamera( 40, 1, 1, 1000 );
    camera2.position.setFrom( threeJs.camera.position );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.enableDamping = true;
    controls.minDistance = 10;
    controls.maxDistance = 500;

    final List<double> positions = [];
    final List<double> colors = [];

    final List<three.Vector> points = GeometryUtils.hilbert3D( three.Vector3( 0, 0, 0 ), 20.0, 1, 0, 1, 2, 3, 4, 5, 6, 7 );

    final spline = three.CatmullRomCurve3( points: points );
    final divisions = ( 12 * points.length ).round();
    final point = three.Vector3();
    final color = three.Color();

    for (int i = 0, l = divisions; i < l; i ++ ) {

      final t = i / l;

      spline.getPoint( t, point );
      positions.addAll([ point.x, point.y, point.z ]);

      color.setHSL( t, 1.0, 0.5, three.ColorSpace.srgb );
      colors.addAll([ color.red, color.green, color.blue ]);

    }
    // Line2 ( LineGeometry, LineMaterial )

    final geometry = LineGeometry();
    geometry.setPositions(three.Float32Array.fromList(positions));
    geometry.setColors(three.Float32Array.fromList(colors));

    matLine = LineMaterial.fromMap( {
      'color': 0xffffff,
      'linewidth': 50, // in world units with size attenuation, pixels otherwise
      'vertexColors': true,
    } );
    matLine.alphaToCoverage = true;
    matLine.dashed = false;
    matLine.worldUnits = true;
    line = Line2( geometry, matLine );
    line.computeLineDistances();
    line.scale.setValues( 1, 1, 1 );
    threeJs.scene.add( line );

    // THREE.Line ( THREE.BufferGeometry, THREE.LineBasicMaterial ) - rendered with gl.LINE_STRIP

    final geo = three.BufferGeometry();
    geo.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( positions, 3 ) );
    geo.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors, 3 ) );

    matLineBasic = three.LineBasicMaterial.fromMap( { 'vertexColors': true } );
    matLineDashed = three.LineDashedMaterial.fromMap( { 'vertexColors': true, 'scale': 2, 'dashSize': 1, 'gapSize': 1 } );

    line1 = three.Line( geo, matLineBasic );
    line1.computeLineDistances();
    line1.visible = false;
    threeJs.scene.add( line1 );

    initGui();

    threeJs.postProcessor = ([double? dt]){
      threeJs.renderer!.setViewport(0,0,threeJs.width,threeJs.height);
      threeJs.renderer!.render(threeJs.scene,threeJs.camera );

      threeJs.renderer?.setScissorTest( true );
      threeJs.renderer?.setScissor( 20, 20, threeJs.width/4, threeJs.height/4 );
      threeJs.renderer?.setViewport( 20, 20, threeJs.width/4, threeJs.height/4 );

      camera2.position.setFrom( threeJs.camera.position );
      camera2.quaternion.setFrom( threeJs.camera.quaternion );
      //matLine.resolution.setValues( threeJs.width/4, threeJs.height/4 ); // resolution of the inset viewport
      threeJs.renderer?.render( threeJs.scene, camera2 );
      threeJs.renderer?.setScissorTest( false );
    };
  }

  late three.Line line1;
  late three.LineBasicMaterial matLineBasic;
  late three.LineBasicMaterial matLineDashed;

  void initGui() {
    final Map<String,dynamic> param = {
      'line type': 'LineGeometry',
      'world units': true,
      'width': 50.0,
      'alphaToCoverage': true,
      'dashed': false,
      'dash scale': 1.0,
      'dash / gap': '2 : 1'
    };

    final folder = gui.addFolder('GUI')..open();

    folder.addDropDown( param, 'line type', ['LineGeometry', 'gl.LINE'] ).onChange( ( val ) {
      switch ( val ) {
        case 'LineGeometry':
          line.visible = true;
          line1.visible = false;
          break;
        case 'gl.LINE':
          line.visible = false;
          line1.visible = true;
          break;
      }
    });

    folder.addButton( param, 'world units' ).onChange(( val ) {
      matLine.worldUnits = val;
      matLine.needsUpdate = true;
    } );

    folder.addSlider( param, 'width', 10.0, 100.0 ).onChange(( val ) {
      matLine.linewidth = val;
    });

    folder.addButton( param, 'alphaToCoverage' ).onChange(( val ) {
      matLine.alphaToCoverage = val;
    } );

    folder.addButton( param, 'dashed' ).onChange(( val ) {
      matLine.dashed = val;
      line1.material = val ? matLineDashed : matLineBasic;
    } );

    folder.addSlider( param, 'dash scale', 0.5, 2.0)..step(0.1)..onChange(( val ) {
      matLine.dashScale = val;
      matLineDashed.scale = val;
    } );

    folder.addDropDown( param, 'dash / gap', ['2 : 1', '1 : 1', '1 : 2'] ).onChange(( val ) {
      switch ( val ) {
        case '2 : 1':
          matLine.dashSize = 2;
          matLine.gapSize = 1;

          matLineDashed.dashSize = 2;
          matLineDashed.gapSize = 1;
          break;
        case '1 : 1':
          matLine.dashSize = 1;
          matLine.gapSize = 1;

          matLineDashed.dashSize = 1;
          matLineDashed.gapSize = 1;
          break;
        case '1 : 2':
          matLine.dashSize = 1;
          matLine.gapSize = 2;

          matLineDashed.dashSize = 1;
          matLineDashed.gapSize = 2;
          break;
      }
    } );
  }
}