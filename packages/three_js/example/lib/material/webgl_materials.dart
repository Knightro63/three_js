import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglMaterials extends StatefulWidget {
  final String fileName;
  const WebglMaterials({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglMaterials> {
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
    threeJs.dispose();
    controls.clearListeners();
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
  late three.PointLight pointLight;
  final objects = [], materials = [];

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 2000);
    threeJs.camera.position.setValues(0, 200, 800);
    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);
    threeJs.scene = three.Scene();

    // Grid

    final helper = GridHelper(1000, 40, three.Color.fromHex32(0x303030), three.Color.fromHex32(0x303030));
    helper.position.y = -75;
    threeJs.scene.add(helper);

    // Materials

    final texture = three.DataTexture(generateTexture().data, 256, 256, null,
        null, null, null, null, null, null, null, null);
    texture.needsUpdate = true;

    materials.add(
        three.MeshLambertMaterial.fromMap({"map": texture, "transparent": true}));
    materials.add(three.MeshLambertMaterial.fromMap({"color": 0xdddddd}));
    materials.add(three.MeshPhongMaterial.fromMap({
      "color": 0xdddddd,
      "specular": 0x009900,
      "shininess": 30,
      "flatShading": true
    }));
    materials.add(three.MeshNormalMaterial());
    materials.add(three.MeshBasicMaterial.fromMap({
      "color": 0xffaa00,
      "transparent": true,
      "blending": three.AdditiveBlending
    }));
    materials.add(three.MeshLambertMaterial.fromMap({"color": 0xdddddd}));
    materials.add(three.MeshPhongMaterial.fromMap({
      "color": 0xdddddd,
      "specular": 0x009900,
      "shininess": 30,
      "map": texture,
      "transparent": true
    }));
    materials.add(three.MeshNormalMaterial.fromMap({"flatShading": true}));
    materials.add(
        three.MeshBasicMaterial.fromMap({"color": 0xffaa00, "wireframe": true}));
    materials.add(three.MeshDepthMaterial());
    materials.add(three.MeshLambertMaterial.fromMap({"color": 0x666666, "emissive": 0xff0000}));
    materials.add(three.MeshPhongMaterial.fromMap({
      "color": 0x000000,
      "specular": 0x666666,
      "emissive": 0xff0000,
      "shininess": 10,
      "opacity": 0.9,
      "transparent": true
    }));
    materials.add(
        three.MeshBasicMaterial.fromMap({"map": texture, "transparent": true}));

    // Spheres geometry

    final geometry = three.SphereGeometry(70, 32, 16);

    for (int i = 0, l = materials.length; i < l; i++) {
      addMesh(geometry, materials[i]);
    }

    // Lights

    threeJs.scene.add(three.AmbientLight(0x111111, 1));

    final directionalLight = three.DirectionalLight(0xffffff, 0.125);

    directionalLight.position.x = math.Random().nextDouble() - 0.5;
    directionalLight.position.y = math.Random().nextDouble() - 0.5;
    directionalLight.position.z = math.Random().nextDouble() - 0.5;
    directionalLight.position.normalize();

    threeJs.scene.add(directionalLight);

    pointLight = three.PointLight(0xffffff, 1);
    threeJs.scene.add(pointLight);

    pointLight.add(three.Mesh(three.SphereGeometry(4, 8, 8),
        three.MeshBasicMaterial.fromMap({"color": 0xffffff})));

    threeJs.addAnimationEvent((dt){
      controls.update();
      animate(dt);
    });
  }

  generateTexture() {
    final pixels = Uint8Array(256 * 256 * 4);

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

  addMesh(geometry, material) {
    final mesh = three.Mesh(geometry, material);

    mesh.position.x = (objects.length % 4) * 200 - 400;
    mesh.position.z = (objects.length / 4).floor() * 200 - 200;

    mesh.rotation.x = math.Random().nextDouble() * 200 - 100;
    mesh.rotation.y = math.Random().nextDouble() * 200 - 100;
    mesh.rotation.z = math.Random().nextDouble() * 200 - 100;

    objects.add(mesh);

    threeJs.scene.add(mesh);
  }

  void animate(double dt) {
    final timer = 0.0001 * DateTime.now().millisecondsSinceEpoch;

    threeJs.camera.position.x = math.cos(timer) * 1000;
    threeJs.camera.position.z = math.sin(timer) * 1000;

    threeJs.camera.lookAt(threeJs.scene.position);

    for (int i = 0, l = objects.length; i < l; i++) {
      final object = objects[i];

      object.rotation.x += 0.01;
      object.rotation.y += 0.005;
    }

    materials[materials.length - 2]
        .emissive
        .setHSL(0.54, 1.0, 0.35 * (0.5 + 0.5 * math.sin(35 * timer)));
    materials[materials.length - 3]
        .emissive
        .setHSL(0.04, 1.0, 0.35 * (0.5 + 0.5 * math.cos(35 * timer)));

    pointLight.position.x = math.sin(timer * 7) * 300;
    pointLight.position.y = math.cos(timer * 5) * 400;
    pointLight.position.z = math.cos(timer * 3) * 300;
  }
}
