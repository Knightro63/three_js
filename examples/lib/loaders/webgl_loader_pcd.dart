import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglLoaderPcd extends StatefulWidget {
  const WebglLoaderPcd({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglLoaderPcd> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late Gui wg;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    wg = Gui((){setState(() {});});
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
          Statistics(data: data),
          if(threeJs.mounted)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: wg.render(context)
            )
          )
        ],
      ) 
    );
  }

  Future<void> setup() async {
    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 30, threeJs.width / threeJs.height, 0.01, 40 );
    threeJs.camera.position.setValues( 0, 0, 1 );
    threeJs.scene.add( threeJs.camera );

    final controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 0.5;
    controls.maxDistance = 10;

    threeJs.scene.add( AxesHelper( 1 ) );
    final loader = three.PCDLoader();

    Map<String, dynamic> temp = {
      'size': 0.005,
      'color': 0,
      'name': 'binary/Zaghetto.pcd',
      'points': null
    };

    loadPointCloud( file ) async{
      final points = await loader.fromAsset( 'assets/models/pcd/$file');
      temp = {
        'size': points!.material!.size,
        'color': points.material!.color,
        'name': file,
        'points': points
      };

      points.geometry?.center();
      points.geometry?.rotateX( math.pi );
      points.name = file;
      threeJs.scene.add( points );
    }

    loadPointCloud( 'binary/Zaghetto.pcd' );

    final gui = wg.addFolder('GUI')..open();

    gui.addSlider( temp, 'size', 0.001, 0.011, 0.001 ).onChange((e){
      temp['points']?.material!.size = e;
    });
    gui.addColor( temp, 'color' ).onChange((e){
      temp['points']?.material!.color = three.Color.fromHex32(e);
    });
    gui.addDropDown( temp, 'name', <String>[
      'ascii/simple.pcd',
      'binary/Zaghetto.pcd',
      'binary/Zaghetto_8bit.pcd',
      'binary_compressed/pcl_logo.pcd',
    ])..name = 'type'..onChange( (e){
      threeJs.scene.remove( temp['points'] );
      loadPointCloud( e );
    });
  }
}
