import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_advanced_exporters/three_js_advanced_exporters.dart';
import 'package:three_js_helpers/three_js_helpers.dart';

class MiscExporterUSDZ extends StatefulWidget {
  const MiscExporterUSDZ({super.key});
  @override
  createState() => _State();
}

class _State extends State<MiscExporterUSDZ> {
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

  late final three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera =three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.25, 20 );
    threeJs.camera.position.setValues( - 2.5, 0.6, 3.0 );

    final pmremGenerator = three.PMREMGenerator( threeJs.renderer! );

    threeJs.scene =three.Scene();
    threeJs.scene.background =three.Color.fromHex32( 0xf0f0f0 );
    threeJs.scene.environment = pmremGenerator.fromScene( RoomEnvironment(), sigma: 0.04 ).texture;

    final loader = three.GLTFLoader().setPath( 'assets/models/gltf/DamagedHelmet/glTF/' );
    final gltf = await loader.fromAsset( 'DamagedHelmet.gltf');

    threeJs.scene.add( gltf?.scene );
    
    final shadowMesh = createSpotShadowMesh();
    shadowMesh.position.y = - 1.1;
    shadowMesh.position.z = - 0.25;
    shadowMesh.scale.setScalar( 2 );
    threeJs.scene.add( shadowMesh );

    // USDZ
    final exporter = USDZExporter();

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 2;
    controls.maxDistance = 10;
    controls.target.setValues( 0, - 0.15, - 0.2 );
    controls.update();

    final Map<String,dynamic> params = {
      'exportUSDZ': true
    };

    final folder2 = gui.addFolder('Export')..open();
    folder2.addButton( params, 'exportUSDZ' ).onChange(( val ) {
      exporter.exportScene('TEST', threeJs.scene);
    });
  }

  three.Mesh createSpotShadowMesh() {
    final geometry = three.PlaneGeometry();
    final material = three.MeshBasicMaterial.fromMap( {
      'blending': three.MultiplyBlending, 
      'toneMapped': false
    } );

    final mesh = three.Mesh( geometry, material );
    mesh.rotation.x = - math.pi / 2;

    return mesh;
  }

}
