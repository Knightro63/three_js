import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:example/src/gui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_advanced_exporters/gltf_exporter.dart';
import 'package:three_js_exporters/saveFile/saveFile.dart';
import 'package:three_js_helpers/three_js_helpers.dart';

class MiscExporterGLTF extends StatefulWidget {
  const MiscExporterGLTF({super.key});
  @override
  createState() => _State();
}

class _State extends State<MiscExporterGLTF> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late three.ThreeJS threeJs;
  late Gui gui;

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
    gui = Gui((){setState(() {});});
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    controls.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          threeJs.build(),
          Statistics(data: data),
          if(threeJs.mounted)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: gui.render()
            )
          )  
        ],
      ) 
    );
  }

  late final three.OrbitControls controls;
  late three.Object3D object;
  late three.Material material;

  final Map<String,dynamic> params = {
    'trs': false,
    'onlyVisible': true,
    'binary': false,
    'maxTextureSize': 4096,
  };

  Future<void> setup() async {
    final data = Uint8List( 100 * 100 * 4 );

    for ( int y = 0; y < 100; y ++ ) {
      for ( int x = 0; x < 100; x ++ ) {
        final stride = 4 * ( 100 * y + x );
        data[ stride ] = ( 255 * y / 99 ).round();
        data[ stride + 1 ] = ( 255 - 255 * y / 99 ).round();
        data[ stride + 2 ] = 0;
        data[ stride + 3 ] = 255;
      }
    }

    final gradientTexture = three.DataTexture( data, 100, 100, three.RGBAFormat );
    gradientTexture.minFilter = three.LinearFilter;
    gradientTexture.magFilter = three.LinearFilter;
    gradientTexture.needsUpdate = true;

    threeJs.scene = three.Scene();
    threeJs.scene.name = 'threeJs.scene';

    // ---------------------------------------------------------------------
    // Perspective Camera
    // ---------------------------------------------------------------------
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 1, 2000 );
    threeJs.camera.position.setValues( 600, 400, 0 );

    threeJs.camera.name = 'PerspectiveCamera';
    threeJs.scene.add( threeJs.camera );

    // ---------------------------------------------------------------------
    // Ambient light
    // ---------------------------------------------------------------------
    final ambientLight = three.AmbientLight( 0xcccccc );
    ambientLight.name = 'AmbientLight';
    threeJs.scene.add( ambientLight );

    // ---------------------------------------------------------------------
    // DirectLight
    // ---------------------------------------------------------------------
    final dirLight = three.DirectionalLight( 0xffffff, 3 );
    dirLight.target?.position.setValues( 0, 0, - 1 );
    dirLight.add( dirLight.target );
    dirLight.lookAt(three.Vector3(- 1, - 1, 0));
    dirLight.name = 'DirectionalLight';
    threeJs.scene.add( dirLight );

    // ---------------------------------------------------------------------
    // Grid
    // ---------------------------------------------------------------------
    final gridHelper = GridHelper( 2000, 20, 0xc1c1c1, 0x8d8d8d );
    gridHelper.position.y = - 50;
    gridHelper.name = 'Grid';
    threeJs.scene.add( gridHelper );

    // ---------------------------------------------------------------------
    // Axes
    // ---------------------------------------------------------------------
    final axes = AxesHelper( 500 );
    axes.name = 'AxesHelper';
    threeJs.scene.add( axes );

    // ---------------------------------------------------------------------
    // Simple geometry with basic material
    // ---------------------------------------------------------------------
    // Icosahedron
    final mapGrid = await three.TextureLoader().fromAsset( 'assets/textures/uv_grid_opengl.jpg' );
    mapGrid?.wrapS = mapGrid.wrapT = three.RepeatWrapping;
    mapGrid?.colorSpace = three.SRGBColorSpace;
    material = three.MeshBasicMaterial.fromMap( {
      'color': 0xffffff,
      'map': mapGrid
    } );

    object = three.Mesh( three.IcosahedronGeometry( 75, 0 ), material );
    object.position.setValues( - 200, 0, 200 );
    object.name = 'Icosahedron';
    threeJs.scene.add( object );

    // Octahedron
    material = three.MeshBasicMaterial.fromMap( {
      'color': 0x0000ff,
      'wireframe': true
    } );
    object = three.Mesh( three.OctahedronGeometry( 75, 1 ), material );
    object.position.setValues( 0, 0, 200 );
    object.name = 'Octahedron';
    threeJs.scene.add( object );

    // Tetrahedron
    material = three.MeshBasicMaterial.fromMap( {
      'color': 0xff0000,
      'transparent': true,
      'opacity': 0.5
    } );

    object = three.Mesh( three.TetrahedronGeometry( 75, 0 ), material );
    object.position.setValues( 200, 0, 200 );
    object.name = 'Tetrahedron';
    threeJs.scene.add( object );

    // ---------------------------------------------------------------------
    // Buffered geometry primitives
    // ---------------------------------------------------------------------
    // Sphere
    material = three.MeshStandardMaterial.fromMap( {
      'color': 0xffff00,
      'metalness': 0.5,
      'roughness': 1.0,
      'flatShading': true,
    } );
    material.map = gradientTexture;
    material.bumpMap = mapGrid;
    final sphere = three.Mesh( three.SphereGeometry( 70, 10, 10 ), material );
    sphere.position.setValues( 0, 0, 0 );
    sphere.name = 'Sphere';
    threeJs.scene.add( sphere );

    // Cylinder
    material = three.MeshStandardMaterial.fromMap( {
      'color': 0xff00ff,
      'flatShading': true
    } );
    object = three.Mesh( three.CylinderGeometry( 10, 80, 100 ), material );
    object.position.setValues( 200, 0, 0 );
    object.name = 'Cylinder';
    threeJs.scene.add( object );

    // TorusKnot
    material = three.MeshStandardMaterial.fromMap( {
      'color': 0xff0000,
      'roughness': 1
    } );
    object = three.Mesh( three.TorusKnotGeometry( 50, 15, 40, 10 ), material );
    object.position.setValues( - 200, 0, 0 );
    object.name = 'Cylinder';
    threeJs.scene.add( object );


    // ---------------------------------------------------------------------
    // Hierarchy
    // ---------------------------------------------------------------------
    final mapWood = await three.TextureLoader().fromAsset( 'assets/textures/hardwood2_diffuse.jpg' );
    material = three.MeshStandardMaterial.fromMap( { 'map': mapWood, 'side': three.DoubleSide } );

    object = three.Mesh( three.BoxGeometry( 40, 100, 100 ), material );
    object.position.setValues( - 200, 0, 400 );
    object.name = 'Cube';
    threeJs.scene.add( object );

    three.Mesh object2 = three.Mesh( three.BoxGeometry( 40, 40, 40, 2, 2, 2 ), material );
    object2.position.setValues( 0, 0, 50 );
    object2.rotation.set( 0, 45, 0 );
    object2.name = 'SubCube';
    object.add( object2 );


    // ---------------------------------------------------------------------
    // Groups
    // ---------------------------------------------------------------------
    final group1 = three.Group();
    group1.name = 'Group';
    threeJs.scene.add( group1 );

    final group2 = three.Group();
    group2.name = 'subGroup';
    group2.position.setValues( 0, 50, 0 );
    group1.add( group2 );

    object2 = three.Mesh( three.BoxGeometry( 30, 30, 30 ), material );
    object2.name = 'Cube in group';
    object2.position.setValues( 0, 0, 400 );
    group2.add( object2 );

    // ---------------------------------------------------------------------
    // three.Line Strip
    // ---------------------------------------------------------------------
    three.BufferGeometry geometry = three.BufferGeometry();
    int numPoints = 100;
    Float32List positions = Float32List( numPoints * 3 );

    for ( int i = 0; i < numPoints; i ++ ) {
      positions[ i * 3 ] = i*1.0;
      positions[ i * 3 + 1 ] = math.sin( i / 2 ) * 20;
      positions[ i * 3 + 2 ] = 0;
    }

    geometry.setAttributeFromString( 'position', three.Float32BufferAttribute( positions, 3 ) );
    object = three.Line( geometry, three.LineBasicMaterial.fromMap( { 'color': 0xffff00 } ) );
    object.position.setValues( - 50, 0, - 200 );
    threeJs.scene.add( object );

    // ---------------------------------------------------------------------
    // three.Line Loop
    // ---------------------------------------------------------------------
    geometry = three.BufferGeometry();
    numPoints = 5;
    const radius = 70.0;
    positions = Float32List( numPoints * 3 );

    for ( int i = 0; i < numPoints; i ++ ) {
      final s = i * math.pi * 2 / numPoints;
      positions[ i * 3 ] = radius * math.sin( s );
      positions[ i * 3 + 1 ] = radius * math.cos( s );
      positions[ i * 3 + 2 ] = 0;
    }

    geometry.setAttributeFromString( 'position', three.Float32BufferAttribute( positions, 3 ) );
    object = three.LineLoop( geometry, three.LineBasicMaterial.fromMap( { 'color': 0xffff00 } ) );
    object.position.setValues( 0, 0, - 200 );

    threeJs.scene.add( object );

    // ---------------------------------------------------------------------
    // three.Points
    // ---------------------------------------------------------------------
    numPoints = 100;
    final pointsArray = Float32List( numPoints * 3 );
    for ( int i = 0; i < numPoints; i ++ ) {
      pointsArray[ 3 * i ] = - 50 + math.Random().nextDouble() * 100;
      pointsArray[ 3 * i + 1 ] = math.Random().nextDouble() * 100;
      pointsArray[ 3 * i + 2 ] = - 50 + math.Random().nextDouble() * 100;
    }

    final pointsGeo = three.BufferGeometry();
    pointsGeo.setAttributeFromString( 'position', three.Float32BufferAttribute.fromList( pointsArray, 3 ) );

    final pointsMaterial = three.PointsMaterial.fromMap( { 'color': 0xffff00, 'size': 5 } );
    final pointCloud = three.Points( pointsGeo, pointsMaterial );
    pointCloud.name = 'Points';
    pointCloud.position.setValues( - 200, 0, - 200 );
    threeJs.scene.add( pointCloud );

    // ---------------------------------------------------------------------
    // Ortho camera
    // ---------------------------------------------------------------------

    const height = 1000.0; // frustum height
    final aspect = threeJs.width / threeJs.height;

    final cameraOrtho = three.OrthographicCamera( - height * aspect, height * aspect, height, - height, 0, 2000 );
    cameraOrtho.position.setValues( 600, 400, 0 );
    cameraOrtho.lookAt(three.Vector3());
    threeJs.scene.add( cameraOrtho );
    cameraOrtho.name = 'OrthographicCamera';

    material = three.MeshLambertMaterial.fromMap( {
      'color': 0xffff00,
      'side': three.DoubleSide
    } );

    object = three.Mesh( three.CircleGeometry( radius: 50, segments: 20, thetaLength: math.pi * 2 ), material );
    object.position.setValues( 200, 0, - 400 );
    threeJs.scene.add( object );

    object = three.Mesh( three.RingGeometry( 10, 50, 20, 5, 0, math.pi * 2 ), material );
    object.position.setValues( 0, 0, - 400 );
    threeJs.scene.add( object );

    object = three.Mesh( three.CylinderGeometry( 25, 75, 100, 40, 5 ), material );
    object.position.setValues( - 200, 0, - 400 );
    threeJs.scene.add( object );

    //
    final List<three.Vector2> points = [];

    for ( int i = 0; i < 50; i ++ ) {
      points.add( three.Vector2( math.sin( i * 0.2 ) * math.sin( i * 0.1 ) * 15 + 50, ( i - 5 ) * 2 ) );
    }

    object = three.Mesh( three.LatheGeometry( points, segments: 20 ), material );
    object.position.setValues( 200, 0, 400 );
    threeJs.scene.add( object );

    // ---------------------------------------------------------------------
    // Big red box hidden just for testing `onlyVisible` option
    // ---------------------------------------------------------------------
    material = three.MeshBasicMaterial.fromMap( {
      'color': 0xff0000
    } );
    object = three.Mesh( three.BoxGeometry( 200, 200, 200 ), material );
    object.position.setValues( 0, 0, 0 );
    object.name = 'CubeHidden';
    object.visible = false;
    threeJs.scene.add( object );

    // ---------------------------------------------------------------------
    // Model requiring KHR_mesh_quantization
    // ---------------------------------------------------------------------
    final loader = three.GLTFLoader();
    final gltf = await loader.fromAsset( 'assets/models/gltf/ShaderBall.glb');

    final model = gltf!.scene;
    model.scale.setScalar( 50 );
    model.position.setValues( 200, - 40, - 200 );
    threeJs.scene.add( model );

    // ---------------------------------------------------------------------
    // Model requiring KHR_mesh_quantization
    // ---------------------------------------------------------------------

    material = three.MeshBasicMaterial.fromMap( {
      'color': 0xffffff,
    } );
    object = three.InstancedMesh( three.BoxGeometry( 10, 10, 10, 2, 2, 2 ), material, 50 );
    final matrix = three.Matrix4();
    final color = three.Color();

    for ( int i = 0; i < 50; i ++ ) {
      matrix.setPosition( math.Random().nextDouble() * 100 - 50, math.Random().nextDouble() * 100 - 50, math.Random().nextDouble() * 100 - 50 );
      (object as three.InstancedMesh).setMatrixAt( i, matrix );
      (object as three.InstancedMesh).setColorAt( i, color.setHSL( i / 50, 1, 0.5 ) );
    }

    object.position.setValues( 400, 0, 200 );
    threeJs.scene.add( object );

    // ---------------------------------------------------------------------
    // 2nd three.Scene
    // ---------------------------------------------------------------------
    final scene2 = three.Scene();
    object = three.Mesh( three.BoxGeometry( 100, 100, 100 ), material );
    object.position.setValues( 0, 0, 0 );
    object.name = 'Cube2ndScene';
    scene2.name = 'Scene2';
    scene2.add( object );

    final gltf2 = await three.GLTFLoader().fromAsset( 'assets/models/gltf/coffeemate.glb');
    gltf2!.scene.position.x = 400;
    gltf2.scene.position.z = - 200;
    threeJs.scene.add( gltf2.scene );
    final coffeemat = gltf2.scene;

    threeJs.addAnimationEvent((dt){
      final timer = DateTime.now().millisecondsSinceEpoch * 0.0001;
      threeJs.camera.position.x = math.cos( timer ) * 800;
      threeJs.camera.position.z = math.sin( timer ) * 800;
      threeJs.camera.lookAt( threeJs.scene.position );
    });

    final webpTexture = three.CanvasTexture( await generateTexture() );
    webpTexture.userData['mimeType'] = 'image/webp';
    webpTexture.colorSpace = three.SRGBColorSpace;

    final webpBox = three.Mesh(
      three.BoxGeometry( 100, 100, 100 ),
      three.MeshBasicMaterial.fromMap( { 'map': webpTexture } )
    );
    webpBox.position.setValues( 400, 0, 0 );
    webpBox.name = 'WebPBox';
    threeJs.scene.add( webpBox );

    Folder h = gui.addFolder( 'Settings' )..open();
    h.addCheckBox( params, 'trs' ).name = 'Use TRS';
    h.addCheckBox( params, 'onlyVisible' ).name = 'Only Visible Objects';
    h.addCheckBox( params, 'binary' ).name ='Binary (GLB)';
    h.addSlider( params, 'maxTextureSize', 2, 8192 )..name = 'Max Texture Size'..step( 1 );

    h = gui.addFolder( 'Export' )..open();
    h.addFunction('exportscene1' )..name = 'Export Scene 1'..onFinishChange((){
      exportGLTF( [threeJs.scene] , 'scene');
    });
    h.addFunction('exportScenes' )..name = 'Export Scene 1 and 2'..onFinishChange((){
      exportGLTF( [ threeJs.scene, scene2 ] , 'scene1_2');
    });
    h.addFunction('exportSphere')..name = 'Export Sphere'..onFinishChange((){
      exportGLTF( [sphere],'sphere' );
    });
    h.addFunction('exportModel' )..name = 'Export Model'..onFinishChange((){
      exportGLTF( [model],'model' );
    });
    h.addFunction('exportObjects' )..name = 'Export Sphere With Grid'..onFinishChange((){
      exportGLTF( [ sphere, gridHelper ],'objects' );
    });
    h.addFunction('exportSceneObject' )..name = 'Export Scene 1 and Object'..onFinishChange((){
      exportGLTF( [ threeJs.scene, gridHelper ],'scene_object' );
    });
    h.addFunction('exportCompressedObject' )..name = 'Export Coffeemat'..onFinishChange((){
      exportGLTF([coffeemat],'cofffeeMate');
    });
    h.addFunction('exportWebPModel' )..name = 'Export WebP Model (EXT_texture_webp)'..onFinishChange((){
      exportGLTF( [webpBox],'webpmodel');
    });
  }

  Future<three.ImageElement> generateTexture() async {
    const int width = 64;
    const int height = 64;
    
    // 1. Create a raw RGBA byte buffer (64 * 64 pixels * 4 channels = 16,384 bytes)
    final Uint8List pixelData = Uint8List(width * height * 4);

    // 2. Loop through and fill coordinates completely in memory
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int index = (y * width + x) * 4;

        // Check if the current pixel falls inside the inner 32x32 yellow square
        // Equivalent to: ctx.fillRect( 16, 16, 32, 32 ) with color '#FFD500'
        if (x >= 16 && x < 48 && y >= 16 && y < 48) {
          pixelData[index + 0] = 255; // Red
          pixelData[index + 1] = 213; // Green
          pixelData[index + 2] = 0;   // Blue
          pixelData[index + 3] = 255; // Alpha
        } 
        // Fallback background color: '#005BBB' blue
        // Equivalent to: ctx.fillRect( 0, 0, 64, 64 )
        else {
          pixelData[index + 0] = 0;   // Red
          pixelData[index + 1] = 91;  // Green
          pixelData[index + 2] = 187; // Blue
          pixelData[index + 3] = 255; // Alpha
        }
      }
    }

    // 3. Construct and return your native cross-platform three_js ImageElement
    return three.ImageElement(
      width: width,
      height: height,
      data: pixelData,
    );
  }

  void exportGLTF(List<three.Object3D> input, String name ) {
    final gltfExporter = GLTFExporter();

    final options = GLTFOptions(
      trs: params['trs'],
      onlyVisible: params['onlyVisible'],
      type: params['binary'] == true?ExportTypes.binary:ExportTypes.ascii,
      maxTextureSize: params['maxTextureSize']
    );

    gltfExporter.exportList(
      name,
      input,
      options: options
    );
  }
}