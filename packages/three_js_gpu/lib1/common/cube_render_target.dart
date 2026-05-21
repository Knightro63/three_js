import 'package:three_js_core/renderers/index.dart';
import 'package:three_js_core/three_js_core.dart' as core;
import 'package:three_js_gpu/common/renderer.dart';
import 'package:three_js_math/three_js_math.dart';

class CubeRenderTarget extends core.CubeRenderTarget {
  
	CubeRenderTarget([super.size = 1, super.options]);

  @override
	CubeRenderTarget fromEquirectangularTexture(Renderer renderer, core.Texture texture ) {

		final currentMinFilter = texture.minFilter;
		final currentGenerateMipmaps = texture.generateMipmaps;

		texture.generateMipmaps = true;

		this.texture.type = texture.type;
		this.texture.colorSpace = texture.colorSpace;

		this.texture.generateMipmaps = texture.generateMipmaps;
		this.texture.minFilter = texture.minFilter;
		this.texture.magFilter = texture.magFilter;

		final geometry = core.BoxGeometry( 5, 5, 5 );

		final uvNode = equirectUV( positionWorldDirection );

		final material = NodeMaterial();
		material.colorNode = TSL_Texture( texture, uvNode, 0 );
		material.side = BackSide;
		material.blending = NoBlending;

		final mesh = core.Mesh( geometry, material );

		final scene = core.Scene();
		scene.add( mesh );

		// Avoid blurred poles
		if ( texture.minFilter == LinearMipmapLinearFilter ) texture.minFilter = LinearFilter;

		final camera = core.CubeCamera( 1, 10, this );

		final currentMRT = renderer.getMRT();
		renderer.setMRT( null );

		camera.update( renderer, scene );

		renderer.setMRT( currentMRT );

		texture.minFilter = currentMinFilter;
		texture.currentGenerateMipmaps = currentGenerateMipmaps;

		mesh.geometry?.dispose();
		mesh.material?.dispose();

		return this;
	}
}
