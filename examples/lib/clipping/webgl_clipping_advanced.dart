import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglClippingAdvanced extends StatefulWidget {
  
  const WebglClippingAdvanced({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglClippingAdvanced> {
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
      setup: setup,      settings: three.Settings(
        clippingPlanes: [],
        localClippingEnabled: true,
        
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
  late three.Object3D object;
  late three.MeshPhongMaterial clipMaterial;

  int startTime = 0;

  dynamic volumeVisualization;
  late List<three.Plane> globalClippingPlanes;

  late List<three.Plane> scenePlanes;
  late List<three.Matrix4> scenePlaneMatrices;
  late List<three.Plane> sceneGlobalClippingPlanes;

  List<three.Plane> planesFromMesh(List<three.Vector3> vertices, List<int> indices) {
    // creates a clipping volume from a convex triangular mesh
    // specified by the arrays 'vertices' and 'indices'

    int n = indices.length ~/ 3;
    final result = List<three.Plane>.filled(n, three.Plane());
    for (int i = 0, j = 0; i < n; ++i, j += 3) {
      final a = vertices[indices[j]],
          b = vertices[indices[j + 1]],
          c = vertices[indices[j + 2]];

      result[i] = three.Plane().setFromCoplanarPoints(a, b, c);
    }

    return result;
  }

  List<three.Plane> createPlanes(int n) {
    final result = List<three.Plane>.filled(n, three.Plane());

    // for ( final i = 0; i != n; ++ i )
    //   result[ i ] = new three.Plane(null, null);

    return result;
  }

  void assignTransformedPlanes(
    List<three.Plane> planesOut, 
    List<three.Plane> planesIn, 
    three.Matrix4 matrix
  ) {
    for (int i = 0, n = planesIn.length; i != n; ++i) {
      planesOut[i].copyFrom(planesIn[i]).applyMatrix4(matrix, null);
    }
  }

  List<three.Plane> cylindricalPlanes(int n, double innerRadius) {
    final result = createPlanes(n);

    for (int i = 0; i != n; ++i) {
      final three.Plane plane = result[i];
      final double angle = i * math.pi * 2 / n;
      plane.normal.setValues(math.cos(angle), 0.0, math.sin(angle));
      plane.constant = innerRadius;
    }

    return result;
  }

  final xAxis = three.Vector3(),
      yAxis = three.Vector3(),
      trans = three.Vector3();

  three.Matrix4 planeToMatrix(three.Plane plane) {
    final zAxis = plane.normal, matrix = three.Matrix4();

    // Hughes & Moeller '99
    // "Building an Orthonormal Basis from a Unit Vector."

    if (zAxis.x.abs() > zAxis.z.abs()) {
      yAxis.setValues(-zAxis.y, zAxis.x, 0);
    } else {
      yAxis.setValues(0, -zAxis.z, zAxis.y);
    }

    xAxis.cross2(yAxis.normalize(), zAxis);

    plane.coplanarPoint(trans);
    return matrix.setValues(xAxis.x, yAxis.x, zAxis.x, trans.x, xAxis.y, yAxis.y,
        zAxis.y, trans.y, xAxis.z, yAxis.z, zAxis.z, trans.z, 0, 0, 0, 1);
  }

  Future<void> setup() async {
    final List<three.Vector3> vertices = [
      three.Vector3(1, 0, math.sqrt1_2),
      three.Vector3(-1, 0, math.sqrt1_2),
      three.Vector3(0, 1, -math.sqrt1_2),
      three.Vector3(0, -1, -math.sqrt1_2)
    ];
    final List<int> indices = [0, 1, 2, 0, 2, 3, 0, 3, 1, 1, 3, 2];

    scenePlanes = planesFromMesh(vertices, indices);
    scenePlaneMatrices = scenePlanes.map(planeToMatrix).toList();
    sceneGlobalClippingPlanes = cylindricalPlanes(5, 2.5);

    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 0.25, 16);
    threeJs.camera.position.setValues(0, 1.5, 5);
    threeJs.scene = three.Scene();

    threeJs.camera.lookAt(threeJs.scene.position);
    threeJs.scene.add(three.AmbientLight(0xffffff, 0.3));

    controls = three.OrbitControls(threeJs.camera, threeJs.globalKey);

    final spotLight = three.SpotLight(0xffffff, 0.5);
    spotLight.angle = math.pi / 5;
    spotLight.penumbra = 0.2;
    spotLight.position.setValues(2, 3, 3);
    spotLight.castShadow = true;
    spotLight.shadow!.camera!.near = 3;
    spotLight.shadow!.camera!.far = 10;
    spotLight.shadow!.mapSize.width = 1024;
    spotLight.shadow!.mapSize.height = 1024;
    threeJs.scene.add(spotLight);

    final dirLight = three.DirectionalLight(0xffffff, 0.5);
    dirLight.position.setValues(0, 2, 0);
    dirLight.castShadow = true;
    dirLight.shadow!.camera!.near = 1;
    dirLight.shadow!.camera!.far = 10;

    dirLight.shadow!.camera!.right = 1;
    dirLight.shadow!.camera!.left = -1;
    dirLight.shadow!.camera!.top = 1;
    dirLight.shadow!.camera!.bottom = -1;

    dirLight.shadow!.mapSize.width = 1024;
    dirLight.shadow!.mapSize.height = 1024;
    threeJs.scene.add(dirLight);

    // Geometry

    clipMaterial = three.MeshPhongMaterial.fromMap({
      "color": 0xee0a10,
      "shininess": 100,
      "side": three.DoubleSide,
      // Clipping setup:
      "clippingPlanes": createPlanes(scenePlanes.length),
      "clipShadows": true
    });

    object = three.Group();

    final geometry = three.BoxGeometry(0.18, 0.18, 0.18);

    for (int z = -2; z <= 2; ++z){
      for (int y = -2; y <= 2; ++y) {
        for (int x = -2; x <= 2; ++x) {
          final mesh = three.Mesh(geometry, clipMaterial);
          mesh.position.setValues(x / 5, y / 5, z / 5);
          mesh.castShadow = true;
          object.add(mesh);
        }
      }
    }

    threeJs.scene.add(object);

    final planeGeometry = three.PlaneGeometry(3, 3, 1, 1),
        color = three.Color(0, 0, 0);

    volumeVisualization = three.Group();
    volumeVisualization.visible = true;

    for (int i = 0, n = scenePlanes.length; i != n; ++i) {
      List<three.Plane> clippingPlanes = [];

      clipMaterial.clippingPlanes!.asMap().forEach((index, elm) {
        if (index != i) {
          clippingPlanes.add(elm);
        }
      });

      final material = three.MeshBasicMaterial.fromMap({
        "color": color.setHSL(i / n, 0.5, 0.5).getHex(),
        "side": three.DoubleSide,
        "opacity": 0.2,
        "transparent": true,
        "clippingPlanes": clippingPlanes
      });

      final mesh = three.Mesh(planeGeometry, material);
      mesh.matrixAutoUpdate = false;

      volumeVisualization.add(mesh);
    }

    threeJs.scene.add(volumeVisualization);

    final ground = three.Mesh(planeGeometry, three.MeshPhongMaterial.fromMap({"color": 0xa0adaf, "shininess": 10}));
    ground.rotation.x = -math.pi / 2;
    ground.scale.scale(3);
    ground.receiveShadow = true;
    threeJs.scene.add(ground);

    globalClippingPlanes = createPlanes(sceneGlobalClippingPlanes.length);

    startTime = DateTime.now().millisecondsSinceEpoch;
    threeJs.addAnimationEvent((dt){
      controls.update();
      animate();
    });
  }

  void setObjectWorldMatrix(three.Object3D object, three.Matrix4 matrix) {
    final parent = object.parent;
    threeJs.scene.updateMatrixWorld(false);
    object.matrix.setFrom(parent!.matrixWorld).invert();
    object.applyMatrix4(matrix);
  }

  final transform = three.Matrix4(), tmpMatrix = three.Matrix4();

  void animate() {
    final currentTime = DateTime.now().millisecondsSinceEpoch, time = (currentTime - startTime) / 1000;

    object.position.y = 1;
    object.rotation.x = time * 0.5;
    object.rotation.y = time * 0.2;

    object.updateMatrix();
    transform.setFrom(object.matrix);

    final bouncy = math.cos(time * .5) * 0.5 + 0.7;
    transform.multiply(tmpMatrix.makeScale(bouncy, bouncy, bouncy));

    assignTransformedPlanes(clipMaterial.clippingPlanes!, scenePlanes, transform);

    final planeMeshes = volumeVisualization.children;
    final n = planeMeshes.length;

    for (int i = 0; i < n; ++i) {
      tmpMatrix.multiply2(transform, scenePlaneMatrices[i]);
      setObjectWorldMatrix(planeMeshes[i], tmpMatrix);
    }

    transform.makeRotationY(time * 0.1);

    assignTransformedPlanes(globalClippingPlanes, sceneGlobalClippingPlanes, transform);
  }
}
