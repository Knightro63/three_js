import 'dart:js_interop';
import 'dart:math' as math;
import 'package:web/web.dart' as html;
import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';

class LightProbeGenerator {
	// https://www.ppsloan.org/publications/StupidSH36.pdf
	static LightProbe fromCubeTexture(CubeTexture cubeTexture ) {
		double totalWeight = 0;

		final coord = Vector3();
		final dir = Vector3();
		final color = Color();
		final List<double> shBasis = [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
		final sh = SphericalHarmonics3();
		final shCoefficients = sh.coefficients;

		for (int faceIndex = 0; faceIndex < 6; faceIndex ++ ) {
			final image = cubeTexture.image[ faceIndex ];

			final width = image.width;
			final height = image.height;


      final html.CanvasElement canvas = html.document.createElement( 'canvas' ) as html.CanvasElement;

      canvas.width = width;
      canvas.height = height;

      final html.CanvasRenderingContext2D context = canvas.getContext( '2d' ) as html.CanvasRenderingContext2D;

      context.drawImage( image.data, 0, 0);

      final imageData = context.getImageData( 0, 0, width, height );
      final data = imageData.data.toDart;
      final imageWidth = imageData.width; // assumed to be square
      final pixelSize = 2 / imageWidth;

			for (int i = 0, il = data.length; i < il; i += 4 ) { // RGBA assumed
				// pixel color
				color.setRGB( data[ i ] / 255, data[ i + 1 ] / 255, data[ i + 2 ] / 255 );

				// convert to linear color space
				convertColorToLinear( color, cubeTexture.colorSpace );

				// pixel coordinate on unit cube

				final pixelIndex = i / 4;
				final col = - 1 + ( pixelIndex % imageWidth + 0.5 ) * pixelSize;
				final row = 1 - ( ( pixelIndex / imageWidth ).floor() + 0.5 ) * pixelSize;

				switch ( faceIndex ) {
					case 0: coord.setValues( - 1, row, - col ); break;
					case 1: coord.setValues( 1, row, col ); break;
					case 2: coord.setValues( - col, 1, - row ); break;
					case 3: coord.setValues( - col, - 1, row ); break;
					case 4: coord.setValues( - col, row, 1 ); break;
					case 5: coord.setValues( col, row, - 1 ); break;
				}

				// weight assigned to this pixel

				final lengthSq = coord.length2;
				final weight = 4 / ( math.sqrt( lengthSq ) * lengthSq );

				totalWeight += weight;

				// direction vector to this pixel
				dir.setFrom( coord ).normalize();

				// evaluate SH basis functions in direction dir
				SphericalHarmonics3.getBasisAt( dir, shBasis );

				// accummuulate
				for (int j = 0; j < 9; j ++ ) {
					shCoefficients[ j ].x += shBasis[ j ] * color.red * weight;
					shCoefficients[ j ].y += shBasis[ j ] * color.green * weight;
					shCoefficients[ j ].z += shBasis[ j ] * color.blue * weight;
				}
			}
		}

		// normalize
		final norm = ( 4 * math.pi ) / totalWeight;

		for (int j = 0; j < 9; j ++ ) {
			shCoefficients[ j ].x *= norm;
			shCoefficients[ j ].y *= norm;
			shCoefficients[ j ].z *= norm;
		}

		return LightProbe( sh );
	}

	static LightProbe fromCubeRenderTarget(WebGLRenderer renderer,WebGLCubeRenderTarget cubeRenderTarget ) {
		// The renderTarget must be set to RGBA in order to make readRenderTargetPixels works
		double totalWeight = 0;
		final coord = Vector3();
		final dir = Vector3();
		final color = Color();
		final List<double> shBasis = [ 0, 0, 0, 0, 0, 0, 0, 0, 0 ];

		final sh = SphericalHarmonics3();
		final shCoefficients = sh.coefficients;
		final dataType = cubeRenderTarget.texture.type;

		for (int faceIndex = 0; faceIndex < 6; faceIndex ++ ) {
			final imageWidth = cubeRenderTarget.width; // assumed to be square

			NativeArray data;

			if ( dataType == HalfFloatType ) {
				data = Uint16Array( imageWidth * imageWidth * 4 );
			} 
      else {
				// assuming UnsignedByteType
				data = Uint8Array( imageWidth * imageWidth * 4 );
			}

			renderer.readRenderTargetPixels( cubeRenderTarget, 0, 0, imageWidth, imageWidth, data, faceIndex );

			final pixelSize = 2 / imageWidth;

			for (int i = 0, il = data.length; i < il; i += 4 ) { // RGBA assumed
				double r, g, b;

				if ( dataType == HalfFloatType ) {
					r = MathUtils.fromHalfFloat( data[ i ] );
					g = MathUtils.fromHalfFloat( data[ i + 1 ] );
					b = MathUtils.fromHalfFloat( data[ i + 2 ] );
				} else {
					r = data[i] / 255;
					g = data[i + 1] / 255;
					b = data[i + 2] / 255;
				}

				// pixel color
				color.setRGB( r, g, b );

				// convert to linear color space
				convertColorToLinear( color, cubeRenderTarget.texture.colorSpace );

				// pixel coordinate on unit cube

				final pixelIndex = i / 4;
				final col = - 1 + ( pixelIndex % imageWidth + 0.5 ) * pixelSize;
				final row = 1 - (( pixelIndex / imageWidth ).floor() + 0.5 ) * pixelSize;

				switch ( faceIndex ) {
					case 0: coord.setValues( 1, row, - col ); break;
					case 1: coord.setValues( - 1, row, col ); break;
					case 2: coord.setValues( col, 1, - row ); break;
					case 3: coord.setValues( col, - 1, row ); break;
					case 4: coord.setValues( col, row, 1 ); break;
					case 5: coord.setValues( - col, row, - 1 ); break;
				}

				// weight assigned to this pixel

				final lengthSq = coord.length2;

				final weight = 4 / ( math.sqrt( lengthSq ) * lengthSq );

				totalWeight += weight;

				// direction vector to this pixel
				dir.setFrom( coord ).normalize();

				// evaluate SH basis functions in direction dir
				SphericalHarmonics3.getBasisAt( dir, shBasis );

				// accummuulate
				for (int j = 0; j < 9; j ++ ) {
					shCoefficients[ j ].x += shBasis[ j ] * color.red * weight;
					shCoefficients[ j ].y += shBasis[ j ] * color.green * weight;
					shCoefficients[ j ].z += shBasis[ j ] * color.blue * weight;
				}
			}
		}

		// normalize
		final norm = ( 4 * math.pi ) / totalWeight;

		for (int j = 0; j < 9; j ++ ) {
			shCoefficients[ j ].x *= norm;
			shCoefficients[ j ].y *= norm;
			shCoefficients[ j ].z *= norm;
		}

		return LightProbe( sh );
	}
}

Color convertColorToLinear(Color color, String colorSpace ) {
	switch ( colorSpace ) {
		case SRGBColorSpace:
			color.convertSRGBToLinear();
			break;
		case LinearSRGBColorSpace:
		case NoColorSpace:
			break;
		default:
			console.warning( 'WARNING: LightProbeGenerator convertColorToLinear() encountered an unsupported color space.' );
			break;
	}

	return color;
}
