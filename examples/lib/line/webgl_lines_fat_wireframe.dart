import 'dart:async';
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_line/three_js_line.dart';

class WebglLinesFatWireframe extends StatefulWidget {
  const WebglLinesFatWireframe({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglLinesFatWireframe> {
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
      settings: three.Settings(
        useOpenGL: useOpenGL
      )
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
  late Wireframe wireframe;
  late three.LineSegments wireframe1;
  late three.LineBasicMaterial matLineBasic;
  late three.LineBasicMaterial matLineDashed;

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 1, 1000 );
    threeJs.camera.position.setValues( - 50, 0, 50 );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 10;
    controls.maxDistance = 500;

    final geo = IcosahedronGeometry( 20, 1 );
    final geometry = WireframeGeometry2( geo );

    matLine = LineMaterial.fromMap( {
      'color': 0x4080ff,
      'linewidth': 5, // in pixels
    });
    matLine.dashed = false;

    wireframe = Wireframe( geometry, matLine );
    wireframe.computeLineDistances();
    wireframe.scale.setValues( 1, 1, 1 );
    threeJs.scene.add( wireframe );

    final wfg = WireframeGeometry( geo );
    matLineBasic = three.LineBasicMaterial.fromMap( { 'color': 0x4080ff } );
    matLineDashed = three.LineDashedMaterial.fromMap( { 'scale': 2, 'dashSize': 1, 'gapSize': 1, 'color': 0x4080ff } );

    wireframe1 = three.LineSegments( wfg, matLineBasic );
    wireframe1.computeLineDistances();
    wireframe1.visible = false;
    threeJs.scene.add( wireframe1 );

    initGui();
  }

  void initGui() {
    final folder = gui.addFolder('GUI')..open();
    final param = {
      'line type': 'LineGeometry',
      'width (px)': 5.0,
      'dashed': false,
      'dash scale': 1.0,
      'dash / gap': '2 : 1'
    };

    folder.addDropDown( param, 'line type', ['LineGeometry', 'gl.LINE']).onChange(( val ) {
      switch ( val ) {
        case 'LineGeometry':
          wireframe.visible = true;
          wireframe1.visible = false;
          break;
        case 'gl.LINE':
          wireframe.visible = false;
          wireframe1.visible = true;
          break;
      }
    } );

    folder.addSlider( param, 'width (px)', 1, 10 ).onChange(( val ) {
      matLine.linewidth = val;
    } );

    folder.addButton( param, 'dashed' ).onChange(( val ) {
      matLine.dashed = val;
      if ( val ){ 
        matLine.defines!['USE_DASH'] = ''; 
      }
      else{
        matLine.defines?.remove('USE_DASH');
      }
      matLine.needsUpdate = true;

      wireframe1.material = val ? matLineDashed : matLineBasic;

    } );

    folder.addSlider( param, 'dash scale', 0.5, 1)..step( 0.1 )..onChange(( val ) {
      matLine.dashScale = val;
      matLineDashed.scale = val;
    } );

    folder.addDropDown( param, 'dash / gap', ['2 : 1', '1 : 1', '1 : 2']).onChange(( val ) {
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
    });
  }
}