import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_exporters/ply_exporter.dart';
import 'package:three_js_exporters/three_js_exporters.dart';
import 'package:three_js_helpers/three_js_helpers.dart';

class MiscExporterPly extends StatefulWidget {
  const MiscExporterPly({super.key});
  @override
  createState() => _State();
}

class _State extends State<MiscExporterPly> {
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
        useSourceTexture: true
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

  late final three.OrbitControls controls;
  late final three.Mesh mesh;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 4, 2, 4 );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xa0a0a0 );
    threeJs.scene.fog = three.Fog( 0xa0a0a0, 4, 20 );

    final hemiLight = three.HemisphereLight( 0xffffff, 0x444444, 1 );
    hemiLight.position.setValues( 0, 20, 0 );
    threeJs.scene.add( hemiLight );

    final directionalLight = three.DirectionalLight( 0xffffff, 1 );
    directionalLight.position.setValues( 0, 20, 10 );
    directionalLight.castShadow = true;
    directionalLight.shadow?.camera?.top = 2;
    directionalLight.shadow?.camera?.bottom = - 2;
    directionalLight.shadow?.camera?.left = - 2;
    directionalLight.shadow?.camera?.right = 2;
    threeJs.scene.add( directionalLight );

    // ground

    final ground = three.Mesh( three.PlaneGeometry( 40, 40 ), three.MeshPhongMaterial.fromMap( { 'color': 0xcbcbcb, 'depthWrite': false } ) );
    ground.rotation.x = - math.pi / 2;
    ground.receiveShadow = true;
    threeJs.scene.add( ground );

    final grid = GridHelper( 40, 20, 0x000000, 0x000000 );
    grid.material?.opacity = 0.2;
    grid.material?.transparent = true;
    threeJs.scene.add( grid );

    // export mesh

    final geometry = three.BoxGeometry();
    final material = three.MeshPhongMaterial.fromMap( { 'vertexColors': true } );

    // color vertices based on vertex positions
    final colors = (geometry.getAttributeFromString( 'position' ) as three.Float32BufferAttribute).array.sublist(0);
    for ( int i = 0, l = colors.length; i < l; i ++ ) {
      if ( colors[ i ] > 0 ){ 
        colors[ i ] = 0.5;
      }
      else{ 
        colors[ i ] = 0;
      }
    }

    geometry.setAttributeFromString( 'color', three.Float32BufferAttribute.fromList( colors, 3 ) );

    mesh = three.Mesh( geometry, material );
    mesh.castShadow = true;
    mesh.position.y = 0.5;
    threeJs.scene.add( mesh );

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.target.setValues( 0, 0.5, 0 );
    controls.update();

    final Map<String,dynamic> params = {
      'exportASCII': true,
      'exportBinaryBigEndian': true,
      'exportBinaryLittleEndian': true
    };


    final folder = gui.addFolder('GUI')..open();

    folder.addButton( params, 'exportASCII' ).onChange(( val ) {
      exportASCII();
    } );
    folder.addButton( params, 'exportBinaryBigEndian' ).onChange(( val ) {
      exportBinaryBigEndian();
    } );
    folder.addButton( params, 'exportBinaryLittleEndian' ).onChange(( val ) {
      exportBinaryLittleEndian();
    } );
  }

  void exportASCII() {
    PLYExporter.exportMesh('Export PLY (ASCII)',mesh);
  }

  void exportBinaryBigEndian() {
    PLYExporter.exportMesh('Export Binary (Big)' ,mesh, PLYOptions(littleEndian: false,type: ExportTypes.binary));
  }

  void exportBinaryLittleEndian() {
    PLYExporter.exportMesh('Export Binary (Little)' ,mesh, PLYOptions(littleEndian: true,type: ExportTypes.binary));
  }
}
