import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_gpu/common/binding.dart';

int _id = 0;

/**
 * Represents a sampled texture binding type.
 *
 * @private
 * @augments Binding
 */
class SampledTexture extends Binding {
  int id = _id ++;
  Texture? texture;
  bool isSampledTexture = true;
  bool store = false;
  late int version;
  int? generation;


	SampledTexture(String name, [this.texture] ):super( name ) {
		this.version = texture != null? texture!.version : 0;
		this.generation = null;
	}

	/**
	 * Returns `true` whether this binding requires an update for the
	 * given generation.
	 *
	 * @param {number} generation - The generation.
	 * @return {boolean} Whether an update is required or not.
	 */
	bool needsBindingsUpdate(int generation ) {
		if ( generation != this.generation ) {
			this.generation = generation;
			return true;
		}

		return false;
	}

	/**
	 * Updates the binding.
	 *
	 * @return {boolean} Whether the texture has been updated and must be
	 * uploaded to the GPU.
	 */
	bool update() {
		final texture = this.texture;
    final version = this.version;
		if ( version != texture?.version ) {

			this.version = texture!.version;
			return true;
		}
		return false;
	}
}

/**
 * Represents a sampled array texture binding type.
 *
 * @private
 * @augments SampledTexture
 */
class SampledArrayTexture extends SampledTexture {
  bool isSampledArrayTexture = true;
	/**
	 * Constructs a new sampled array texture.
	 *
	 * @param {string} name - The sampled array texture's name.
	 * @param {?(DataArrayTexture|CompressedArrayTexture)} texture - The texture this binding is referring to.
	 */
	SampledArrayTexture(String name,[Texture? texture ]):super( name, texture );
}

/**
 * Represents a sampled 3D texture binding type.
 *
 * @private
 * @augments SampledTexture
 */
class Sampled3DTexture extends SampledTexture {
  bool isSampled3DTexture = true;
	/**
	 * Constructs a new sampled 3D texture.
	 *
	 * @param {string} name - The sampled 3D texture's name.
	 * @param {?Data3DTexture} texture - The texture this binding is referring to.
	 */
	Sampled3DTexture(String name, [Data3DTexture? texture] ):super( name, texture );
}

/**
 * Represents a sampled cube texture binding type.
 *
 * @private
 * @augments SampledTexture
 */
class SampledCubeTexture extends SampledTexture {
  bool isSampledCubeTexture = true;
	/**
	 * Constructs a new sampled cube texture.
	 *
	 * @param {string} name - The sampled cube texture's name.
	 * @param {?(CubeTexture|CompressedCubeTexture)} texture - The texture this binding is referring to.
	 */
	SampledCubeTexture( name, texture ):super( name, texture );
}
