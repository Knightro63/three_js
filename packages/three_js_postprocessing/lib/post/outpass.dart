import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'package:three_js_postprocessing/post/index.dart';
import 'package:three_js_postprocessing/shaders/outpass_shader.dart';
import 'pass.dart';

class OutputPass extends Pass {
  int? _toneMapping;
  String? _outputColorSpace;

  final _LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 = Matrix3.identity().setValues(
    0.8224621, 0.177538, 0.0,
    0.0331941, 0.9668058, 0.0,
    0.0170827, 0.0723974, 0.9105199,
  );

  final _LINEAR_DISPLAY_P3_TO_LINEAR_SRGB = /*@__PURE__*/ Matrix3.identity().setValues(
    1.2249401, - 0.2249404, 0.0,
    - 0.0420569, 1.0420571, 0.0,
    - 0.0196376, - 0.0786361, 1.0982735
  );

  late final Map<String,dynamic> _COLOR_SPACES = {
    'LinearSRGBColorSpace': {
      'transfer': LinearTransfer,
      'primaries': Rec709Primaries,
      'toReference': ( color ) => color,
      'fromReference': ( color ) => color,
    },
    'SRGBColorSpace': {
      'transfer': SRGBTransfer,
      'primaries': Rec709Primaries,
      'toReference': (Color color ) => color.convertSRGBToLinear(),
      'fromReference': (Color color ) => color.convertLinearToSRGB(),
    },
    'LinearDisplayP3ColorSpace': {
      'transfer': LinearTransfer,
      'primaries': P3Primaries,
      'toReference': (Color color ) => color.applyMatrix3( _LINEAR_DISPLAY_P3_TO_LINEAR_SRGB ),
      'fromReference': (Color color ) => color.applyMatrix3( _LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 ),
    },
    'DisplayP3ColorSpace': {
      'transfer': SRGBTransfer,
      'primaries': P3Primaries,
      'toReference': (Color color ) => color.convertSRGBToLinear().applyMatrix3( _LINEAR_DISPLAY_P3_TO_LINEAR_SRGB ),
      'fromReference': (Color color ) => color.applyMatrix3( _LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 ).convertLinearToSRGB(),
    },
  };

	OutputPass():super(){
		const Map<String, dynamic> shader = outputShader;

		uniforms = UniformsUtils.clone(shader['uniforms']);

		material = RawShaderMaterial.fromMap( {
			'name': shader['name'],
			'uniforms': uniforms,
			'vertexShader': shader['vertexShader'],
			'fragmentShader': shader['fragmentShader']
		} );

		fsQuad = FullScreenQuad(material );
	}

	String? getTransfer(colorSpace) {
		if ( colorSpace == NoColorSpace ) return LinearTransfer;
		return _COLOR_SPACES[ colorSpace ]?['transfer'];
	}

  @override
	void render(WebGLRenderer renderer, WebGLRenderTarget writeBuffer, WebGLRenderTarget readBuffer, {double? deltaTime, bool? maskActive}) {
		uniforms['tDiffuse']['value'] = readBuffer.texture;
		uniforms['toneMappingExposure']['value'] = renderer.toneMappingExposure;

		// rebuild defines if required

		if (_outputColorSpace != renderer.outputColorSpace || _toneMapping != renderer.toneMapping ) {
			_outputColorSpace = renderer.outputColorSpace;
			_toneMapping = renderer.toneMapping;

			material.defines = {};

			if (_outputColorSpace == SRGBTransfer ) material.defines!['SRGB_TRANSFER'] = '';
      
			if (_toneMapping == LinearToneMapping ){ material.defines!['LINEAR_TONE_MAPPING'] = '';}
			else if (_toneMapping == ReinhardToneMapping ){ material.defines!['REINHARD_TONE_MAPPING'] = '';}
			else if (_toneMapping == CineonToneMapping ){ material.defines!['CINEON_TONE_MAPPING'] = '';}
			else if (_toneMapping == ACESFilmicToneMapping ){ material.defines!['ACES_FILMIC_TONE_MAPPING'] = '';}
      else if (_toneMapping == AgXToneMapping ) this.material.defines!['AGX_TONE_MAPPING'] = '';
			else if (_toneMapping == NeutralToneMapping ){ material.defines!['NEUTRAL_TONE_MAPPING'] = '';}
			else if (_toneMapping == CustomToneMapping ){ material.defines!['CUSTOM_TONE_MAPPING'] = '';}

			material.needsUpdate = true;
		}

		if (renderToScreen) {
			renderer.setRenderTarget( null );
			fsQuad.render( renderer );
		} 
    else {
			renderer.setRenderTarget( writeBuffer );
			if (clear) renderer.clear( renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil );
			fsQuad.render( renderer );
		}
	}

	void dispose() {
		material.dispose();
		fsQuad.dispose();
	}
}
