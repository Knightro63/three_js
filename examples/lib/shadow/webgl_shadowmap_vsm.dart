import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglShadowmapVsm extends StatefulWidget {
  
  const WebglShadowmapVsm({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglShadowmapVsm> {
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
    controls.dispose();
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
          Statistics(data: data)
        ],
      ) 
    );
  }

  late three.OrbitControls controls ;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width/threeJs.height, 1, 1000 );
    threeJs.camera.position.setValues( 0, 10, 30 );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x222244 );
    threeJs.scene.fog = three.Fog( 0x222244, 50, 100 );

    threeJs.scene.add( three.AmbientLight( 0x444444,0.4) );

    final spotLight = three.SpotLight( 0xff3333, 10 );
    spotLight.angle = math.pi / 5;
    spotLight.penumbra = 0.3;
    spotLight.position.setValues( 8, 10, 5 );
    spotLight.castShadow = true;
    spotLight.shadow?.camera?.near = 8;
    spotLight.shadow?.camera?.far = 200;
    spotLight.shadow?.mapSize.width = 256;
    spotLight.shadow?.mapSize.height = 256;
    spotLight.shadow?.bias = - 0.002;
    spotLight.shadow?.radius = 4;
    threeJs.scene.add( spotLight );

    final dirLight = three.DirectionalLight( 0x3333ff, 0.8 );
    dirLight.position.setValues( 3, 12, 17 );
    dirLight.castShadow = true;
    dirLight.shadow?.camera?.near = 0.1;
    dirLight.shadow?.camera?.far = 500;
    dirLight.shadow?.camera?.right = 17;
    dirLight.shadow?.camera?.left = - 17;
    dirLight.shadow?.camera?.top	= 17;
    dirLight.shadow?.camera?.bottom = - 17;
    dirLight.shadow?.mapSize.width = 512;
    dirLight.shadow?.mapSize.height = 512;
    dirLight.shadow?.radius = 4;
    dirLight.shadow?.bias = - 0.005;

    final dirGroup = three.Group();
    dirGroup.add( dirLight );
    threeJs.scene.add( dirGroup );

    // Geometry

    final geometry = TorusKnotGeometry( 25, 8, 75, 20 );
    final material = three.MeshPhongMaterial.fromMap( {
      'color': 0x999999,
      'shininess': 0,
      'specular': 0x222222
    } );

    final torusKnot = three.Mesh( geometry, material );
    torusKnot.scale.scale( 1 / 18 );
    torusKnot.position.y = 3;
    torusKnot.castShadow = true;
    torusKnot.receiveShadow = true;
    threeJs.scene.add( torusKnot );

    final cylinderGeometry = CylinderGeometry( 0.75, 0.75, 7, 32 );

    final pillar1 = three.Mesh( cylinderGeometry, material );
    pillar1.position.setValues( 8, 3.5, 8 );
    pillar1.castShadow = true;
    pillar1.receiveShadow = true;

    final pillar2 = pillar1.clone();
    pillar2.position.setValues( 8, 3.5, - 8 );
    final pillar3 = pillar1.clone();
    pillar3.position.setValues( - 8, 3.5, 8 );
    final pillar4 = pillar1.clone();
    pillar4.position.setValues( - 8, 3.5, - 8 );

    threeJs.scene.add( pillar1 );
    threeJs.scene.add( pillar2 );
    threeJs.scene.add( pillar3 );
    threeJs.scene.add( pillar4 );

    final planeGeometry = three.PlaneGeometry( 200, 200 );
    final planeMaterial = three.MeshPhongMaterial.fromMap( {
      'color': 0x999999,
      'shininess': 0,
      'specular': 0x111111
    } );

    final ground = three.Mesh( planeGeometry, planeMaterial );
    ground.rotation.x = - math.pi / 2;
    ground.scale.scale( 3 );
    ground.castShadow = true;
    ground.receiveShadow = true;
    threeJs.scene.add( ground );

    threeJs.renderer?.shadowMap.type = three.VSMShadowMap;

    // Mouse control
    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.target.setValues( 0, 2, 0 );
    

    threeJs.addAnimationEvent((delta){
      final time = DateTime.now().millisecondsSinceEpoch;
      controls.update();

      torusKnot.rotation.x += 0.25 * delta;
      torusKnot.rotation.y += 0.5 * delta;
      torusKnot.rotation.z += 1 * delta;

      dirGroup.rotation.y += 0.7 * delta;
      dirLight.position.z = 17 + math.sin( time * 0.001 ) * 5;
    });
  }
}
