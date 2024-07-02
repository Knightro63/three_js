import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglClippingIntersection extends StatefulWidget {
  
  const WebglClippingIntersection({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglClippingIntersection> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        localClippingEnabled: true
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    controls.dispose();
    threeJs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: threeJs.build()
    );
  }

  late three.OrbitControls controls;

  Future<void> setup() async {
    Map<String, dynamic> params = {
      "clipIntersection": true,
      "planeConstant": 0,
      "showHelpers": false
    };

    final clipPlanes = [
      three.Plane(three.Vector3(1, 0, 0), 0),
      three.Plane(three.Vector3(0, -1, 0), 0),
      three.Plane(three.Vector3(0, 0, -1), 0)
    ];

    threeJs.scene = three.Scene();
    threeJs.camera = three.PerspectiveCamera(40, threeJs.width / threeJs.height, 1, 200);
    threeJs.camera.position.setValues(-1.5, 2.5, 3.0);
    threeJs.camera.lookAt(threeJs.scene.position);

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    final light = three.HemisphereLight(0xffffff, 0x080808, 1.5);
    light.position.setValues(-1.25, 1, 1.25);
    threeJs.scene.add(light);

    final group = three.Group();

    for (int i = 1; i <= 30; i += 2) {
      final geometry = three.SphereGeometry(i / 30, 48, 24);

      final material = three.MeshLambertMaterial.fromMap({
        "color": three.Color(0, 0, 0).setHSL(math.Random().nextDouble(), 0.5, 0.5),
        "side": three.DoubleSide,
        "clippingPlanes": clipPlanes,
        "clipIntersection": params["clipIntersection"]
      });

      group.add(three.Mesh(geometry, material));
    }

    threeJs.scene.add(group);

    final helpers = three.Group();
    helpers.add(PlaneHelper(clipPlanes[0], 2, 0xff0000));
    helpers.add(PlaneHelper(clipPlanes[1], 2, 0x00ff00));
    helpers.add(PlaneHelper(clipPlanes[2], 2, 0x0000ff));
    helpers.visible = params["showHelpers"]!;
    threeJs.scene.add(helpers);

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }
}
