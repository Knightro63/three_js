import 'dart:math' as math;
import 'package:three_js_advanced_loaders/md2/md2_loader.dart';
import 'package:three_js_advanced_loaders/md2/morph_anim_mesh.dart';
import 'package:three_js_animations/three_js_animations.dart';
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_core_loaders/three_js_core_loaders.dart';
import 'package:three_js_math/three_js_math.dart';

class MD2LoadData{
  MD2LoadData({
    this.path = '',
    this.weapons = const [],
    this.skins = const [],
    required this.body
  });

  String path;
  List<List<String>> weapons;
  List<String> skins;
  String body;
}

class MD2Character {
	double scale = 1;
	int animationFPS = 6;
	Object3D root = Object3D();
	MorphAnimMesh? meshBody;
	MorphAnimMesh? meshWeapon;

  List<Texture> skinsBody = [];
  List<Texture> skinsWeapon = [];

  List<MorphAnimMesh> weapons = [];
  AnimationAction? activeAnimation;
  AnimationMixer? mixer;
  void Function()? onLoadComplete;
  int loadCounter = 0;

  AnimationClip? activeClip;

	MD2Character();

	Future<void> loadParts(MD2LoadData config ) async{
		MorphAnimMesh createPart(MD2LoaderData data, Texture skinMap) {
			final materialWireframe = MeshLambertMaterial.fromMap( { 'color': 0xffaa00, 'wireframe': true } );
			final materialTexture = MeshLambertMaterial.fromMap( { 'color': 0xffffff, 'wireframe': false, 'map': skinMap } );

			final mesh = MorphAnimMesh( data.geometry, materialTexture );
			mesh.rotation.y = - math.pi / 2;
      mesh.animations = data.animations;

			mesh.castShadow = true;
			mesh.receiveShadow = true;

			mesh.materialTexture = materialTexture;
			mesh.materialWireframe = materialWireframe;

			return mesh;
		}

		void checkLoadingComplete() {
			loadCounter -= 1;
			if ( loadCounter == 0 ) onLoadComplete?.call();
		}

		Future<List<Texture>> loadTextures( baseUrl, textureUrls ) async{
			final textureLoader = TextureLoader();
      textureLoader.flipY = true;
			final List<Texture> textures = [];

			for (int i = 0; i < textureUrls.length; i ++ ) {
        final text = await textureLoader.unknown( baseUrl + textureUrls[ i ]);
        checkLoadingComplete();
        if(text != null){
          textures.add(text);
          textures[i].mapping = UVMapping;
          textures[i].name = textureUrls[ i ];
          textures[i].colorSpace = SRGBColorSpace;
        }
			}

			return textures;
		}

	  loadCounter = config.weapons.length * 2 + config.skins.length + 1;

		final weaponsTextures = [];
		for (int i = 0; i < config.weapons.length; i ++ ){ 
      weaponsTextures.add(config.weapons[ i ][ 1 ]);
    }
		// SKINS

		skinsBody = await loadTextures('${config.path }skins/', config.skins );
		skinsWeapon = await loadTextures('${config.path}skins/', weaponsTextures );

		// BODY

		final loader = MD2Loader();

		await loader.unknown( config.path + config.body).then( ( data ) {
			final boundingBox = BoundingBox();
			boundingBox.setFromBuffer( data!.geometry.attributes['position'] );

			root.position.y = - scale * boundingBox.min.y;

			final mesh = createPart( data, skinsBody[ 0 ] );
			mesh.scale.setValues( scale, scale, scale );

			root.add( mesh );
			meshBody = mesh;

			meshBody?.clipOffset = 0;
			activeClip = mesh.animations.isNotEmpty?mesh.animations[0]:null;

			mixer = AnimationMixer( mesh );
			checkLoadingComplete();
		});

		// WEAPONS
		for (int i = 0; i < config.weapons.length; i ++ ) {
			await loader.unknown( config.path + config.weapons[i][0]).then((geo){
				final mesh = createPart( geo!, skinsWeapon[ i ] );
				mesh.scale.setValues( scale, scale, scale );
				mesh.visible = false;
				mesh.name = config.weapons[ i ][0];
				root.add( mesh );
				weapons.add(mesh);
				meshWeapon = mesh;
				checkLoadingComplete();
      });
		}
	}

	void setPlaybackRate(double rate ) {
		if ( rate != 0 ) {
			mixer?.timeScale = 1 / rate;
		} 
    else {
			mixer?.timeScale = 0;
		}
	}

	void setWireframe(bool wireframeEnabled ) {
		if ( wireframeEnabled ) {
			if ( meshBody != null) meshBody?.material = meshBody?.materialWireframe;
			if ( meshWeapon != null) meshWeapon?.material = meshWeapon?.materialWireframe;
		} 
    else {
			if ( meshBody != null) meshBody?.material = meshBody?.materialTexture;
			if ( meshWeapon != null) meshWeapon?.material = meshWeapon?.materialTexture;
		}
	}

	void setSkin(int index ) {
		if ( meshBody != null && meshBody?.material?.wireframe == false ) {
			meshBody?.material?.map = skinsBody[ index ];
		}
	}

	void setWeapon(int index ) {
		for (int i = 0; i < weapons.length; i ++ ){
      weapons[ i ].visible = false;
    }
		final activeWeapon = weapons[ index ];
		//if ( activeWeapon ) {
			activeWeapon.visible = true;
			meshWeapon = activeWeapon;
			syncWeaponAnimation();
		//}
	}

	void setAnimation(AnimationClip clipName ) {
		if ( meshBody != null) {
			meshBody?.activeAction?.stop();
			meshBody?.activeAction = null;

			final action = mixer?.clipAction( clipName, meshBody );

			if ( action != null) {
				meshBody?.activeAction = action.play();
			}
		}
		activeClip = clipName;
		syncWeaponAnimation();
	}

	void syncWeaponAnimation() {
		final clip = activeClip;

		if (meshWeapon != null) {
			meshWeapon?.activeAction?.stop();
			meshWeapon?.activeAction = null;
			
			final action = mixer?.clipAction( clip, meshWeapon );

			if ( action != null) {
				meshWeapon?.activeAction = action.syncWith( meshBody!.activeAction! ).play();
			}
		}
	}

	void update(double delta ) {
		mixer?.update( delta );
	}
}
