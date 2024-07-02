import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglShadowmapPointlight extends StatefulWidget {
  
  const WebglShadowmapPointlight({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglShadowmapPointlight> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  GlobalKey key = GlobalKey();
  bool createdPng = false;

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
        enableShadowMap: true,
        shadowMapType: three.BasicShadowMap,
        localClippingEnabled: true,
        useSourceTexture: true,
      )
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
          Statistics(data: data)
        ],
      )
    );
  }

  late final three.Plane localPlane;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width/threeJs.height, 1, 1000 );
    threeJs.camera.position.setValues( 0, 10, 40 );

    threeJs.scene = three.Scene();
    threeJs.scene.add( three.AmbientLight( 0x111122, 3 ) );

    final test = await generateTexture();

    three.PointLight createLight(int color ) {
      const intensity = 1.0;

      final light = three.PointLight( color, intensity, 20);
      light.castShadow = true;
      light.shadow?.bias = - 0.005; // reduces self-shadowing on double-sided objects

      three.SphereGeometry geometry = three.SphereGeometry( 0.3, 12, 6 );
      three.Material material = three.MeshBasicMaterial.fromMap({'color': color});
      material.color.scale( intensity );
      three.Mesh sphere = three.Mesh( geometry, material );
      light.add( sphere );
      
      final texture = three.CanvasTexture(test);
      texture.magFilter = three.NearestFilter;
      texture.wrapT = three.RepeatWrapping;
      texture.wrapS = three.RepeatWrapping;
      texture.repeat.setValues( 1, 4.5 );

      geometry = three.SphereGeometry( 2, 32, 8 );
      material = three.MeshPhongMaterial.fromMap( {
        'side': three.DoubleSide,
        'alphaMap': texture,
        'alphaTest': 0.25
      });

      sphere = three.Mesh( geometry, material );
      sphere.castShadow = true;
      sphere.receiveShadow = true;
      light.add( sphere );

      return light;
    }

    final pointLight = createLight( 0x0088ff );
    threeJs.scene.add( pointLight );

    final pointLight2 = createLight( 0xff8888 );
    threeJs.scene.add( pointLight2 );

    localPlane = three.Plane(three.Vector3(0, 0, -14.9), 0.8);

    final geometry = three.BoxGeometry( 30,30,30 );
    final material = three.MeshPhongMaterial.fromMap( {
      'color': 0xa0adaf,
      'shininess': 10,
      'specular': 0x111111,
      'side': kIsWeb?three.BackSide:three.DoubleSide,
      "clippingPlanes": kIsWeb?null:[localPlane],
    } );

    final mesh = three.Mesh( geometry, material );
    mesh.position.y = 10;
    mesh.receiveShadow = true;
    threeJs.scene.add( mesh );

    threeJs.addAnimationEvent((dt){
      double time = DateTime.now().millisecondsSinceEpoch * 0.001;

      pointLight.position.x = math.sin( time * 0.6 ) * 9;
      pointLight.position.y = math.sin( time * 0.7 ) * 9 + 6;
      pointLight.position.z = math.sin( time * 0.8 ) * 9;

      pointLight.rotation.x = time;
      pointLight.rotation.z = time;

      time += 10000;

      pointLight2.position.x = math.sin( time * 0.6 ) * 9;
      pointLight2.position.y = math.sin( time * 0.7 ) * 9 + 6;
      pointLight2.position.z = math.sin( time * 0.8 ) * 9;

      pointLight2.rotation.x = time;
      pointLight2.rotation.z = time;
    });
  }

  Future<three.ImageElement> generateTexture() async{
    return three.ImageElement(
      width: 2,
      height: 2,
      data: three.Uint8Array.fromList([0,0,0,0,0,0,0,0,255,255,255,255,255,255,255,255])
    );
  }
}
