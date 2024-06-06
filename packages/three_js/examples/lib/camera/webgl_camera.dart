import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglCamera extends StatefulWidget {
  final String fileName;
  const WebglCamera({super.key, required this.fileName});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<WebglCamera> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup,
      postProcessor: postProcessor,
      settings: three.Settings(renderOptions: {
        "minFilter": three.LinearFilter,
        "magFilter": three.LinearFilter,
        "format": three.RGBAFormat,
        "samples": 4
      })
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    threeJs.renderer!.setScissor( 0, 0, threeJs.width , threeJs.height);
    super.dispose();
  }
  late three.Mesh mesh;

  late three.Camera cameraPerspective;
  late three.Camera cameraOrtho;

  late three.Group cameraRig;

  late three.Camera activeCamera;
  late CameraHelper activeHelper;

  late CameraHelper cameraOrthoHelper;
  late CameraHelper cameraPerspectiveHelper;

  double randFloatSpread(double range) {
    return range * (0.5 - math.Random().nextDouble());
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

  void postProcessor([double? dt]) {
    final r = DateTime.now().millisecondsSinceEpoch * 0.0005;

    mesh.position.x = 700 * math.cos(r);
    mesh.position.z = 700 * math.sin(r);
    mesh.position.y = 700 * math.sin(r);

    mesh.children[0].position.x = 70 * math.cos(2 * r);
    mesh.children[0].position.z = 70 * math.sin(r);

    if (activeCamera == cameraPerspective) {
      cameraPerspective.fov = 35 + 30 * math.sin(0.5 * r);
      cameraPerspective.far = mesh.position.length;
      cameraPerspective.updateProjectionMatrix();

      cameraPerspectiveHelper.update();
      cameraPerspectiveHelper.visible = true;

      cameraOrthoHelper.visible = false;
    } 
    else {
      cameraOrtho.far = mesh.position.length;
      cameraOrtho.updateProjectionMatrix();

      cameraOrthoHelper.update();
      cameraOrthoHelper.visible = true;

      cameraPerspectiveHelper.visible = false;
    }

    cameraRig.lookAt(mesh.position);

    threeJs.renderer!.clear();

    activeHelper.visible = false;

    threeJs.renderer!.setClearColor( three.Color.fromHex32(0x000000), 1 );
    threeJs.renderer!.setScissor( 0, 0, threeJs.width / 2, threeJs.height);
    threeJs.renderer!.setViewport(0, 0, threeJs.width / 2, threeJs.height);
    threeJs.renderer!.render(threeJs.scene, activeCamera);

    activeHelper.visible = true;

    threeJs.renderer!.setClearColor( three.Color.fromHex32(0x111111), 1 );
    threeJs.renderer!.setScissor( threeJs.width / 2, 0, threeJs.width / 2, threeJs.height);
    threeJs.renderer!.setViewport(threeJs.width / 2, 0, threeJs.width / 2, threeJs.height);
    threeJs.renderer!.render( threeJs.scene, threeJs.camera );
  }

  void setup(){
    int frustumSize = 600;
    double aspect = 1.0;

    aspect = threeJs.width / threeJs.height;
    threeJs.scene = three.Scene();

    //

    threeJs.camera = three.PerspectiveCamera(50, 0.5 * aspect, 1, 10000);
    threeJs.camera.position.z = 2500;

    cameraPerspective =
        three.PerspectiveCamera(50, 0.5 * aspect, 150, 1000);

    cameraPerspectiveHelper = CameraHelper(cameraPerspective);
    threeJs.scene.add(cameraPerspectiveHelper);

    //
    cameraOrtho = three.OrthographicCamera(
        0.5 * frustumSize * aspect / -2,
        0.5 * frustumSize * aspect / 2,
        frustumSize / 2,
        frustumSize / -2,
        150,
        1000);

    cameraOrthoHelper = CameraHelper(cameraOrtho);
    threeJs.scene.add(cameraOrthoHelper);

    //

    activeCamera = cameraPerspective;
    activeHelper = cameraPerspectiveHelper;

    // counteract different front orientation of cameras vs rig

    cameraOrtho.rotation.y = math.pi;
    cameraPerspective.rotation.y = math.pi;

    cameraRig = three.Group();

    cameraRig.add(cameraPerspective);
    cameraRig.add(cameraOrtho);

    threeJs.scene.add(cameraRig);

    //

    mesh = three.Mesh(three.SphereGeometry(100, 16, 8), three.MeshBasicMaterial.fromMap({"color": 0xffffff, "wireframe": true}));
    threeJs.scene.add(mesh);

    final mesh2 = three.Mesh(three.SphereGeometry(50, 16, 8),
        three.MeshBasicMaterial.fromMap({"color": 0x00ff00, "wireframe": true}));
    mesh2.position.y = 150;
    mesh.add(mesh2);

    final mesh3 = three.Mesh(three.SphereGeometry(5, 16, 8),
        three.MeshBasicMaterial.fromMap({"color": 0x0000ff, "wireframe": true}));
    mesh3.position.z = 150;
    cameraRig.add(mesh3);

    //

    final geometry = three.BufferGeometry();
    List<double> vertices = [];

    for (int i = 0; i < 10000; i++) {
      vertices.add(randFloatSpread(2000)); // x
      vertices.add(randFloatSpread(2000)); // y
      vertices.add(randFloatSpread(2000)); // z
    }

    geometry.setAttributeFromString(
        'position', three.Float32BufferAttribute.fromList(vertices, 3));

    final particles = three.Points(
        geometry, three.PointsMaterial.fromMap({"color": 0x888888}));
    threeJs.scene.add(particles);

    threeJs.renderer!.setScissorTest( true );
  }
}

