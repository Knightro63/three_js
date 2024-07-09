import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'dart:async';
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

  late three.OrbitControls controls;
  late Brush baseBrush, brush, core;
  late Evaluator evaluator;
  late three.Mesh  wireframe;
  dynamic result;

  final Map<String,dynamic> params = {
    'operation': SUBTRACTION,
    'useGroups': true,
    'wireframe': false,
  };

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 50, threeJs.width / threeJs.height, 1, 100 );
    threeJs.camera.position.setValues( - 1, 1, 1 ).normalize().scale( 10 );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0xfce4ec );

    // lights
    final ambient = three.HemisphereLight( 0xffffff, 0xbfd4d2, 3 );
    threeJs.scene.add( ambient );

    final directionalLight = three.DirectionalLight( 0xffffff, 0.3 );
    directionalLight.position.setValues( 1, 4, 3 ).scale( 3 );
    directionalLight.castShadow = true;
    directionalLight.shadow?.mapSize.setScalar( 2048 );
    directionalLight.shadow?.bias = - 1e-4;
    directionalLight.shadow?.normalBias = 1e-4;
    threeJs.scene.add( directionalLight );

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

    // create brushes
    evaluator = Evaluator();

    baseBrush = Brush(
      IcosahedronGeometry( 2, 3 ),
      three.MeshStandardMaterial.fromMap( {
        'flatShading': true,
        'polygonOffset': true,
        'polygonOffsetUnits': 1,
        'polygonOffsetFactor': 1,
      }),
    );

    brush = Brush(
      CylinderGeometry( 1, 1, 5, 45 ),
      three.MeshStandardMaterial.fromMap( {
        'color': 0x80cbc4,
        'polygonOffset': true,
        'polygonOffsetUnits': 1,
        'polygonOffsetFactor': 1,
      }),
    );

    core = Brush( 
      IcosahedronGeometry( 0.15, 1 ),
      three.MeshStandardMaterial.fromMap( {
        'flatShading': true,
        'color': 0xff9800,
        'emissive': 0xff9800,
        'emissiveIntensity': 0.35,
        'polygonOffset': true,
        'polygonOffsetUnits': 1,
        'polygonOffsetFactor': 1,
      }),
    );
    core.castShadow = true;
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

  }

	void updateCSG() {
    evaluator.useGroups = params['useGroups'];
    result = evaluator.evaluate( baseBrush, brush, params['operation'], result );

    result.castShadow = true;
    result.receiveShadow = true;
    threeJs.scene.add( result );

    threeJs.addAnimationEvent((dt){
      animate();
    });
  }

  void animate() {
    // update the transforms
    final t = DateTime.now().millisecondsSinceEpoch + 9000;
    baseBrush.rotation.x = t * 0.0001;
    baseBrush.rotation.y = t * 0.00025;
    baseBrush.rotation.z = t * 0.0005;
    baseBrush.updateMatrixWorld();

    brush.rotation.x = t * - 0.0002;
    brush.rotation.y = t * - 0.0005;
    brush.rotation.z = t * - 0.001;

    final s = 0.5 + 0.5 * ( 1 + math.sin( t * 0.001 ) );
    brush.scale.set( s, 1, s );
    brush.updateMatrixWorld();

    // update the csg
    updateCSG();

    wireframe.geometry = result.geometry;
    wireframe.visible = params['wireframe'];
  }
}
