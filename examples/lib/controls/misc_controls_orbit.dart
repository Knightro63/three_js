import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class MiscControlsOrbit extends StatefulWidget {
  
  const MiscControlsOrbit({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MiscControlsOrbit> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  bool usePerspective = true;

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
        renderOptions: {
          "minFilter": three.LinearFilter,
          "magFilter": three.LinearFilter,
          "format": three.RGBAFormat,
          "samples": 4
        }
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    controls.dispose();
    timer.cancel();
    threeJs.dispose();
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

  late three.Mesh mesh;
  late three.OrbitControls controls;

  void setup() {
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xcccccc);
    threeJs.scene.fog = three.FogExp2(0xcccccc, 0.002);

    if(usePerspective){
      threeJs.camera = three.PerspectiveCamera(60, threeJs.width / threeJs.height, 1, 1000);
    }
    else{
      int frustumSize = 600;
      double aspect = 1.0;
      threeJs.camera = three.OrthographicCamera(
          0.5 * frustumSize * aspect / -2,
          0.5 * frustumSize * aspect / 2,
          frustumSize / 2,
          frustumSize / -2,
          150,
          1000);
    }
    threeJs.camera.position.setValues(400, 200, 0);

    // controls

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);
    // controls.listenToKeyEvents( window );

    //controls.addEventListener( 'change', render ); // call this only in static scenes (i.e., if there is no animation loop)

    controls.enableDamping =true; // an animation loop is required when either damping or auto-rotation are enabled
    controls.dampingFactor = 0.05;
    controls.screenSpacePanning = false;
    controls.minDistance = 100;
    controls.maxDistance = 500;

    controls.maxPolarAngle = 0;//math.pi / 2;

    // world

    final geometry = CylinderGeometry(0, 10, 30, 4, 1);
    final material =
        three.MeshPhongMaterial.fromMap({"color": 0xffffff, "flatShading": true});

    for (int i = 0; i < 500; i++) {
      final mesh = three.Mesh(geometry, material);
      mesh.position.x = math.Random().nextDouble() * 1600 - 800;
      mesh.position.y = 0;
      mesh.position.z = math.Random().nextDouble() * 1600 - 800;
      mesh.updateMatrix();
      mesh.matrixAutoUpdate = false;
      threeJs.scene.add(mesh);
    }

    final dirLight1 = three.DirectionalLight(0xffffff);
    dirLight1.position.setValues(1, 1, 1);
    threeJs.scene.add(dirLight1);

    final dirLight2 = three.DirectionalLight(0x002288);
    dirLight2.position.setValues(-1, -1, -1);
    threeJs.scene.add(dirLight2);

    final ambientLight = three.AmbientLight(0x222222);
    threeJs.scene.add(ambientLight);

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
