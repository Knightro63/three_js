import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglMorphtargets extends StatefulWidget {
  final String fileName;
  const WebglMorphtargets({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglMorphtargets> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup
    );
    super.initState();
  }
  @override
  void dispose() {
    controls.dispose();
    threeJs.dispose();
    three.loading.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: threeJs.build()
    );
  }

  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0x8FBCD4);

    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 20);
    threeJs.camera.position.z = 10;
    threeJs.scene.add(threeJs.camera);

    threeJs.camera.lookAt(threeJs.scene.position);
    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);
    threeJs.scene.add(three.AmbientLight(0x8FBCD4, 0.4));

    final pointLight = three.PointLight(0xffffff, 1);
    threeJs.camera.add(pointLight);

    final geometry = createGeometry();

    final material = three.MeshPhongMaterial.fromMap({"color": 0xff0000, "flatShading": true});

    final mesh = three.Mesh(geometry, material);
    threeJs.scene.add(mesh);

    controls.enableZoom = false;

    threeJs.addAnimationEvent((dt){
      controls.update();
      num t = (DateTime.now().millisecondsSinceEpoch * 0.0005);

      final v0 = (math.sin(t) + 1.0) / 2.0;
      final v1 = (math.sin(t + 0.3) + 1.0) / 2.0;

      mesh.morphTargetInfluences![0] = v0;
      mesh.morphTargetInfluences![1] = v1;
    });
  }

  three.BoxGeometry createGeometry() {
    final geometry = three.BoxGeometry(2, 2, 2, 32, 32, 32);

    // create an empty array to  hold targets for the attribute we want to morph
    // morphing positions and normals is supported
    geometry.morphAttributes["position"] = [];

    // the original positions of the cube's vertices
    final positionAttribute = geometry.attributes["position"];

    // for the first morph target we'll move the cube's vertices onto the surface of a sphere
    List<double> spherePositions = [];

    // for the second morph target, we'll twist the cubes vertices
    List<double> twistPositions = [];
    final direction = three.Vector3(1, 0, 0);
    final vertex = three.Vector3();

    for (int i = 0; i < positionAttribute.count; i++) {
      final x = positionAttribute.getX(i);
      final y = positionAttribute.getY(i);
      final z = positionAttribute.getZ(i);

      spherePositions.addAll([
        x * math.sqrt( 1 - (y * y / 2) - (z * z / 2) + (y * y * z * z / 3)),
        y * math.sqrt( 1 - (z * z / 2) - (x * x / 2) + (z * z * x * x / 3)),
        z * math.sqrt(1 - (x * x / 2) - (y * y / 2) + (x * x * y * y / 3))
      ]);

      // stretch along the x-axis so we can see the twist better
      vertex.setValues(x * 2, y, z);

      vertex.applyAxisAngle(direction, math.pi * x / 2).copyIntoArray(twistPositions, twistPositions.length);
    }

    // add the spherical positions as the first morph target
    // geometry.morphAttributes["position"][ 0 ] = new three.Float32BufferAttribute( spherePositions, 3 );
    geometry.morphAttributes["position"]!.add(three.Float32BufferAttribute.fromList(spherePositions, 3));

    // add the twisted positions as the second morph target
    geometry.morphAttributes["position"]!.add(three.Float32BufferAttribute.fromList(twistPositions, 3));

    return geometry;
  }
}
