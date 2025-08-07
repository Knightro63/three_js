import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_helpers/three_js_helpers.dart';

class Controls{
  late List<int> key;
  late three.Vector3 ease;
  late three.Vector3 position;
  late three.Vector3 up;
  late three.Quaternion rotate;
  late String current;
  late double fadeDuration;
  late double runVelocity;
  late double walkVelocity;
  late double rotateSpeed;
  late double floorDecale;
  
  Controls({
    List<int>? key,
    three.Vector3? ease ,
    three.Vector3? position,
    three.Vector3? up,
    three.Quaternion? rotate,
    this.current = 'Idle',
    this.fadeDuration = 0.5,
    this.runVelocity = 5.0,
    this.walkVelocity = 1.8,
    this.rotateSpeed = 0.05,
    this.floorDecale = 0.0,
  }){
    this.key = key ?? [ 0, 0, 0 ];
    this.ease = ease ?? three.Vector3();
    this.position = position ?? three.Vector3();
    this.up = up ?? three.Vector3( 0, 1, 0 );
    this.rotate = rotate ?? three.Quaternion();
  }
}

class WebglAnimationWalk extends StatefulWidget {
  const WebglAnimationWalk({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglAnimationWalk> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late Gui panel;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    panel = Gui((){setState(() {});});
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
      });
    });
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,      settings: three.Settings(
        toneMapping: three.ACESFilmicToneMapping,
        toneMappingExposure: 0.5,
        enableShadowMap: true,
        
      )
    );
    super.initState();
  }
  @override
  void dispose() {
    timer.cancel();
    threeJs.dispose();
    three.loading.clear();
    orbitControls.dispose();
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
              child: panel.render()
            )
          )
        ],
      ) 
    );
  }

  final pi90 = math.pi / 2;

  final Controls controls = Controls();
  final Map<String,bool> settings = {
    'show_skeleton': false,
    'fixe_transition': true,
  };
  late final three.Group group;
  late final three.Group followGroup;
  late final three.OrbitControls orbitControls;
  late final three.Mesh floor;
  late final three.Object3D model;
  late final three.AnimationMixer mixer;
  late final SkeletonHelper skeleton;
  late final Map<String,three.AnimationAction> actions;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 0, 2, - 5 );

    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x5e5d5d );
    threeJs.scene.fog = three.Fog( 0x5e5d5d, 2, 20 );

    group = three.Group();
    threeJs.scene.add( group );

    followGroup = three.Group();
    threeJs.scene.add( followGroup );

    final dirLight = three.DirectionalLight( 0xffffff, 5 );
    dirLight.position.setValues( - 2, 5, - 3 );
    dirLight.castShadow = true;
    final cam = dirLight.shadow?.camera;
    cam?.top = cam.right = 2;
    cam?.bottom = cam.left = - 2;
    cam?.near = 3;
    cam?.far = 8;
    dirLight.shadow?.bias = - 0.005;
    dirLight.shadow?.radius = 4;
    followGroup.add( dirLight );
    followGroup.add( dirLight.target );

    orbitControls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    orbitControls.target.setValues( 0, 1, 0 );
    orbitControls.enableDamping = true;
    orbitControls.enablePan = false;
    orbitControls.maxPolarAngle = pi90 - 0.05;
    orbitControls.update();

    threeJs.domElement.addEventListener( three.PeripheralType.keydown, onKeyDown );
    threeJs.domElement.addEventListener( three.PeripheralType.keyup, onKeyUp );

    final three.DataTexture texture = await three.RGBELoader().setPath('assets/textures/equirectangular/').fromAsset( 'moonless_golf_1k.hdr');
    texture.mapping = three.EquirectangularReflectionMapping;
    threeJs.scene.environment = texture;
    threeJs.scene.environmentIntensity = 1.5;

    await loadModel();
    await addFloor();
  }

  Future<void> addFloor() async{
    const size = 50.0;
    const repeat = 16.0;
    
    // final pointLight = three.PointLight( 0xffffff, 0.05 );
    // threeJs.camera.add( pointLight );
    // threeJs.scene.add(threeJs.camera);
    // threeJs.camera.lookAt(threeJs.scene.position);

    final maxAnisotropy = threeJs.renderer!.capabilities.getMaxAnisotropy().toInt();
    final textureLoader = three.TextureLoader();

    final floorT = await textureLoader.fromAsset( 'assets/textures/floors/FloorsCheckerboard_S_Diffuse.jpg' );
    floorT?.colorSpace = three.SRGBColorSpace;
    floorT?.repeat.setValues( repeat, repeat );
    floorT?.wrapS = floorT.wrapT = three.RepeatWrapping;
    floorT?.anisotropy = maxAnisotropy;

    final floorN = await textureLoader.fromAsset( 'assets/textures/floors/FloorsCheckerboard_S_Normal.jpg' );
    floorN?.repeat.setValues( repeat, repeat );
    floorN?.wrapS = floorN.wrapT = three.RepeatWrapping;
    floorN?.anisotropy = maxAnisotropy;

    final mat = three.MeshStandardMaterial.fromMap( { 
      'map': floorT, 
      'normalMap': floorN, 
      'normalScale': three.Vector2( 0.5, 0.5 ), 
      'color': 0x404040, 
      'depthWrite': false, 
      'roughness': 0.85 
    } );
    final g = three.PlaneGeometry( size, size, 50, 50 );

    g.rotateX( - pi90 );

    floor = three.Mesh( g, mat );
    floor.receiveShadow = true;
    threeJs.scene.add( floor );

    controls.floorDecale = ( size / repeat ) * 4;

    final bulbGeometry = three.SphereGeometry( 0.05, 16, 8 );
    final bulbLight = three.PointLight( 0xffee88, 2, 500, 2 );

    final bulbMat = three.MeshStandardMaterial.fromMap( { 
      'emissive': 0xffffee, 
      'emissiveIntensity': 1.0, 
      'color': 0x000000 
    } );
    bulbLight.add( three.Mesh( bulbGeometry, bulbMat ) );
    bulbLight.position.setValues( 1, 0.1, - 3 );
    bulbLight.castShadow = true;
    floor.add( bulbLight );
  }

  Future<void> loadModel() async{
    final loader = three.GLTFLoader().setPath('assets/models/gltf/Soldier/');
    await loader.fromAsset( 'Soldier.gltf').then(( gltf ) {
      model = gltf!.scene;
      group.add( model );
      model.rotation.y = math.pi;
      group.rotation.y = math.pi;

      model.traverse(( object ) {
        if ( object is three.Mesh ) {
          if ( object.name == 'vanguard_Mesh' ) {
            object.castShadow = true;
            object.receiveShadow = true;
            object.material?.shadowSide = three.DoubleSide;
            object.material?.envMapIntensity = 0.5;
            object.material?.metalness = 1.0;
            object.material?.roughness = 0.2;
            object.material?.color.setValues( 1, 1, 1 );
            object.material?.metalnessMap = object.material?.map;
          }
          else {
            object.material?.metalness = 1;
            object.material?.roughness = 0;
            object.material?.transparent = true;
            object.material?.opacity = 0.8;
            object.material?.color.setValues( 1, 1, 1 );
          }
        }
      });

      skeleton = SkeletonHelper( model );
      skeleton.visible = false;
      threeJs.scene.add( skeleton );

      createPanel();

      final animations = gltf.animations;
      mixer = three.AnimationMixer( model );

      actions = {
        'Idle': mixer.clipAction( animations![ 0 ] )!,
        'Walk': mixer.clipAction( animations[ 3 ] )!,
        'Run': mixer.clipAction( animations[ 1 ] )!
      };

      for ( final m in actions.keys ) {
        actions[ m ]!.enabled = true;
        actions[ m ]!.setEffectiveTimeScale( 1 );
        if ( m != 'Idle' ) actions[ m ]!.setEffectiveWeight( 0 );
      }

      actions['Idle']!.play();
      threeJs.addAnimationEvent((dt){
        updateCharacter(dt);
      });
    });
  }

  void updateCharacter( delta ) {
    final fade = controls.fadeDuration;
    final key = controls.key;
    final up = controls.up;
    final ease = controls.ease;
    final rotate = controls.rotate;
    final position = controls.position;
    final azimuth = orbitControls.getAzimuthalAngle;

    final active = key[ 0 ] == 0 && key[ 1 ] == 0 ? false : true;
    final play = active ? ( key[ 2 ] > 0? 'Run' : 'Walk' ) : 'Idle';

    // change animation

    if ( controls.current != play ) {
      final current = actions[ play ]!;
      final old = actions[ controls.current ]!;
      controls.current = play;

      if ( settings['fixe_transition']! ) {
        current.reset();
        current.weight = 1.0;
        current.stopFading();
        old.stopFading();
        // synchro if not idle
        if ( play != 'Idle' ) current.time = old.time * ( current.getClip().duration / old.getClip().duration );
        old.scheduleFading( fade, old.getEffectiveWeight(), 0 );
        current.scheduleFading( fade, current.getEffectiveWeight(), 1 );
        current.play();
      } 
      else {
        setWeight( current, 1.0 );
        old.fadeOut( fade );
        current.reset().fadeIn( fade ).play();
      }
    }

    // move object
    model.rotation.x = 0;
    if ( controls.current != 'Idle' ) {
      // run/walk velocity
      final velocity = controls.current == 'Run' ? controls.runVelocity : controls.walkVelocity;

      // direction with key
      ease.setValues( key[ 1 ].toDouble(), 0, key[ 0 ].toDouble() ).scale( velocity * delta );

      // calculate camera direction
      final angle = unwrapRad( math.atan2( ease.x, ease.z ) + azimuth );
      rotate.setFromAxisAngle( up, angle );

      // apply camera angle on ease
      controls.ease.applyAxisAngle( up, azimuth );

      position.add( ease );
      threeJs.camera.position.add( ease );

      group.position.setFrom( position );
      group.quaternion.rotateTowards( rotate, controls.rotateSpeed );

      orbitControls.target.setFrom( position ).add( three.Vector3(0,1,0) );
      followGroup.position.setFrom( position );

      // Move the floor without any limit
      final dx = ( position.x - floor.position.x );
      final dz = ( position.z - floor.position.z );
      if ( ( dx ).abs() > controls.floorDecale ) floor.position.x += dx;
      if ( ( dz ).abs() > controls.floorDecale ) floor.position.z += dz;
    }

    mixer.update( delta );
    //orbitControls.update();
  }

  double unwrapRad(double r ) {
    return math.atan2( math.sin( r ), math.cos( r ) );
  }

  void createPanel() {
    //final panel = new GUI( { width: 310 } );
    final folder = panel.addFolder("GUI")..open();
    folder.addButton( settings, 'show_skeleton' ).onChange( ( b ){
      skeleton.visible = b;
    });
    folder.addButton( settings, 'fixe_transition' );
  }

  void setWeight(three.AnimationAction action, double weight ) {
    action.enabled = true;
    action.setEffectiveTimeScale( 1 );
    action.setEffectiveWeight( weight );
  }

	void onKeyDown( event ) {
    final key = controls.key;
    switch ( event.debugName.toString().replaceAll(' ', '') ) {
      case 'ArrowUp': case 'KeyW': case 'KeyZ': key[ 0 ] = - 1; break;
      case 'ArrowDown': case 'KeyS': key[ 0 ] = 1; break;
      case 'ArrowLeft': case 'KeyA': case 'KeyQ': key[ 1 ] = - 1; break;
      case 'ArrowRight': case 'KeyD': key[ 1 ] = 1; break;
      case 'ShiftLeft' : case 'ShiftRight' : key[ 2 ] = 1; break;
	  }
	}
	void onKeyUp( event ) {
    final key = controls.key;
    switch ( event.debugName.toString().replaceAll(' ', '')) {
      case 'ArrowUp': case 'KeyW': case 'KeyZ': key[ 0 ] = key[ 0 ] < 0 ? 0 : key[ 0 ]; break;
      case 'ArrowDown': case 'KeyS': key[ 0 ] = key[ 0 ] > 0 ? 0 : key[ 0 ]; break;
      case 'ArrowLeft': case 'KeyA': case 'KeyQ': key[ 1 ] = key[ 1 ] < 0 ? 0 : key[ 1 ]; break;
      case 'ArrowRight': case 'KeyD': key[ 1 ] = key[ 1 ] > 0 ? 0 : key[ 1 ]; break;
      case 'ShiftLeft' : case 'ShiftRight' : key[ 2 ] = 0; break;
	  }
	}
}
