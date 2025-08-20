import 'package:three_js_animations/three_js_animations.dart';
import 'package:three_js_core/three_js_core.dart';

class MorphAnimMesh extends Mesh {
  //late AnimationMixer mixer;
  AnimationAction? activeAction;
  List<AnimationClip> animations = [];
  int clipOffset = 0;

  Material? materialWireframe;
  Material? materialTexture;

	MorphAnimMesh(super.geometry, super.material ) {
		type = 'MorphAnimMesh';
		//mixer = AnimationMixer(this);
	}

	// void setDirectionForward() {
	// 	mixer.timeScale = 1.0;
	// }

	// void setDirectionBackward() {
	// 	mixer.timeScale = - 1.0;
	// }

	// void playAnimation(String label, int fps) {
	// 	activeAction?.stop();
	// 	activeAction = null;
	
	// 	final clip = findByName(label);

	// 	if ( clip != null) {
	// 		final action = mixer.clipAction( clip );
	// 		action?.timeScale = ( clip.tracks.length * fps ) / clip.duration;
	// 		activeAction = action?.play();
	// 	} 
  //   else{
	// 		throw( 'MorphAnimMesh: animations[$label] undefined in .playAnimation()' );
	// 	}
	// }

	// AnimationClip? findByName(String name ) {
	// 	for (int i = 0; i < animations.length; i ++ ) {
	// 		if ( animations[i].name == name ) {
	// 			return animations[i];
	// 		}
	// 	}
	// 	return null;
	// }

	// void updateAnimation( delta ) {
	// 	mixer.update( delta );
	// }
  
  @override
  MorphAnimMesh copy(Object3D source, [bool? recursive ]) {
		super.copy( source, recursive );
    if(source is MorphAnimMesh){
      materialWireframe = source.materialWireframe;
      materialTexture = source.materialTexture;
      animations = source.animations.sublist(0);
    }
		//mixer = AnimationMixer( this );
		return this;
	}
}
