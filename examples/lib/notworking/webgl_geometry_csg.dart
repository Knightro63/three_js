import 'dart:async';
import 'dart:math' as math;
import 'package:example/notworking/csg/evaluator.dart';
import 'package:example/src/gui.dart';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglGeometryCSG extends StatefulWidget {
  const WebglGeometryCSG({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglGeometryCSG> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late Gui gui;
  late three.ThreeJS threeJs;
  late three.Mesh brush;
  late three.Mesh baseBrush;

  @override
  void initState() {
    gui = Gui((){setState(() {});});
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
          Statistics(data: data),
          if(threeJs.mounted)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: gui.render(context)
            )
          )
        ],
      ) 
    );
  }

  late three.OrbitControls controls;
  late three.Mesh  wireframe;
  three.Mesh? result;

  final Map<String,dynamic> params = {
    'operation': 'subtract',
    'useGroups': true,
    'wireframe': false,
  };

  late three.Mesh core;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width / threeJs.height, 1, 100 );
    threeJs.camera.position.setValues( - 1, 1, 1 ).normalize().scale( 10 );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xfce4ec );

    // lights
    final ambient = three.HemisphereLight( 0xffffff, 0xbfd4d2, 0.5 );
    threeJs.scene.add( ambient );

    final directionalLight = three.DirectionalLight( 0xffffff, 0.3 );
    directionalLight.position.setValues( 1, 4, 3 ).scale( 3 );
    threeJs.scene.add( directionalLight );

    baseBrush = three.Mesh(
      IcosahedronGeometry( 2, 3 ),
      three.MeshStandardMaterial.fromMap( {
        //'color': 0xff0000,
        'flatShading': true,
        'polygonOffset': true,
        'polygonOffsetUnits': 1,
        'polygonOffsetFactor': 1,
        'side': three.DoubleSide,
        // 'opacity': 0.5,
        // 'transparent': true
      }),
    );

    //threeJs.scene.add(baseBrush);

    brush = three.Mesh(
      CylinderGeometry( 1, 1, 5, 45 ),
      three.MeshStandardMaterial.fromMap( {
        'color': 0x80cbc4,
        'polygonOffset': true,
        'polygonOffsetUnits': 1,
        'polygonOffsetFactor': 1,
        'side': three.DoubleSide,
        'opacity': 0.5,
        'transparent': true
      }),
    );

    //threeJs.scene.add(brush);

    // add shadow plane
    final plane = three.Mesh(
      three.PlaneGeometry(),
      three.ShadowMaterial.fromMap( {
        'color': 0xd81b60,
        'transparent': true,
        'opacity': 0.075,
        'side': three.DoubleSide,
      }),
    );
    plane.position.y = - 3;
    plane.rotation.x = - math.pi / 2;
    plane.scale.setScalar( 10 );
    plane.receiveShadow = true;
    threeJs.scene.add( plane );

    core = three.Mesh( 
      IcosahedronGeometry( 0.15, 1 ),
      three.MeshStandardMaterial.fromMap( {
        'flatShading': true,
        'color': 0xff9800,
        'emissive': 0xff9800,
        //'emissiveIntensity': 0.35,
        'polygonOffset': true,
        'polygonOffsetUnits': 1,
        'polygonOffsetFactor': 1,
      })..emissiveIntensity = 0.35,
    );
    threeJs.scene.add( core );

    // create wireframe
    wireframe = three.Mesh(
      null,
      three.MeshBasicMaterial.fromMap( { 'color': 0x009688, 'wireframe': true } ),
    );
    threeJs.scene.add( wireframe );

    // controls
    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 5;
    controls.maxDistance = 75;

    result = updateCSG();
    threeJs.scene.add( result );
    
    createGui();

    threeJs.addAnimationEvent((dt){
      animate();
    });
  }

	three.Mesh updateCSG() {
    return Evaluator.evaluate( baseBrush, brush, BooleanType.fromString(params['operation']), result)!;
  }

  void createGui(){
    final folder = gui.addFolder('GUI')..open();
    folder.addDropDown( params, 'operation', ['subtract', 'intersect', 'union'] );
    folder.addButton( params, 'wireframe' );
    folder.addButton( params, 'useGroups' );
  }

  void animate() {
    final t = DateTime.now().millisecondsSinceEpoch + 9000;

    baseBrush.rotation.x = t * 0.0001;
    baseBrush.rotation.y = t * 0.00025;
    baseBrush.rotation.z = t * 0.0005;
    baseBrush.updateMatrixWorld();

    brush.rotation.x = t * - 0.0002;
    brush.rotation.y = t * - 0.0005;
    brush.rotation.z = t * - 0.001;

    final s = 0.5 + 0.5 * ( 1 + math.sin( t * 0.001 ) );
    brush.scale.setValues( s, 1, s );
    brush.updateMatrixWorld();

    wireframe.geometry = result?.geometry;
    wireframe.visible = params['wireframe'];

    updateCSG();
  }
}
