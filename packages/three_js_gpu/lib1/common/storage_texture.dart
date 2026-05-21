import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

/**
 * This special type of texture is intended for compute shaders.
 * It can be used to compute the data of a texture with a compute shader.
 *
 * Note: This type of texture can only be used with `WebGPURenderer`
 * and a WebGPU backend.
 *
 * @augments Texture
 */
class StorageTexture extends Texture {
  int width;
  int height;

	StorageTexture([this.width = 1, this.height = 1 ]):super() {
		image = { width, height };
		magFilter = LinearFilter;
		minFilter = LinearFilter;
	}
}