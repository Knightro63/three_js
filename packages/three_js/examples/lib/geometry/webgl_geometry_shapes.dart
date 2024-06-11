import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglGeometryShapes extends StatefulWidget {
  final String fileName;
  const WebglGeometryShapes({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglGeometryShapes> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup,
      // settings: three.Settings(
      //     renderOptions: {
      //     "minFilter": three.LinearFilter,
      //     "magFilter": three.LinearFilter,
      //     "format": three.RGBAFormat,
      //     "samples": 4
      //   }
      // )
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
  
  late three.Group group;
  late three.Texture texture;
  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(0xffffff);
    threeJs.camera = three.PerspectiveCamera(50, threeJs.width / threeJs.height, 1, 1000);
    // let camra far
    threeJs.camera.position.setValues(0, 150, 500);
    threeJs.scene.add(threeJs.camera);

    final light = three.PointLight(0xffffff,0.8,0,0);
    threeJs.camera.add(light);

    group = three.Group();
    group.position.y = 50;
    threeJs.scene.add(group);

    final loader = three.TextureLoader();
    texture = (await loader.fromAsset("assets/textures/uv_grid_opengl.jpg"))!;

    // it's necessary to apply these settings in order to correctly display the texture on a shape geometry

    texture.wrapS = texture.wrapT = three.RepeatWrapping;
    texture.repeat.setValues(0.008, 0.008);

    // California

    List<three.Vector2> californiaPts = [];

    californiaPts.add(three.Vector2(610, 320));
    californiaPts.add(three.Vector2(450, 300));
    californiaPts.add(three.Vector2(392, 392));
    californiaPts.add(three.Vector2(266, 438));
    californiaPts.add(three.Vector2(190, 570));
    californiaPts.add(three.Vector2(190, 600));
    californiaPts.add(three.Vector2(160, 620));
    californiaPts.add(three.Vector2(160, 650));
    californiaPts.add(three.Vector2(180, 640));
    californiaPts.add(three.Vector2(165, 680));
    californiaPts.add(three.Vector2(150, 670));
    californiaPts.add(three.Vector2(90, 737));
    californiaPts.add(three.Vector2(80, 795));
    californiaPts.add(three.Vector2(50, 835));
    californiaPts.add(three.Vector2(64, 870));
    californiaPts.add(three.Vector2(60, 945));
    californiaPts.add(three.Vector2(300, 945));
    californiaPts.add(three.Vector2(300, 743));
    californiaPts.add(three.Vector2(600, 473));
    californiaPts.add(three.Vector2(626, 425));
    californiaPts.add(three.Vector2(600, 370));
    californiaPts.add(three.Vector2(610, 320));

    for (int i = 0; i < californiaPts.length; i++) {
      californiaPts[i].scale(0.25);
    }

    final californiaShape = three.Shape(californiaPts);

    // Triangle

    final triangleShape = three.Shape(null)
        .moveTo(80.0, 20.0)
        .lineTo(40.0, 80.0)
        .lineTo(120.0, 80.0)
        .lineTo(80.0, 20.0); // close path

    // Heart

    double x = 0, y = 0;

    final heartShape =
        three.Shape(null) // From http://blog.burlock.org/html5/130-paths
            .moveTo(x + 25, y + 25)
            .bezierCurveTo(x + 25, y + 25, x + 20, y, x, y)
            .bezierCurveTo(x - 30, y, x - 30, y + 35, x - 30, y + 35)
            .bezierCurveTo(x - 30, y + 55, x - 10, y + 77, x + 25, y + 95)
            .bezierCurveTo(x + 60, y + 77, x + 80, y + 55, x + 80, y + 35)
            .bezierCurveTo(x + 80, y + 35, x + 80, y, x + 50, y)
            .bezierCurveTo(x + 35, y, x + 25, y + 25, x + 25, y + 25);

    // Square

    double sqLength = 80;

    final squareShape = three.Shape(null)
        .moveTo(0.0, 0.0)
        .lineTo(0.0, sqLength)
        .lineTo(sqLength, sqLength)
        .lineTo(sqLength, 0.0)
        .lineTo(0.0, 0.0);

    // Rounded rectangle

    final roundedRectShape = three.Shape(null);

    roundedRect(ctx, double x, double y, num width, num height, num radius) {
      ctx.moveTo(x, y + radius);
      ctx.lineTo(x, y + height - radius);
      ctx.quadraticCurveTo(x, y + height, x + radius, y + height);
      ctx.lineTo(x + width - radius, y + height);
      ctx.quadraticCurveTo(
          x + width, y + height, x + width, y + height - radius);
      ctx.lineTo(x + width, y + radius);
      ctx.quadraticCurveTo(x + width, y, x + width - radius, y);
      ctx.lineTo(x + radius, y);
      ctx.quadraticCurveTo(x, y, x, y + radius);
    }
    roundedRect(roundedRectShape, 0, 0, 50, 50, 20);

    // Track

    final trackShape = three.Shape()
        .moveTo(40.0, 40.0)
        .lineTo(40.0, 160.0)
        .absarc(60.0, 160.0, 20.0, math.pi, 0.0, true)
        .lineTo(80, 40)
        .absarc(60, 40, 20, 2 * math.pi, math.pi, true);

    // Circle

    double circleRadius = 40;
    final circleShape = three.Shape()
        .moveTo(0, circleRadius)
        .quadraticCurveTo(circleRadius, circleRadius, circleRadius, 0)
        .quadraticCurveTo(circleRadius, -circleRadius, 0, -circleRadius)
        .quadraticCurveTo(-circleRadius, -circleRadius, -circleRadius, 0)
        .quadraticCurveTo(-circleRadius, circleRadius, 0, circleRadius);

    // Fish

    final fishShape = three.Shape()
        .moveTo(x, y)
        .quadraticCurveTo(x + 50, y - 80, x + 90, y - 10)
        .quadraticCurveTo(x + 100, y - 10, x + 115, y - 40)
        .quadraticCurveTo(x + 115, y, x + 115, y + 40)
        .quadraticCurveTo(x + 100, y + 10, x + 90, y + 10)
        .quadraticCurveTo(x + 50, y + 80, x, y);

    // Arc circle

    final arcShape = three.Shape()
        .moveTo(50, 10)
        .absarc(10, 10, 40, 0, math.pi * 2, false);

    final holePath = three.Path()
        .moveTo(20, 10)
        .absarc(10, 10, 10, 0, math.pi * 2, true);

    arcShape.holes.add(holePath);

    // Smiley

    final smileyShape = three.Shape()
        .moveTo(80, 40)
        .absarc(40, 40, 40, 0, math.pi * 2, false);

    final smileyEye1Path = three.Path()
        .moveTo(35, 20)
        .absellipse(25, 20, 10, 10, 0, math.pi * 2, true, null);

    final smileyEye2Path = three.Path()
        .moveTo(65, 20)
        .absarc(55, 20, 10, 0, math.pi * 2, true);

    final smileyMouthPath = three.Path()
        .moveTo(20, 40)
        .quadraticCurveTo(40, 60, 60, 40)
        .bezierCurveTo(70, 45, 70, 50, 60, 60)
        .quadraticCurveTo(40, 80, 20, 60)
        .quadraticCurveTo(5, 50, 20, 40);

    smileyShape.holes.add(smileyEye1Path);
    smileyShape.holes.add(smileyEye2Path);
    smileyShape.holes.add(smileyMouthPath);

    // Spline shape

    List<three.Vector2> splinepts = [];
    splinepts.add(three.Vector2(70, 20));
    splinepts.add(three.Vector2(80, 90));
    splinepts.add(three.Vector2(-30, 70));
    splinepts.add(three.Vector2(0, 0));

    final splineShape = three.Shape(null).moveTo(0, 0).splineThru(splinepts);

    three.ExtrudeGeometryOptions extrudeSettings = three.ExtrudeGeometryOptions(
      depth: 8,
      bevelEnabled: true,
      bevelSegments: 2,
      steps: 2,
      bevelSize: 1,
      bevelThickness: 1
    );

    // addShape( shape, color, x, y, z, rx, ry,rz, s );

    addShape(
        californiaShape, extrudeSettings, 0xf08000, -300, -100, 0, 0, 0, 0, 1);
    addShape(triangleShape, extrudeSettings, 0x8080f0, -180, 0, 0, 0, 0, 0, 1);
    addShape(
        roundedRectShape, extrudeSettings, 0x008000, -150, 150, 0, 0, 0, 0, 1);
    addShape(trackShape, extrudeSettings, 0x008080, 200, -100, 0, 0, 0, 0, 1);
    addShape(squareShape, extrudeSettings, 0x0040f0, 150, 100, 0, 0, 0, 0, 1);
    addShape(heartShape, extrudeSettings, 0xf00000, 60, 100, 0, 0, 0,
        math.pi, 1);
    addShape(circleShape, extrudeSettings, 0x00f000, 120, 250, 0, 0, 0, 0, 1);
    addShape(fishShape, extrudeSettings, 0x404040, -60, 200, 0, 0, 0, 0, 1);
    addShape(smileyShape, extrudeSettings, 0xf000f0, -200, 250, 0, 0, 0,
        math.pi, 1);
    addShape(arcShape, extrudeSettings, 0x804000, 150, 0, 0, 0, 0, 0, 1);
    addShape(splineShape, extrudeSettings, 0x808080, -50, -100, 0, 0, 0, 0, 1);

    addLineShape(arcShape.holes[0], 0x804000, 150, 0, 0, 0, 0, 0, 1);

    for (int i = 0; i < smileyShape.holes.length; i += 1) {
      addLineShape(
          smileyShape.holes[i], 0xf000f0, -200, 250, 0, 0, 0, math.pi, 1);
    }

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }

  void addShape(shape, three.ExtrudeGeometryOptions extrudeSettings, color, double x, double y, double z, double rx, double ry, double rz, double s) {
    // flat shape with texture
    // note: default UVs generated by three.ShapeGeometry are simply the x- and y-coordinates of the vertices

    ShapeGeometry geometry = ShapeGeometry([shape]);

    three.Mesh mesh = three.Mesh(geometry, three.MeshPhongMaterial.fromMap({"side": three.DoubleSide, "map": texture}));
    mesh.position.setValues(x, y, z - 175.0);
    mesh.rotation.set(rx, ry, rz);
    mesh.scale.setValues(s, s, s);
    group.add(mesh);

    // flat shape

    geometry = ShapeGeometry([shape]);

    mesh = three.Mesh(geometry, three.MeshPhongMaterial.fromMap({"color": color, "side": three.DoubleSide}));
    mesh.position.setValues(x, y, z - 125.0);
    mesh.rotation.set(rx, ry, rz);
    mesh.scale.setValues(s, s, s);
    group.add(mesh);

    // extruded shape

    final geometry2 = three.ExtrudeGeometry([shape], extrudeSettings);

    mesh = three.Mesh(
        geometry2, three.MeshPhongMaterial.fromMap({"color": color}));
    mesh.position.setValues(x, y, z - 75.0);
    mesh.rotation.set(rx, ry, rz);
    mesh.scale.setValues(s, s, s);
    group.add(mesh);

    addLineShape(shape, color, x, y, z, rx, ry, rz, s);
  }

  void addLineShape(shape, color, double x, double y, double z, double rx, double ry, double rz, double s) {
    // lines

    shape.autoClose = true;

    final points = shape.getPoints();
    final spacedPoints = shape.getSpacedPoints(50);

    final geometryPoints = three.BufferGeometry().setFromPoints(points);
    final geometrySpacedPoints =
        three.BufferGeometry().setFromPoints(spacedPoints);

    // solid line

    three.Line line = three.Line(
        geometryPoints, three.LineBasicMaterial.fromMap({"color": color}));
    line.position.setValues(x, y, z - 25);
    line.rotation.set(rx, ry, rz);
    line.scale.setValues(s, s, s);
    group.add(line);

    // line from equidistance sampled points

    line = three.Line(
        geometrySpacedPoints, three.LineBasicMaterial.fromMap({"color": color}));
    line.position.setValues(x, y, z + 25);
    line.rotation.set(rx, ry, rz);
    line.scale.setValues(s, s, s);
    group.add(line);

    // vertices from real points

    three.Points particles = three.Points(geometryPoints, three.PointsMaterial.fromMap({"color": color, "size": 4}));
    particles.position.setValues(x, y, z + 75);
    particles.rotation.set(rx, ry, rz);
    particles.scale.setValues(s, s, s);
    group.add(particles);

    // equidistance sampled points

    particles = three.Points(geometrySpacedPoints,
        three.PointsMaterial.fromMap({"color": color, "size": 4}));
    particles.position.setValues(x, y, z + 125);
    particles.rotation.set(rx, ry, rz);
    particles.scale.setValues(s, s, s);
    group.add(particles);
  }
}
