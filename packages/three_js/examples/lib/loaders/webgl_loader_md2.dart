import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglLoaderMd2 extends StatefulWidget {
  
  const WebglLoaderMd2({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglLoaderMd2> {
  late three.ThreeJS threeJs;

  @override
  void initState() {
    threeJs = three.ThreeJS(
      onSetupComplete: (){setState(() {});},
      setup: setup,
      settings: three.Settings(
        // enableShadowMap: true,
        // useSourceTexture: true
      )
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

      body: threeJs.build()
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

    threeJs.scene.add( three.AmbientLight( 0x666666 ) );

    final light1 = three.SpotLight( 0xffffff, 3 );
    light1.position.setValues( 2, 5, 10 );
    light1.angle = 0.5;
    light1.penumbra = 0.5;

    //light1.castShadow = true;
    light1.shadow?.mapSize.width = 1024;
    light1.shadow?.mapSize.height = 1024;
    threeJs.scene.add( light1 );

    final light2 = three.SpotLight( 0xffffff, 3 );
    light2.position.setValues( - 1, 3.5, 3.5 );
    light2.angle = 0.5;
    light2.penumbra = 0.5;

    //light2.castShadow = true;
    light2.shadow?.mapSize.width = 1024;
    light2.shadow?.mapSize.height = 1024;
    threeJs.scene.add( light2 );

    //  GROUND

    final gt = await three.TextureLoader().fromAsset( 'assets/textures/terrain/grasslight-big.jpg' );
    final gg = three.PlaneGeometry( 20, 20 );
    final gm = three.MeshPhongMaterial.fromMap( { 'color': 0xffffff, 'map': gt } );

    final ground = three.Mesh( gg, gm );
    ground.rotation.x = - math.pi / 2;
    ground.material?.map?.repeat.setValues( 8, 8 );
    ground.material?.map?.wrapS = three.RepeatWrapping;
    ground.material?.map?.wrapT = three.RepeatWrapping;
    ground.material?.map?.colorSpace = three.SRGBColorSpace;
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

    final character = three.MD2Character();
    character.scale = 0.03;

    await character.loadParts( config ).then((r){
      character.setAnimation( character.meshBody!.animations[ 12 ]);
      print(character.meshBody!.animations[ 1 ].name);
      character.setPlaybackRate( 1.0 );
      character.setWeapon( 3 );
    });
    threeJs.scene.add( character.root );

    threeJs.addAnimationEvent((dt){
      controls.update();
      character.update(dt);
    });
  }
}
