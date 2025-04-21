import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';

import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglGeometryColors extends StatefulWidget {
  
  const WebglGeometryColors({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglGeometryColors> {
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
      settings: three.Settings(
        useOpenGL: true
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

  late three.OrbitControls controls;
  final objects = [], materials = [];

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(20, threeJs.width / threeJs.height, 1, 10000);
    threeJs.camera.position.z = 1800;
    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xffffff);

    final light = three.DirectionalLight(0xffffff);
    light.position.setValues(0, 0, 1);
    threeJs.scene.add(light);

    // shadow

    // final canvas = document.createElement( 'canvas' );
    // canvas.width = 128;
    // canvas.height = 128;

    // final context = canvas.getContext( '2d' );
    // final gradient = context.createRadialGradient( canvas.width / 2, canvas.height / 2, 0, canvas.width / 2, canvas.height / 2, canvas.width / 2 );
    // gradient.addColorStop( 0.1, 'rgba(210,210,210,1)' );
    // gradient.addColorStop( 1, 'rgba(255,255,255,1)' );

    // context.fillStyle = gradient;
    // context.fillRect( 0, 0, canvas.width, canvas.height );

    // final shadowTexture = new three.CanvasTexture( canvas );

    final shadowMaterial = three.MeshBasicMaterial({});
    final shadowGeo = three.PlaneGeometry(300, 300, 1, 1);

    three.Mesh shadowMesh;

    shadowMesh = three.Mesh(shadowGeo, shadowMaterial);
    shadowMesh.position.y = -250;
    shadowMesh.rotation.x = -math.pi / 2;
    threeJs.scene.add(shadowMesh);

    shadowMesh = three.Mesh(shadowGeo, shadowMaterial);
    shadowMesh.position.y = -250;
    shadowMesh.position.x = -400;
    shadowMesh.rotation.x = -math.pi / 2;
    threeJs.scene.add(shadowMesh);

    shadowMesh = three.Mesh(shadowGeo, shadowMaterial);
    shadowMesh.position.y = -250;
    shadowMesh.position.x = 400;
    shadowMesh.rotation.x = -math.pi / 2;
    threeJs.scene.add(shadowMesh);

    const radius = 200.0;

    final geometry1 = IcosahedronGeometry(radius, 1);

    final count = geometry1.attributes["position"].count;
    geometry1.setAttributeFromString('color', three.Float32BufferAttribute.fromList(Float32List(count * 3), 3));

    final geometry2 = geometry1.clone();
    final geometry3 = geometry1.clone();

    final color = three.Color(1, 1, 1);
    final positions1 = geometry1.attributes["position"];
    final positions2 = geometry2.attributes["position"];
    final positions3 = geometry3.attributes["position"];
    final colors1 = geometry1.attributes["color"];
    final colors2 = geometry2.attributes["color"];
    final colors3 = geometry3.attributes["color"];

    for (int i = 0; i < count; i++) {
      color.setHSL((positions1.getY(i) / radius + 1) / 2, 1.0, 0.5);
      colors1.setXYZ(i, color.red, color.green, color.blue);

      color.setHSL(0, (positions2.getY(i) / radius + 1) / 2, 0.5);
      colors2.setXYZ(i, color.red, color.green, color.blue);

      color.setRGB(1, 0.8 - (positions3.getY(i) / radius + 1) / 2, 0);
      colors3.setXYZ(i, color.red, color.green, color.blue);
    }

    final material = three.MeshPhongMaterial.fromMap({
      "color": 0xffffff,
      "flatShading": true,
      "vertexColors": true,
      "shininess": 0
    });

    final wireframeMaterial = three.MeshBasicMaterial.fromMap({"color": 0x000000, "wireframe": true, "transparent": true});

    three.Mesh mesh = three.Mesh(geometry1, material);
    three.Mesh wireframe = three.Mesh(geometry1, wireframeMaterial);
    mesh.add(wireframe);
    mesh.position.x = -400;
    mesh.rotation.x = -1.87;
    threeJs.scene.add(mesh);

    mesh = three.Mesh(geometry2, material);
    wireframe = three.Mesh(geometry2, wireframeMaterial);
    mesh.add(wireframe);
    mesh.position.x = 400;
    threeJs.scene.add(mesh);

    mesh = three.Mesh(geometry3, material);
    wireframe = three.Mesh(geometry3, wireframeMaterial);
    mesh.add(wireframe);
    threeJs.scene.add(mesh);

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }

  generateTexture() {
    final pixels = Uint8List(256 * 256 * 4);

    int x = 0, y = 0, l = pixels.length;

    for (int i = 0, j = 0; i < l; i += 4, j++) {
      x = j % 256;
      y = (x == 0) ? y + 1 : y;

      pixels[i] = 255;
      pixels[i + 1] = 255;
      pixels[i + 2] = 255;
      pixels[i + 3] = (x ^ y).floor();
    }

    return three.ImageElement(data: pixels, width: 256, height: 256);
  }

  void addMesh(three.BufferGeometry geometry, three.Material material) {
    final mesh = three.Mesh(geometry, material);

    mesh.position.x = (objects.length % 4) * 200 - 400;
    mesh.position.z = (objects.length / 4).floor() * 200 - 200;

    mesh.rotation.x = math.Random().nextDouble() * 200 - 100;
    mesh.rotation.y = math.Random().nextDouble() * 200 - 100;
    mesh.rotation.z = math.Random().nextDouble() * 200 - 100;

    objects.add(mesh);

    threeJs.scene.add(mesh);
  }
}
