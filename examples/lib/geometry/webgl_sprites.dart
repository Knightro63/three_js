import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/statistics.dart';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;

class WebglSprites extends StatefulWidget {
  
  const WebglSprites({super.key});

  @override
  createState() => _State();
}

class _State extends State<WebglSprites> {
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
      windowResizeUpdate: (size){
        final width = size.width;
        final height = size.height;

        threeJs.camera.aspect = width / height;
        threeJs.camera.updateProjectionMatrix();

        cameraOrtho.left = - width / 2;
        cameraOrtho.right = width / 2;
        cameraOrtho.top = height / 2;
        cameraOrtho.bottom = - height / 2;
        cameraOrtho.updateProjectionMatrix();

        updateHUDSprites();
      }
    );
    super.initState();
  }
  @override
  void dispose() {
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

  late three.OrthographicCamera cameraOrtho;
  late three.Scene sceneOrtho;
  late three.Texture mapC;
  late three.Group group;
  late three.Sprite spriteTL, spriteTR, spriteBL, spriteBR, spriteC;

  Future<void> setup() async {
    final width = threeJs.width;
    final height = threeJs.height;

    threeJs.camera = three.PerspectiveCamera( 60, width / height, 1, 2100 );
    threeJs.camera.position.z = 1500;

    cameraOrtho = three.OrthographicCamera( - width / 2, width / 2, height / 2, - height / 2, 1, 10 );
    cameraOrtho.position.z = 10;

    threeJs.scene = three.Scene();
    threeJs.scene.fog = three.Fog( 0x000000, 1500, 2100 );

    sceneOrtho = three.Scene();

    // create sprites

    const amount = 200;
    const radius = 500.0;

    final textureLoader = three.TextureLoader();

    final texture = (await textureLoader.fromAsset( 'assets/textures/sprite0.png'))!;
    createHUDSprites(texture);

    final mapB = await textureLoader.fromAsset( 'assets/textures/sprite1.png' );
    mapC = (await textureLoader.fromAsset( 'assets/textures/sprite2.png' ))!;

    // mapB.colorSpace = three.SRGBColorSpace;
    // mapC.colorSpace = three.SRGBColorSpace;

    group = three.Group();

    final materialC = three.SpriteMaterial.fromMap( { 'map': mapC, 'color': 0xffffff, 'fog': true } );
    final materialB = three.SpriteMaterial.fromMap( { 'map': mapB, 'color': 0xffffff, 'fog': true } );

    for ( int a = 0; a < amount; a ++ ) {

      final x = math.Random().nextDouble() - 0.5;
      final y = math.Random().nextDouble() - 0.5;
      final z = math.Random().nextDouble() - 0.5;

      three.Material material;

      if ( z < 0 ) {
        material = materialB.clone();
      } 
      else {
        material = materialC.clone();
        material.color.setHSL( 0.5 * math.Random().nextDouble(), 0.75, 0.5 );
        material.map?.offset.setValues( - 0.5, - 0.5 );
        material.map?.repeat.setValues( 2, 2 );
      }

      final sprite = three.Sprite( material );

      sprite.position.setValues( x, y, z );
      sprite.position.normalize();
      sprite.position.scale( radius );

      group.add( sprite );
    }

    threeJs.scene.add( group );

    threeJs.renderer?.autoClear = false; // To allow render overlay on top of sprited sphere

    threeJs.postProcessor = render;
  }

   void createHUDSprites(three.Texture texture ) {
    //texture.colorSpace = three.SRGBColorSpace;

    final material = three.SpriteMaterial.fromMap( { 'map': texture } );

    final width = material.map?.image.width?.toDouble();
    final height = material.map?.image.height?.toDouble();

    spriteTL = three.Sprite( material );
    spriteTL.center.setValues( 0.0, 1.0 );
    spriteTL.scale.setValues( width, height, 1 );
    sceneOrtho.add( spriteTL );

    spriteTR = three.Sprite( material );
    spriteTR.center.setValues( 1.0, 1.0 );
    spriteTR.scale.setValues( width, height, 1 );
    sceneOrtho.add( spriteTR );

    spriteBL = three.Sprite( material );
    spriteBL.center.setValues( 0.0, 0.0 );
    spriteBL.scale.setValues( width, height, 1 );
    sceneOrtho.add( spriteBL );

    spriteBR = three.Sprite( material );
    spriteBR.center.setValues( 1.0, 0.0 );
    spriteBR.scale.setValues( width, height, 1 );
    sceneOrtho.add( spriteBR );

    spriteC = three.Sprite( material );
    spriteC.center.setValues( 0.5, 0.5 );
    spriteC.scale.setValues( width, height, 1 );
    sceneOrtho.add( spriteC );

    updateHUDSprites();
  }

  void updateHUDSprites() {
    final width = threeJs.width / 2;
    final height = threeJs.height / 2;

    spriteTL.position.setValues( - width, height, 1 ); // top left
    spriteTR.position.setValues( width, height, 1 ); // top right
    spriteBL.position.setValues( - width, - height, 1 ); // bottom left
    spriteBR.position.setValues( width, - height, 1 ); // bottom right
    spriteC.position.setValues( 0, 0, 1 ); // center
  }

  void render([double? dt]) {

    final time = DateTime.now().millisecondsSinceEpoch / 1000;

    for (int i = 0, l = group.children.length; i < l; i ++ ) {

      final sprite = group.children[ i ];
      final material = sprite.material;
      final scale = math.sin( time + sprite.position.x * 0.01 ) *  0.001;

      int imageWidth = 1;
      int imageHeight = 1;

      imageWidth = material?.map?.image.width;
      imageHeight = material?.map?.image.height;

      sprite.material?.rotation += 0.1 * ( i / l );
      sprite.scale.setValues( scale * imageWidth, scale * imageHeight, 1.0 );

      if ( material?.map != mapC ) {
        material?.opacity = math.sin( time + sprite.position.x * 0.01 ) * 0.4 + 0.6;
      }

    }

    group.rotation.x = time * 0.5;
    group.rotation.y = time * 0.75;
    group.rotation.z = time * 1.0;

    threeJs.renderer!.clear();
    threeJs.renderer!.render( threeJs.scene, threeJs.camera );
    threeJs.renderer!.clearDepth();
    threeJs.renderer!.render( sceneOrtho, cameraOrtho );
  }
}
