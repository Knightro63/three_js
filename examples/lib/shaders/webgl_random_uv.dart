import 'dart:async';
import 'dart:math' as math;
import 'package:example/src/gui.dart';
import 'package:flutter/material.dart';
import 'package:example/src/statistics.dart';
import 'package:three_js/three_js.dart' as three;

class WebglRandomUV extends StatefulWidget {
  const WebglRandomUV({super.key});
  @override
  createState() => _State();
}

class _State extends State<WebglRandomUV> {
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
        toneMappingExposure: 0.7,
        enableShadowMap: true,
        shadowMapType: three.VSMShadowMap,
        animate: false,
        
      )
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

  late final three.DirectionalLight dirLight;
  late final three.Mesh ground;
  late final three.Material material;
  late final three.Material materialIn;

  late final Map<String, dynamic> uniforms;
  late final Map<String, dynamic> uniformsIn;

  Future<void> setup() async {
    threeJs.camera = three.PerspectiveCamera( 45, threeJs.width / threeJs.height, 0.1, 20 );
    threeJs.camera.position.setValues( - 0.8, 0.6, 1.5 );

    threeJs.scene = three.Scene();

    dirLight = three.DirectionalLight( 0xFFFFFF, 3 );
    dirLight.position.setValues( - 0.5, 1, 0.8 );
    dirLight.castShadow = true;
    threeJs.scene.add( dirLight );
    final shadow = dirLight.shadow;
    shadow?.mapSize.width = shadow.mapSize.height = 1024;
    shadow?.radius = 16;
    shadow?.bias = - 0.0005;
    final shadowCam = shadow?.camera;
    const double s = 2;
    shadowCam?.near = 0.5;
    shadowCam?.far = 3;
    shadowCam?.right = s;
    shadowCam?.top = s;
    shadowCam?.left = - s;
    shadowCam?.bottom = - s;

    // add ground plane
    final plane = three.PlaneGeometry( 2, 2 );
    plane.rotateX( - math.pi * 0.5 );
    ground = three.Mesh( plane, three.ShadowMaterial.fromMap( { 'opacity': 0.5 } ) );
    ground.receiveShadow = true;
    ground.position.z = - 0.5;
    threeJs.scene.add( ground );

    final three.TextureLoader tl = three.TextureLoader();

    final map = await tl.fromAsset('assets/textures/jade.jpg' );
    map?.colorSpace = three.SRGBColorSpace;
    map?.wrapS = map.wrapT = three.RepeatWrapping;
    map?.repeat.setValues( 20, 20 );
    map?.flipY = false;

    final disolveMap = await tl.fromAsset( 'assets/textures/shaderball_ds.jpg' );
    disolveMap?.flipY = false;

    final noise = await tl.fromAsset( 'assets/textures/noise.png' );

    await three.RGBELoader().setPath( 'assets/textures/equirectangular/' ).fromAsset( 'moonless_golf_1k.hdr').then (( texture ) {
      final dataTexture = texture as three.DataTexture;
      dataTexture.mapping = three.EquirectangularReflectionMapping;
      print(dataTexture.image.data.runtimeType);
      threeJs.scene.background = dataTexture;
      threeJs.scene.environment = dataTexture;
      threeJs.scene.backgroundBlurriness = 0.5;
      threeJs.scene.backgroundIntensity = 0.15;
      threeJs.scene.environmentIntensity = 0.15;

      render();
    });

    final loader = three.GLTFLoader().setPath( 'assets/models/gltf/ShaderBall2/' );
    await loader.fromAsset( 'ShaderBall2.gltf').then(( gltf ) {
      final shaderBall = gltf!.scene.children[ 0 ];

      // shaderBall is a group with 3 children : base, inside and logo
      // ao map is include in model

      int i = shaderBall.children.length, n = 0;

      while ( i > 0) {
        i--;
        shaderBall.children[ i ].receiveShadow = true;
        shaderBall.children[ i ].castShadow = true;
        shaderBall.children[ i ].renderOrder = n ++;
      }

      material = shaderBall.children[ 0 ].material!;
      material.map = map;
      material.alphaMap = disolveMap;
      material.transparent = true;

      materialIn = shaderBall.children[ 1 ].material!;
      materialIn.alphaMap = disolveMap;
      materialIn.transparent = true;

      material.onBeforeCompile = (shader,r) {
        shader.uniforms[ 'disolve' ] = { 'value': 0.0 };
        shader.uniforms[ 'threshold' ] = { 'value': 0.2 };

        shader.uniforms[ 'noiseMap' ] = { 'value': noise };
        shader.uniforms[ 'enableRandom' ] = { 'value': 1.0 };
        shader.uniforms[ 'useNoiseMap' ] = { 'value': 1.0 };
        shader.uniforms[ 'useSuslikMethod' ] = { 'value': 0.0 };
        shader.uniforms[ 'debugNoise' ] = { 'value': 0.0 };

        shader.fragmentShader = shader.fragmentShader?.replaceAll( '#include <clipping_planes_pars_fragment>', '#include <clipping_planes_pars_fragment>$randomUV');
        shader.fragmentShader = shader.fragmentShader?.replaceAll( '#include <map_fragment>', mapFragment );

        // for disolve
        shader.fragmentShader = shader.fragmentShader?.replaceAll( '#include <alphamap_pars_fragment>', alphamapParsFragment );
        shader.fragmentShader = shader.fragmentShader?.replaceAll( '#include <alphamap_fragment>', alphamapFragment );

        uniforms = shader.uniforms;
      };

      materialIn.onBeforeCompile = (shader,r) {
        shader.uniforms[ 'disolve' ] = { 'value': 0.0 };
        shader.uniforms[ 'threshold' ] = { 'value': 0.2 };
        // for disolve
        shader.fragmentShader = shader.fragmentShader?.replaceAll( '#include <alphamap_pars_fragment>', alphamapParsFragment );
        shader.fragmentShader = shader.fragmentShader?.replaceAll( '#include <alphamap_fragment>', alphamapFragment );

        uniformsIn = shader.uniforms;
      };

      threeJs.scene.add( shaderBall );

      render();
      createGUI();
    });
      

    final controls = three.OrbitControls( threeJs.camera, threeJs.globalKey );
    controls.addEventListener( 'change', render ); // use if there is no animation loop
    controls.minDistance = 0.3;
    controls.maxDistance = 10;
    controls.target.setValues( 0, 0.4, 0 );
    controls.update();
  }

  void createGUI() {
    final Map<String,dynamic> map = {
      'roughness': material.roughness,
      'metalness': material.metalness,
      'disolve': uniforms['disolve']['value'],
      'threshold': uniforms['threshold']['value'],
      'Enabled': uniforms['enableRandom']['value'] != 0? true : false,
      'UseNoiseMap': uniforms['useNoiseMap']['value'] != 0? true : false,
      'SuslikMethod': uniforms['useSuslikMethod']['value'] != 0? true : false,
      'DebugNoise': uniforms['debugNoise']['value'] != 0? true : false,
    };

    final gui = panel.addFolder('GUI')..open();
    gui.addSlider( map, 'roughness', 0, 1, 0.01 ).onChange((v){
      material.roughness = v; 
      render();
    });
    gui.addSlider( map, 'metalness', 0, 1, 0.01 ).onChange((v){
      material.metalness = v; 
      render();
    });
    gui.addSlider( map, 'disolve', 0, 1, 0.01 ).onChange((v){
      uniforms['disolve']['value'] = v; 
      uniformsIn['disolve']['value'] = v; 
      ground.material?.opacity = ( 1 - v ) * 0.5; 
      render();
    });
    gui.addSlider( map, 'threshold', 0, 1, 0.01 ).onChange((v){
      uniforms['threshold']['value'] = v; 
      uniformsIn['threshold']['value'] = v; 
      render();
    });
    gui.addButton( map, 'Enabled' ).onChange((v){
      uniforms['enableRandom']['value'] = v ? 1.0 : 0.0; 
      render();
    });
    gui.addButton( map, 'UseNoiseMap' ).onChange((v){
      uniforms['useNoiseMap']['value'] = v ? 1.0 : 0.0;
      render();
    });
    gui.addButton( map, 'SuslikMethod' ).onChange((v){
      uniforms['useSuslikMethod']['value'] = v ? 1.0 : 0.0;
      render();
    });
    gui.addButton( map, 'DebugNoise' ).onChange((v){
      uniforms['debugNoise']['value'] = v ? 1.0 : 0.0;
      render();
    });
  }

  void render([t]){
    threeJs.render();
  }

  final randomUV = '''
  uniform sampler2D noiseMap;
  uniform float enableRandom;
  uniform float useNoiseMap;
  uniform float debugNoise;
  uniform float useSuslikMethod;

  float directNoise(vec2 p){
      vec2 ip = floor(p);
      vec2 u = fract(p);
      u = u*u*(3.0-2.0*u);

      float res = mix(
          mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
          mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
      return res*res;
  }

  float sum( vec4 v ) { return v.x+v.y+v.z; }

  vec4 textureNoTile( sampler2D mapper, in vec2 uv ){

      // sample variation pattern
      float k = 0.0;
      if( useNoiseMap == 1.0 ) k = texture2D( noiseMap, 0.005*uv ).x;
      else k = directNoise( uv );

      // compute index
      float index = k*8.0;
      float f = fract( index );
      float ia = 0.0;
      float ib = 0.0;

      if( useSuslikMethod == 1.0 ){
        ia = floor(index+0.5);
        ib = floor(index);
        f = min(f, 1.0-f)*2.0;
      } else {
        ia = floor( index );
        ib = ia + 1.0;
      }

      // offsets for the different virtual patterns
      vec2 offa = sin(vec2(3.0,7.0)*ia); // can replace with any other hash
      vec2 offb = sin(vec2(3.0,7.0)*ib); // can replace with any other hash

      // compute derivatives for mip-mapping
      vec2 dx = dFdx(uv);
      vec2 dy = dFdy(uv);

      // sample the two closest virtual patterns
      vec4 cola = textureGrad( mapper, uv + offa, dx, dy );
      vec4 colb = textureGrad( mapper, uv + offb, dx, dy );
      if( debugNoise == 1.0 ){
        cola = vec4( 0.1,0.0,0.0,1.0 );
        colb = vec4( 0.0,0.0,1.0,1.0 );
      }

      // interpolate between the two virtual patterns
      return mix( cola, colb, smoothstep(0.2,0.8,f-0.1*sum(cola-colb)) );

  }''';

  final mapFragment = /* glsl */ '''
  #ifdef USE_MAP

    if( enableRandom == 1.0 ) diffuseColor *= textureNoTile( map, vMapUv );
    else diffuseColor *= texture2D( map, vMapUv );

  #endif
  ''';

  final alphamapParsFragment = /* glsl */ '''
  #ifdef USE_ALPHAMAP
    uniform sampler2D alphaMap;
    uniform float disolve;
    uniform float threshold;
  #endif
  ''';

  final alphamapFragment = /* glsl */ '''
  #ifdef USE_ALPHAMAP
      float vv = texture2D( alphaMap, vAlphaMapUv ).g;
      float r = disolve * (1.0 + threshold * 2.0) - threshold;
      float mixf = clamp((vv - r)*(1.0/threshold), 0.0, 1.0);
    diffuseColor.a = mixf;
  #endif
  ''';
}
