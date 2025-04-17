import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderMd2 extends StatefulWidget {
  
  const WebglLoaderMd2({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglLoaderMd2> {
  List<int> data = List.filled(60, 0, growable: true);
  late Timer timer;
  late Gui wg;
  late three.ThreeJS threeJs;

  @override
  void initState() {
    wg = Gui((){setState(() {});});
    timer = Timer.periodic(const Duration(seconds: 1), (t){
      setState(() {
        data.removeAt(0);
        data.add(threeJs.clock.fps);
      });
    });
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        enableShadowMap: true,
        useOpenGL: useOpenGL
      )
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
          Statistics(data: data),
          if(threeJs.mounted)Positioned(
            top: 20,
            right: 20,
            child: SizedBox(
              height: threeJs.height,
              width: 240,
              child: wg.render(context)
            )
          )
        ],
      ) 
    );
  }

  late three.OrbitControls controls;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 40, threeJs.width / threeJs.height, 0.1, 100 );
    threeJs.camera.position.setValues( 0, 2, 4 );

    // SCENE
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32( 0x050505 );
    threeJs.scene.fog = three.Fog( 0x050505, 2.5, 10 );

    // LIGHTS

    threeJs.scene.add( three.AmbientLight( 0x666666, 1 ) );

    final light1 = three.SpotLight( 0xffffff, 25 );
    light1.position.setValues( 2, 5, 10 );
    light1.angle = 0.5;
    light1.penumbra = 0.5;

    //light1.castShadow = true;
    light1.shadow?.mapSize.width = 1024;
    light1.shadow?.mapSize.height = 1024;
    threeJs.scene.add( light1 );

    final light2 = three.SpotLight( 0xffffff, 25 );
    light2.position.setValues( - 1, 3.5, 3.5 );
    light2.angle = 0.5;
    light2.penumbra = 0.5;

    //light2.castShadow = true;
    light2.shadow?.mapSize.width = 1024;
    light2.shadow?.mapSize.height = 1024;
    threeJs.scene.add( light2 );

    //  GROUND

    final gt = await three.TextureLoader().fromAsset( 'assets/textures/terrain/grasslight-big.jpg' );
    final nm = await three.TextureLoader().fromAsset( 'assets/textures/terrain/grasslight-big-nm.jpg' );
    final gg = three.PlaneGeometry( 20, 20 );
    final gm = three.MeshPhongMaterial.fromMap({ 
      'color': 0xffffff, 
      'map': gt,
      'normalMap': nm,
    });

    final ground = three.Mesh( gg, gm );
    ground.rotation.x = - math.pi / 2;
    ground.material?.map?.repeat.setValues( 8, 8 );

    ground.material?.map?.wrapS = three.RepeatWrapping;
    ground.material?.map?.wrapT = three.RepeatWrapping;
    ground.material?.map?.colorSpace = three.SRGBColorSpace;
    ground.material?.normalMap?.wrapS = three.RepeatWrapping;
    ground.material?.normalMap?.wrapT = three.RepeatWrapping;
    ground.material?.normalMap?.colorSpace = three.SRGBColorSpace;
    ground.receiveShadow = true;

    threeJs.scene.add( ground );

    // CONTROLS
    controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.target.setValues( 0, 0.5, 0 );
    controls.update();

    // CHARACTER

    final config = three.MD2LoadData(
      path: 'assets/models/md2/ratamahatta/',
      body: 'ratamahatta.md2',
      skins: [ 'ratamahatta.png', 'ctf_b.png', 'ctf_r.png', 'dead.png', 'gearwhore.png' ],
      weapons: [[ 'weapon.md2', 'weapon.png' ],
        [ 'w_bfg.md2', 'w_bfg.png' ],
        [ 'w_blaster.md2', 'w_blaster.png' ],
        [ 'w_chaingun.md2', 'w_chaingun.png' ],
        [ 'w_glauncher.md2', 'w_glauncher.png' ],
        [ 'w_hyperblaster.md2', 'w_hyperblaster.png' ],
        [ 'w_machinegun.md2', 'w_machinegun.png' ],
        [ 'w_railgun.md2', 'w_railgun.png' ],
        [ 'w_rlauncher.md2', 'w_rlauncher.png' ],
        [ 'w_shotgun.md2', 'w_shotgun.png' ],
        [ 'w_sshotgun.md2', 'w_sshotgun.png' ]
      ]
    );

    final three.MD2Character character = three.MD2Character();

    final Map<String,dynamic> playbackConfig = {
      'speed': 1.0,
      'wireframe': false
    };

    final gui = wg.addFolder('GUI')..open();

    gui.addSlider( playbackConfig, 'speed', 0, 2 )..step(0.1)..onChange( (val) {
      playbackConfig['speed'] = val;
      character.setPlaybackRate(val);
    } );

    gui.addButton( playbackConfig, 'wireframe' ).onChange((val) {
      character.setWireframe( val );
    } );

    setupWeaponsGUI() {
      final folder = wg.addFolder( 'Weapons' );
      generateCallback( index ) {
        character.setWeapon( index );
        character.setWireframe( playbackConfig['wireframe'] );
      }

      for ( int i = 0; i < character.weapons.length; i ++ ) {
        final name = character.weapons[ i ].name;
        playbackConfig[ name ] = false;
        folder.addButton(playbackConfig,name).onChange((val){
          generateCallback( i );
        });//folder.add( playbackConfig, name ).name( labelize( name ) );
      }
    }
    setupSkinsGUI( ) {
      final folder = wg.addFolder( 'Skins' );

      generateCallback( index ) {
        character.setSkin( index );
      }

      for (int i = 0; i < character.skinsBody.length; i ++ ) {
        final name = character.skinsBody[ i ].name;

        playbackConfig[ name ] = false;
        folder.addButton(playbackConfig,name).onChange((val){
          generateCallback( i );
        });
      }
    }
    setupGUIAnimations() {
      final folder = wg.addFolder( 'Animations' );

      generateCallback ( animationClip ){
        character.setAnimation( animationClip );
      }

      final animations = character.meshBody!.animations;

      for (int i = 0; i < animations.length; i ++ ) {
        final clip = animations[ i ];

        playbackConfig[ clip.name ] = false;//generateCallback( clip );
        folder.addButton(playbackConfig,clip.name).onChange((val){
          generateCallback( clip );
        });//folder.addButton( playbackConfig, clip.name, clip.name);
      }
    }

    character.onLoadComplete = (){
      setupSkinsGUI();
      setupWeaponsGUI();
      setupGUIAnimations();
    };
    character.scale = 0.03;
    await character.loadParts( config );
    threeJs.scene.add( character.root );
    threeJs.addAnimationEvent((dt){
      controls.update();
    });


  }
}
