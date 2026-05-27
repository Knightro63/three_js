import 'package:three_js_core/three_js_core.dart' as core;

// regular expression configurations matching original JS regex logic
final RegExp _declarationRegexp = RegExp(
  r'^[fn]*\s*([a-z_0-9]+)?\s*\(([\s\S]*?)\)\s*[\-\>]*\s*([a-z_0-9]+(?:<[\s\S]+?>)?)',
  caseSensitive: false,
);

final RegExp _propertiesRegexp = RegExp(
  r'([a-z_0-9]+)\s*:\s*([a-z_0-9]+(?:<[\s\S]+?>)?)',
  caseSensitive: false,
);

// Map library mapping WGSL type signatures to core engine equivalents
final Map<String, String> _wgslTypeLib = {
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

/// Internal helper model holding parsing layout results
class _ParsedFunction {
  final String type;
  final List<dynamic> inputs; // Replaces List<NodeFunctionInput>
  final String name;
  final String inputsCode;
  final String blockCode;
  final String outputType;

  _ParsedFunction({
    required this.type,
    required this.inputs,
    required this.name,
    required this.inputsCode,
    required this.blockCode,
    required this.outputType,
  });
}

/// Private procedural string parser executing token extraction math bounds
_ParsedFunction _parse(String source) {
  final String trimmedSource = source.trim();
  final Match? declaration = _declarationRegexp.firstMatch(trimmedSource);

  if (declaration != null && declaration.groupCount >= 3) {
    final String inputsCode = declaration.group(2) ?? '';
    final List<Map<String, String>> propsMatches = [];

    // All matches execution sequence loop replacing standard state RegExp exec loops
    final Iterable<Match> matches = _propertiesRegexp.allMatches(inputsCode);
    for (final Match match in matches) {
      propsMatches.add({
        'name': match.group(1) ?? '',
        'type': match.group(2) ?? '',
      });
    }

    final List<dynamic> inputs = [];
    for (int i = 0; i < propsMatches.length; i++) {
      final String name = propsMatches[i]['name']!;
      final String type = propsMatches[i]['type']!;
      String resolvedType = type;

      if (resolvedType.startsWith('ptr')) {
        resolvedType = 'pointer';
      } else {
        if (resolvedType.startsWith('texture')) {
          resolvedType = type.split('<')[0];
        }
        resolvedType = _wgslTypeLib[resolvedType] ?? resolvedType;
      }

      // Replaces new NodeFunctionInput(resolvedType, name)
      inputs.add(NodeFunctionInput(resolvedType, name));
    }

    // Capture the function block segment slice following the matching header signature
    final int matchEndIndex = declaration.end;
    final String blockCode = trimmedSource.substring(matchEndIndex);
    final String outputType = declaration.group(3) ?? 'void';
    final String name = declaration.group(1) ?? '';
    final String type = _wgslTypeLib[outputType] ?? outputType;

    return _ParsedFunction(
      type: type,
      inputs: inputs,
      name: name,
      inputsCode: inputsCode,
      blockCode: blockCode,
      outputType: outputType,
    );
  } else {
    throw Exception('THREE.WGSLNodeFunction: Function is not valid WGSL shader code.');
  }
}

/// This class represents a WGSL node function wrapper layer.
class WGSLNodeFunction extends NodeFunction {
  late final String inputsCode;
  late final String blockCode;
  late final String outputType;

  // Private internal constructor running assignments cleanly following parent constraints
  WGSLNodeFunction._internal(_ParsedFunction parsed): super(parsed.type, parsed.inputs, parsed.name) {
    this.inputsCode = parsed.inputsCode;
    this.blockCode = parsed.blockCode;
    this.outputType = parsed.outputType;
  }

  /// Constructs a new WGSL node function parser pipeline block.
  factory WGSLNodeFunction(String source) {
    final _ParsedFunction parsedData = _parse(source);
    return WGSLNodeFunction._internal(parsedData);
  }

  /// This method returns the fully assembled WGSL string code of the node function.
  String getCode([String? name]) {
    final String targetName = name ?? this.name;
    final String outputSignature = this.outputType != 'void' ? '-> ${this.outputType}' : '';
    
    return 'fn $targetName ( ${this.inputsCode.trim()} ) $outputSignature' + this.blockCode;
  }
}
