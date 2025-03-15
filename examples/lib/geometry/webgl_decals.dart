import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_geometry/three_js_geometry.dart';

class WebglDecals extends StatefulWidget {
  
  const WebglDecals({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglDecals> {
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
    );
    super.initState();
  }
  @override
  void dispose() {
    controls.dispose();
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
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
  late three.Raycaster raycaster;
  late three.Mesh mesh;
  late three.Mesh mouseHelper;
  late three.Line line;
  final three.Vector2 mouse = three.Vector2.zero();
  final textureLoader = three.TextureLoader(flipY: !kIsWeb);

  final position = three.Vector3();
  final orientation = three.Euler();
  final size = three.Vector3( 10, 10, 10 );

  final decalMaterial = three.MeshPhongMaterial.fromMap( {
    'specular': 0x444444,
    'normalScale': three.Vector2( 1, 1 ),
    'shininess': 30,
    'transparent': true,
    'depthTest': true,
    'depthWrite': false,
    'polygonOffset': true,
    'polygonOffsetFactor': - 4,
    'wireframe': false
  });

  final intersection = <String,dynamic>{
    'intersects': false,
    'point': three.Vector3(),
    'normal': three.Vector3()
  };

  final List<three.Intersection> intersects = [];
  List<three.Mesh> decals = [];

  Future<void> setup() async {
    final decalDiffuse = await textureLoader.fromAsset( 'assets/textures/decal/decal-diffuse.png' );
    final decalNormal = await textureLoader.fromAsset( 'assets/textures/decal/decal-normal.jpg' );

    decalMaterial.map = decalDiffuse;
    decalMaterial.normalMap = decalNormal;

    threeJs.scene = three.Scene();

    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width/threeJs.height, 1, 1000 );
    threeJs.camera.position.z = 120;

    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.minDistance = 50;
    controls.maxDistance = 200;

    threeJs.scene.add( three.AmbientLight( 0x666666,0.6 ) );

    final dirLight1 = three.DirectionalLight( 0xffddcc, 0.6 );
    dirLight1.position.setValues( 1, 0.75, 0.5 );
    threeJs.scene.add( dirLight1 );

    final dirLight2 = three.DirectionalLight( 0xccccff, 0.6 );
    dirLight2.position.setValues( - 1, 0.75, - 0.5 );
    threeJs.scene.add( dirLight2 );

    final geometry = three.BufferGeometry();
    geometry.setFromPoints( [ three.Vector3(), three.Vector3() ] );

    line = three.Line( geometry, three.LineBasicMaterial() );
    threeJs.scene.add( line );

    await loadLeePerrySmith();

    raycaster = three.Raycaster();

    mouseHelper = three.Mesh( three.BoxGeometry( 1, 1, 10 ), three.MeshNormalMaterial() );
    mouseHelper.visible = false;
    threeJs.scene.add( mouseHelper );

    bool moved = false;

    threeJs.domElement.addEventListener(three.PeripheralType.pointerdown, () {
      moved = false;
    });

    threeJs.domElement.addEventListener(three.PeripheralType.pointerup, ( event ) {
      if ( moved == false ) {
        checkIntersection( event.clientX, event.clientY );
        if (intersection['intersects']) shoot();
      }
    });

    threeJs.domElement.addEventListener( three.PeripheralType.pointerHover, onPointerMove );

    threeJs.addAnimationEvent((dt){
      controls.update();
    });
  }

  void onPointerMove( event ) {
    if ( event.isPrimary ) {
      checkIntersection( event.clientX, event.clientY );
    }
  }

  void checkIntersection(double x, double y) {
    mouse.x = ( x / threeJs.width ) * 2 - 1;
    mouse.y = - ( y / threeJs.height ) * 2 + 1;

    raycaster.setFromCamera( mouse, threeJs.camera );
    raycaster.intersectObject( mesh, false, intersects );

    if ( intersects.isNotEmpty ) {

      final p = intersects[ 0 ].point!;
      mouseHelper.position.setFrom( p );
      intersection['point'].setFrom( p );

      final n = intersects[ 0 ].face!.normal.clone();
      n.transformDirection( mesh.matrixWorld );
      n.scale( 10 );
      n.add( intersects[ 0 ].point! );

      intersection['normal'].setFrom( intersects[ 0 ].face!.normal );
      mouseHelper.lookAt( n );

      final positions = line.geometry!.attributes['position'];
      positions.setXYZ( 0, p.x, p.y, p.z );
      positions.setXYZ( 1, n.x, n.y, n.z );
      positions.needsUpdate = true;

      intersection['intersects'] = true;

      intersects.length = 0;
    } 
    else {
      intersection['intersects'] = false;
    }
  }

  Future<void> loadLeePerrySmith() async{
    final map = await textureLoader.fromAsset( 'assets/models/gltf/LeePerrySmith/Map-COL.jpg');
    //map.colorSpace = THREE.SRGBColorSpace;
    final specularMap = await textureLoader.fromAsset( 'assets/models/gltf/LeePerrySmith/Map-SPEC.jpg' );
    //final normalMap = await textureLoader.fromAsset( 'assets/models/gltf/LeePerrySmith/Infinite-Level_02_Tangent_SmoothUV.jpg' );

    final loader = three.GLTFLoader();

    await loader.fromAsset( 'assets/models/gltf/LeePerrySmith/LeePerrySmith.glb').then(( gltf ) {
      mesh = gltf!.scene.children[0] as three.Mesh;
      mesh.material = three.MeshPhongMaterial.fromMap( {
        'specular': 0x111111,
        'map': map,
        'specularMap': specularMap,
        //'normalMap': normalMap,
        'shininess': 25
      });

      threeJs.scene.add( mesh );
      mesh.scale.setValues( 10, 10, 10 );
    });
  }

  void shoot() {
    position.setFrom( intersection['point'] );
    orientation.copy( mouseHelper.rotation );

    //orientation.z = math.Random().nextDouble() * 2 * math.pi;

    final scale = 2 + math.Random().nextDouble() * (5 - 2);
    size.setValues( scale, scale, scale );

    final material = decalMaterial.clone();
    material.color.setFromHex32( (math.Random().nextDouble() * 0xffffff).toInt() );

    final m = three.Mesh(DecalGeometry( mesh, position, orientation, size ), material );
    m.renderOrder = decals.length; // give decals a fixed render order

    decals.add(m);
    threeJs.scene.add( m );
  }

  void removeDecals() {
    decals.clear();
  }
}
