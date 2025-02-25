import 'dart:async';
import 'dart:math' as math;
import 'package:three_js_bvh_csg/three_js_bvh_csg.dart';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglGeometryCSG2 extends StatefulWidget {
  const WebglGeometryCSG2({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglGeometryCSG2> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  late three.Mesh brush;
  late three.Mesh baseBrush;

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
          Statistics(data: data),
        ],
      ) 
    );
  }

  late three.OrbitControls controls;
  List<three.Mesh> results = [];

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
      three.SphereGeometry(1.2, 8, 8),
      three.MeshNormalMaterial(),
    );

    brush = three.Mesh(
      three.BoxGeometry(2, 2, 2),
      three.MeshNormalMaterial(),
    );

    // controls
    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 5;
    controls.maxDistance = 75;

    threeJs.addAnimationEvent((dt){
      animate();
    });
  }

	void updateCSG() {
    for (final result in results) {
      result.parent?.remove(result);
      result.geometry?.dispose();
    }
    results = [];

    baseBrush.updateMatrix();
    brush.updateMatrix();

    // ops with box as base mesh
    results.add(CSG.subtractMesh(baseBrush, brush));
    results.add(CSG.unionMesh(baseBrush, brush));
    results.add(CSG.intersectMesh(baseBrush, brush));
    // ops with sphere as base mesh
    results.add(CSG.subtractMesh(brush, baseBrush));
    results.add(CSG.unionMesh(brush, baseBrush));
    results.add(CSG.intersectMesh(brush, baseBrush));

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      threeJs.scene.add(result);

      result.position.z += -5 + (i % 3) * 5;
      result.position.x += -5 + ((i ~/ 3) | 0) * 10;
    }
  }

  void animate() {
    final t = DateTime.now().millisecondsSinceEpoch + 9000;
    baseBrush.position.x = math.sin(t * 0.001) * 2;
    baseBrush.position.z = math.cos(t * 0.0011) * 0.5;
    updateCSG();
  }
}
