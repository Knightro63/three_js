import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:three_js_controls/three_js_controls.dart';
import 'package:three_js_core/three_js_core.dart' as three;
import 'package:three_js_objects/three_js_objects.dart';
import 'package:three_js_math/three_js_math.dart' as tmath;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter threeJs',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Marching(),
    );
  }
}

class EffectController{
  EffectController({
    this.material = 'shiny',
    this.speed = 1.0,
    this.numBlobs = 10,
    this.resolution = 28,
    this.isolation = 80,

    this.floor = true,
    this.wallx = false,
    this.wallz = false,
    Function()? dummy
  }){
    this.dummy = dummy ?? (){};

  }

  String material;
  double speed;
  int numBlobs;
  int resolution;
  int isolation;
  bool floor;
  bool wallx;
  bool wallz;

  late Function? dummy;
}

class Marching extends StatefulWidget {
  const Marching({
    super.key,
  });

  @override
  _MarchingState createState() => _MarchingState();
}

class _MarchingState extends State<Marching> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,      settings: three.Settings(
        renderOptions: {"format": tmath.RGBAFormat,"samples": 8},
        
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    threeJs.dispose();
    controls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: threeJs.build()
    );
  }
  
  late OrbitControls controls;
  late EffectController effectController;
  String currentMaterial = 'plastic';
  late MarchingCubes effect;
  double time = 0;

	// this controls content of marching cubes voxel field
  void updateCubes(MarchingCubes object, double time, int numblobs, bool floor, bool wallx, bool wallz ) {
    object.reset();

    // fill the field with some metaballs
    final rainbow = [
      tmath.Color.fromHex32( 0xff0000 ),
      tmath.Color.fromHex32( 0xffbb00 ),
      tmath.Color.fromHex32( 0xffff00 ),
      tmath.Color.fromHex32( 0x00ff00 ),
      tmath.Color.fromHex32( 0x0000ff ),
      tmath.Color.fromHex32( 0x9400bd ),
      tmath.Color.fromHex32( 0xc800eb )
    ];

    const subtract = 12;
    final strength = 1.2 / ( ( math.sqrt( numblobs ) - 1 ) / 4 + 1 );

    for (int i = 0; i < numblobs; i ++ ) {

      final ballx = math.sin( i + 1.26 * time * ( 1.03 + 0.5 * math.cos( 0.21 * i ) ) ) * 0.27 + 0.5;
      final bally = ( math.cos( i + 1.12 * time * math.cos( 1.22 + 0.1424 * i ) ) ).abs() * 0.77; // dip into the floor
      final ballz = math.cos( i + 1.32 * time * 0.1 * math.sin( ( 0.92 + 0.53 * i ) ) ) * 0.27 + 0.5;

      if(currentMaterial == 'multiColors' ) {
        object.addBall( ballx, bally, ballz, strength, subtract, rainbow[ i % 7 ] );
      } 
      else {
        object.addBall( ballx, bally, ballz, strength, subtract );
      }
    }

    if ( floor ) object.addPlaneY( 2, 12 );
    if ( wallz ) object.addPlaneZ( 2, 12 );
    if ( wallx ) object.addPlaneX( 2, 12 );

    object.update();

  }
  Future<void> setup() async {
    threeJs.scene = three.Scene();
    threeJs.scene.background = tmath.Color.fromHex32( 0x050505 );

    threeJs.camera = three.PerspectiveCamera(45, threeJs.width / threeJs.height, 1, 10000);
    threeJs.camera.position.setValues( - 500, 500, 1500 );

    // lights
    three.DirectionalLight light = three.DirectionalLight( 0xffffff, 3 );
    light.position.setValues( 0.5, 0.5, 1 );
    threeJs.scene.add(light);

    three.PointLight pointLight = three.PointLight( 0xff7c00, 3, 0, 0 );
    pointLight.position.setValues( 0, 0, 100 );
    threeJs.scene.add( pointLight );

    three.AmbientLight ambientLight = three.AmbientLight( 0x323232, 3 );
    threeJs.scene.add( ambientLight );

    // MATERIALS
    Map<String,three.Material> materials = generateMaterials();

    // MARCHING CUBES

    double resolution = 28;

    effect = MarchingCubes(resolution, materials[currentMaterial], true, true, 100000 );
    effect.position.setValues( 0, 0, 0 );
    effect.scale.setValues( 700, 700, 700 );

    effect.enableUvs = false;
    effect.enableColors = false;

    threeJs.scene.add( effect );

    // CONTROLS
    controls = OrbitControls(threeJs.camera, threeJs.globalKey);
    controls.minDistance = 500;
    controls.maxDistance = 5000;

    effectController = EffectController(
      material: 'plastic',
      speed: 1.0,
      numBlobs: 10,
      resolution: 28,
      isolation: 80,
      floor: true,
      wallx: false,
      wallz: false,
    );

    threeJs.addAnimationEvent((dt){
      controls.update();
      time += dt * effectController.speed * 0.5;
      updateCubes(effect, time, effectController.numBlobs, effectController.floor, effectController.wallx, effectController.wallz );
    });
  }

  Map<String,three.Material> generateMaterials() {
    final materials = {
				'shiny': three.MeshStandardMaterial.fromMap( { 'color': 0x9c0000, 'roughness': 0.1, 'metalness': 1.0 } ),
				'chrome': three.MeshLambertMaterial.fromMap( { 'color': 0xffffff} ),
				'liquid': three.MeshLambertMaterial.fromMap( { 'color': 0xffffff, 'refractionRatio': 0.85 } ),
				'matte': three.MeshPhongMaterial.fromMap( { 'specular': 0x494949, 'shininess': 1 } ),
				'flat': three.MeshLambertMaterial.fromMap( {'flatShading': true} ),
				'textured': three.MeshPhongMaterial.fromMap( { 'color': 0xffffff, 'specular': 0x111111, 'shininess': 1} ),
				'colors': three.MeshPhongMaterial.fromMap( { 'color': 0xffffff, 'specular': 0xffffff, 'shininess': 2, 'vertexColors': true } ),
				'multiColors': three.MeshPhongMaterial.fromMap( { 'shininess': 2, 'vertexColors': true } ),
				'plastic': three.MeshPhongMaterial.fromMap( { 'color': 0xff414141,'specular': tmath.Color(0.5, 0.5, 0.5), 'shininess': 15 } ),
    };
    return materials;
  }
}


