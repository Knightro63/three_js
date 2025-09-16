import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_ar/three_js_ar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThreeJsAr threeJsAR = ThreeJsAr();
  late Timer timer;
  three.ThreeJS? threeJs;
  bool loading = true;

  @override
  void initState() {
    threeJs ??= three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        alpha: true,
        clearAlpha: 0.0,
      )
    );
    threeJsAR.createTexture();
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs?.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            if (threeJsAR.textureId != null) Texture(textureId: threeJsAR.textureId!),
            if(threeJs != null)threeJs!.build(),
          ],
        ) 
      )
    );
  }

  Future<void> setup() async {
    threeJs!.renderer?.xr.enabled = true;
    threeJs!.scene = three.Scene();
    //threeJs!.scene.background = three.Color.fromHex32(0x000000);

    threeJs!.camera = three.PerspectiveCamera( 70, threeJs!.width / threeJs!.height, 0.01, 20 );
    threeJs!.camera.layers.enable( 1 );

    final light = three.HemisphereLight( 0xffffff, 0xbbbbff, 3 );
    light.position.setValues( 0.5, 1, 0.25 );
    threeJs!.scene.add( light );

    final geometry = three.CylinderGeometry( 0, 0.05, 0.2, 32 ).rotateX( math.pi / 2 );

    void onSelect(three.WebPointerEvent event) {
      final material = three.MeshPhongMaterial.fromMap( { 'color': (0xffffff * math.Random().nextDouble()).toInt() } );
      final mesh = three.Mesh( geometry, material );

      final cameraDirection = three.Vector3(0, 0, -1);
      cameraDirection.applyQuaternion(threeJs!.camera.quaternion);

      final atPoint = three.Vector3();
      atPoint.setFrom(threeJs!.camera.position).add(cameraDirection);

      threeJsAR.hitTest(event.clientX,event.clientY).then((onValue){
        final lookAtPoint = onValue == null?atPoint:three.Vector3().copyFromArray(onValue);

        mesh.position.setFrom(lookAtPoint);
        mesh.rotation.x = -math.pi/2;
        threeJs!.scene.add( mesh );
      });
    }

    threeJs!.addAnimationEvent((dt){
      threeJsAR.updateTexture();
    });

    threeJs!.domElement.addEventListener( three.PeripheralType.pointerdown, onSelect );

    threeJsAR.transform().listen((event) {
      threeJs!.camera.matrix.copyFromArray(event.matrix);
      threeJs!.camera.matrix.decompose(threeJs!.camera.position, threeJs!.camera.quaternion, threeJs!.camera.scale);
      threeJs!.camera.matrixWorldNeedsUpdate = true;
    });
  }
}
