

final declarationRegexp = '/^[fn]*\s*([a-z_0-9]+)?\s*\(([\s\S]*?)\)\s*[\-\>]*\s*([a-z_0-9]+(?:<[\s\S]+?>)?)/i';
final propertiesRegexp = '/([a-z_0-9]+)\s*:\s*([a-z_0-9]+(?:<[\s\S]+?>)?)/ig';

final Map<String,String> wgslTypeLib = {
	'f32': 'float',
	'i32': 'int',
	'u32': 'uint',
	'bool': 'bool',

	'vec2<f32>': 'vec2',
 	'vec2<i32>': 'ivec2',
 	'vec2<u32>': 'uvec2',
 	'vec2<bool>': 'bvec2',

	'vec2f': 'vec2',
	'vec2i': 'ivec2',
	'vec2u': 'uvec2',
	'vec2b': 'bvec2',

	'vec3<f32>': 'vec3',
	'vec3<i32>': 'ivec3',
	'vec3<u32>': 'uvec3',
	'vec3<bool>': 'bvec3',

	'vec3f': 'vec3',
	'vec3i': 'ivec3',
	'vec3u': 'uvec3',
	'vec3b': 'bvec3',

	'vec4<f32>': 'vec4',
	'vec4<i32>': 'ivec4',
	'vec4<u32>': 'uvec4',
	'vec4<bool>': 'bvec4',

	'vec4f': 'vec4',
	'vec4i': 'ivec4',
	'vec4u': 'uvec4',
	'vec4b': 'bvec4',

	'mat2x2<f32>': 'mat2',
	'mat2x2f': 'mat2',

	'mat3x3<f32>': 'mat3',
	'mat3x3f': 'mat3',

	'mat4x4<f32>': 'mat4',
	'mat4x4f': 'mat4',

	'sampler': 'sampler',

	'texture_1d': 'texture',

	'texture_2d': 'texture',
	'texture_2d_array': 'texture',
	'texture_multisampled_2d': 'cubeTexture',

	'texture_depth_2d': 'depthTexture',
	'texture_depth_2d_array': 'depthTexture',
	'texture_depth_multisampled_2d': 'depthTexture',
	'texture_depth_cube': 'depthTexture',
	'texture_depth_cube_array': 'depthTexture',

	'texture_3d': 'texture3D',

	'texture_cube': 'cubeTexture',
	'texture_cube_array': 'cubeTexture',

	'texture_storage_1d': 'storageTexture',
	'texture_storage_2d': 'storageTexture',
	'texture_storage_2d_array': 'storageTexture',
	'texture_storage_3d': 'storageTexture'

};

Map<String,dynamic> parse(String source ){
	source = source.trim();

	final declaration = source.match( declarationRegexp );

	if ( declaration != null && declaration.length == 4 ) {

		final inputsCode = declaration[ 2 ];
		final propsMatches = [];
		dynamic match = null;

		while ( ( match = propertiesRegexp.exec( inputsCode ) ) != null ) {
			propsMatches.add( { 'name': match[ 1 ], 'type': match[ 2 ] } );
		}

		// Process matches to correctly pair names and types
		final inputs = [];
		for (int i = 0; i < propsMatches.length; i ++ ) {

			final name = propsMatches[ i ]['name'];
      final type = propsMatches[ i ]['type'];

			dynamic resolvedType = type;

			if ( resolvedType.startsWith( 'ptr' ) ) {
				resolvedType = 'pointer';
			} else {
				if ( resolvedType.startsWith( 'texture' ) ) {
					resolvedType = type.split( '<' )[ 0 ];
				}

				resolvedType = wgslTypeLib[ resolvedType ];
			}

			inputs.add( new NodeFunctionInput( resolvedType, name ) );
		}

		final blockCode = source.substring( declaration[ 0 ].length );
		final outputType = declaration[ 3 ] ?? 'void';

		final name = declaration[ 1 ] != null ? declaration[ 1 ] : '';
		final type = wgslTypeLib[ outputType ] ?? outputType;

		return {
			'type':type,
			"inputs":inputs,
			'name':name,
			'inputsCode':inputsCode,
			'blockCode':blockCode,
			'outputType':outputType
		};

	} 
  else {
		throw ( 'FunctionNode: Function is not a WGSL code.' );
	}
}

/**
 * This class represents a WSL node function.
 *
 * @augments NodeFunction
 */
class WGSLNodeFunction extends NodeFunction {
  dynamic inputsCode;
  dynamic blockCode;
  dynamic outputType;

  WGSLNodeFunction(super.type, super.inputs, super.name, this.inputsCode, this.blockCode, this.outputType );
	/**
	 * Constructs a new WGSL node function.
	 *
	 * @param {string} source - The WGSL source.
	 */
	factory WGSLNodeFunction.create(String source ) {
    final Map prse = parse( source );

		final type = prse['type'];
    final inputs = prse['inputs'];
    final name = prse['name'];
    final inputsCode = prse['inputsCode'];
    final blockCode = prse['blockCode'];
    final outputType = prse['outputType'];

    return WGSLNodeFunction(type, inputs, name, inputsCode, blockCode, outputType);
	}

	/**
	 * This method returns the WGSL code of the node function.
	 *
	 * @param {string} [name=this.name] - The function's name.
	 * @return {string} The shader code.
	 */
	String getCode([String? name]) {
    name = this.name;
		final outputType = this.outputType != 'void' ? '-> ${this.outputType} ': '';

		return 'fn ${ name } ( ${ this.inputsCode.trim() } ) ${ outputType } ${this.blockCode}';
	}
}
