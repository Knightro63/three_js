import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/demo.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglGeometryText extends StatefulWidget {
  final String fileName;
  const WebglGeometryText({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglGeometryText> {
  late Demo demo;

  @override
  void initState() {
    demo = Demo(
      fileName: widget.fileName,
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: DemoSettings(
        renderOptions: {
          "minFilter": three.LinearFilter,
          "magFilter": three.LinearFilter,
          "format": three.RGBAFormat,
          "samples": 4
        }
      ),
    );
    super.initState();
  }
  @override
  void dispose() {
    demo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return demo.threeDart();
  }

  late three.Group group;
  late three.GroupMaterial materials;

  Future<void> setup() async {
    // CAMERA

    demo.camera = three.PerspectiveCamera(30, demo.width / demo.height, 1, 1500);
    demo.camera.position.setValues(0, 400, 700);

    final cameraTarget = three.Vector3(0, 50, 0);
    demo.camera.lookAt(cameraTarget);

    // SCENE

    demo.scene = three.Scene();
    demo.scene.background = three.Color.fromHex32(0x000000);
    demo.scene.fog = three.Fog(three.Color.fromHex32(0x000000), 250, 1400);
    // LIGHTS

    final dirLight = three.DirectionalLight(0xffffff, 0.125);
    dirLight.position.setValues(0, 0, 1).normalize();
    demo.scene.add(dirLight);

    final pointLight = three.PointLight(0xffffff, 1.5);
    pointLight.position.setValues(0, 100, 90);
    demo.scene.add(pointLight);

    // Get text from hash

    pointLight.color!.setHSL(math.Random().nextDouble(), 1, 0.5);
    // hex = decimalToHex( pointLight.color!.getHex() );

    materials = three.GroupMaterial([
      three.MeshPhongMaterial.fromMap({"color": 0xffffff, "flatShading": true}), // front
      three.MeshPhongMaterial.fromMap({"color": 0xffffff}) // side
    ]);

    group = three.Group();

    // change size position fit mobile
    group.position.y = 50;
    group.scale.setValues(1, 1, 1);

    demo.scene.add(group);

    final font = await loadFont();

    createText(font);

    final plane = three.Mesh(
        three.PlaneGeometry(10000, 10000),
        three.MeshBasicMaterial.fromMap({"color": 0xffffff, "opacity": 0.5, "transparent": true}));
    plane.position.y = -100;
    plane.rotation.x = -math.pi / 2;
    demo.scene.add(plane);
  }

  Future<three.TYPRFont> loadFont() async {
    var loader = three.TYPRLoader();
    var font = await loader.fromAsset("assets/pingfang.ttf");
    loader.dispose();

    return font!;
  }

  void createText(font) {
    String text = "Three Dart";
    
    double fontHeight = 20,
      size = 70,
      hover = 30,
      bevelThickness = 2,
      bevelSize = 1.5;

    int curveSegments = 4;
    bool bevelEnabled = true;
    bool mirror = true;

    final textGeo = three.TextGeometry(text, three.TextGeometryOptions(
      font: font,
      size: size,
      depth: fontHeight,
      curveSegments: curveSegments,
      bevelThickness: bevelThickness,
      bevelSize: bevelSize,
      bevelEnabled: bevelEnabled
    ));

    textGeo.computeBoundingBox();

    final centerOffset =
        -0.5 * (textGeo.boundingBox!.max.x - textGeo.boundingBox!.min.x);

    final textMesh1 = three.Mesh(textGeo, materials);

    textMesh1.position.x = centerOffset;
    textMesh1.position.y = hover;
    textMesh1.position.z = 0;

    textMesh1.rotation.x = 0;
    textMesh1.rotation.y = math.pi * 2;

    group.add(textMesh1);

    if (mirror) {
      final textMesh2 = three.Mesh(textGeo, materials);

      textMesh2.position.x = centerOffset;
      textMesh2.position.y = -hover;
      textMesh2.position.z = demo.height;

      textMesh2.rotation.x = math.pi;
      textMesh2.rotation.y = math.pi * 2;

      group.add(textMesh2);
    }
  }
}
