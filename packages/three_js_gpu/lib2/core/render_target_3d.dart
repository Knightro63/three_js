import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class RenderTarget3D extends RenderTarget {

	RenderTarget3D([super.width = 1, super.height = 1, int depth = 1, super.options]) {
    this.depth = depth;
		this.texture = new Data3DTexture( null, width, height, depth );
		this._setTextureOptions( options );
		this.texture.isRenderTargetTexture = true;
	}

	void _setTextureOptions([RenderTargetOptions? options]) {
    options ??= RenderTargetOptions();
		final values = RenderTargetOptions({
			'minFilter': LinearFilter,
			'generateMipmaps': false,
			'flipY': false,
			'internalFormat': null
    });

		if ( options.mapping != null ) values.mapping = options.mapping;
		if ( options.wrapS != null ) values.wrapS = options.wrapS;
		if ( options.wrapT != null ) values.wrapT = options.wrapT;
		if ( options.wrapR != null ) values.wrapR = options.wrapR;
		if ( options.magFilter != null ) values.magFilter = options.magFilter;
		if ( options.minFilter != null ) values.minFilter = options.minFilter;
		if ( options.format != null ) values.format = options.format;
		if ( options.type != null ) values.type = options.type;
		if ( options.anisotropy != null ) values.anisotropy = options.anisotropy;
		if ( options.colorSpace != null ) values.colorSpace = options.colorSpace;
		//if ( options.flipY != null ) values.flipY = options.flipY;
		if ( options.generateMipmaps != null ) values.generateMipmaps = options.generateMipmaps;
		if ( options.internalFormat != null ) values.internalFormat = options.internalFormat;

		for ( int i = 0; i < this.textures.length; i ++ ) {
			final texture = this.textures[ i ];
			texture.image.setValues( values );
		}
	}
}
