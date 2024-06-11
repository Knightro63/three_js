import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';
import 'package:three_js_helpers/three_js_helpers.dart';

class WebglClippingStencil extends StatefulWidget {
  final String fileName;
  const WebglClippingStencil({super.key, required this.fileName});

  @override
  createState() => _State();
}

class _State extends State<WebglClippingStencil> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        localClippingEnabled: true,
        clearColor: 0x263238,
        clearAlpha: 1.0,
        useSourceTexture: true
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
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: threeJs.build()
    );
  }

  late three.OrbitControls controls;
  bool cleared = false;

  late three.Object3D object;
  late List<three.Plane> planes;
  late List<PlaneHelper> planeHelpers;
  late List<three.Mesh> planeObjects;

  three.Group createPlaneStencilGroup(three.BufferGeometry geometry, three.Plane plane, int renderOrder) {
    final group = three.Group();
    final mat0 = three.MeshBasicMaterial.fromMap({
      "side": three.BackSide,
      "clippingPlanes": List<three.Plane>.from([plane]),
      "stencilFail": three.IncrementWrapStencilOp,
      "stencilZFail": three.IncrementWrapStencilOp,
      "stencilZPass": three.IncrementWrapStencilOp,
      "depthWrite": false,
      "depthTest": false,
      "colorWrite": false,
      "stencilWrite": true,
      "stencilFunc": three.AlwaysStencilFunc
    });

    final mesh0 = three.Mesh(geometry, mat0);
    mesh0.renderOrder = renderOrder;
    group.add(mesh0);

    final mat1 = three.MeshBasicMaterial.fromMap({
      "side": three.BackSide,
      "clippingPlanes": List<three.Plane>.from([plane]),
      "stencilFail": three.DecrementWrapStencilOp,
      "stencilZFail": three.DecrementWrapStencilOp,
      "stencilZPass": three.DecrementWrapStencilOp,
      "depthWrite": false,
      "depthTest": false,
      "colorWrite": false,
      "stencilWrite": true,
      "stencilFunc": three.AlwaysStencilFunc
    });

    final mesh1 = three.Mesh(geometry, mat1);
    mesh1.renderOrder = renderOrder;

    group.add(mesh1);

    return group;
  }

  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.camera = three.PerspectiveCamera(36, threeJs.width / threeJs.height, 1, 100);
    threeJs.camera.position.setValues(2, 2, 2);
    threeJs.scene.add(three.AmbientLight(0xffffff, 0.5));
    threeJs.camera.lookAt(threeJs.scene.position);

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    final dirLight = three.DirectionalLight(0xffffff, 1);
    dirLight.position.setValues(5, 10, 7.5);
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.right = 2;
    dirLight.shadow!.camera!.left = -2;
    dirLight.shadow!.camera!.top = 2;
    dirLight.shadow!.camera!.bottom = -2;

    dirLight.shadow!.mapSize.width = 1024;
    dirLight.shadow!.mapSize.height = 1024;
    threeJs.scene.add(dirLight);

    planes = [
      three.Plane(three.Vector3(-1, 0, 0), 0),
      three.Plane(three.Vector3(0, -1, 0), 0),
      three.Plane(three.Vector3(0, 0, -1), 0)
    ];

    // planeHelpers = planes.map((p) => PlaneHelper(p, 2, 0xffffff)).toList();
    // for (final ph in planeHelpers) {
    //   ph.visible = true;
    //   threeJs.scene.add(ph);
    // }

    final geometry = TorusKnotGeometry(0.4, 0.15, 220, 60);
    object = three.Group();
    threeJs.scene.add(object);

    // Set up clip plane rendering
    planeObjects = [];
    final planeGeom = three.PlaneGeometry(4, 4);

    for (int i = 0; i < 1; i++) {
      final poGroup = three.Group();
      final plane = planes[i];
      final stencilGroup = createPlaneStencilGroup(geometry, plane, i + 1);

      List<three.Plane> _planes = planes.where((p) => p != plane).toList();

      // plane is clipped by the other clipping planes
      final planeMat = three.MeshStandardMaterial.fromMap({
        "color": 0xE91E63,
        "metalness": 0.1,
        "roughness": 0.75,
        "clippingPlanes": planes,
        "stencilWrite": true,
        "stencilRef": 0,
        "stencilFunc": three.NotEqualStencilFunc,
        "stencilFail": three.ReplaceStencilOp,
        "stencilZFail": three.ReplaceStencilOp,
        "stencilZPass": three.ReplaceStencilOp,
      });

      final po = three.Mesh(planeGeom, planeMat);
      po.renderOrder = i + 1;

      object.add(stencilGroup);
      poGroup.add(po);
      planeObjects.add(po);
      threeJs.scene.add(poGroup);
    }

    final material = three.MeshStandardMaterial.fromMap({
      "color": 0xFFC107,
      "metalness": 0.1,
      "roughness": 0.75,
      "clippingPlanes": planes,
      "clipShadows": true,
      "shadowSide": three.DoubleSide,
    });

    // add the color
    final clippedColorFront = three.Mesh(geometry, material);
    clippedColorFront.castShadow = true;
    clippedColorFront.renderOrder = 6;
    object.add(clippedColorFront);

    final ground = three.Mesh(
      three.PlaneGeometry(9, 9, 1, 1),
      three.ShadowMaterial.fromMap({"color": 0, "opacity": 0.25, "side": three.DoubleSide})
    );

    ground.rotation.x = -math.pi / 2; // rotates X/Y to X/Z
    ground.position.y = -1;
    ground.receiveShadow = true;
    threeJs.scene.add(ground);

    threeJs.addAnimationEvent((dt){
      animate(dt);
      controls.update();
    });
  }

  void animate(double delta) {
    object.rotation.x += delta * 0.5;
    object.rotation.y += delta * 0.2;

    for (int i = 0; i < planeObjects.length; i++) {
      final plane = planes[i];
      final po = planeObjects[i];
      plane.coplanarPoint(po.position);
      po.lookAt(three.Vector3(
        po.position.x - plane.normal.x,
        po.position.y - plane.normal.y,
        po.position.z - plane.normal.z,
      ));
    }
  }
}
