// Non-PURE exports list, side-effects are required here.
// TSL Base Syntax

export './tsl_core.dart'; // float(), vec2(), vec3(), vec4(), mat3(), mat4(), Fn(), If(), element(), nodeObject(), nodeProxy(), ...
export '../core/array_node.dart'; // array(), .toArray()
export '../core/uniform_node.dart'; // uniform()
export '../core/property_node.dart'; // property()  <-> TODO: Separate Material Properties in other file
export '../core/assign_node.dart'; // .assign()
export '../code/function_call_node.dart'; // .call()
export '../math/operator_node.dart'; // .add(), .sub(), ...
export '../math/math_node.dart'; // abs(), floor(), ...
export '../math/conditional_node.dart'; // select(), ...
export '../core/context_node.dart'; // .context()
export '../core/var_node.dart'; // .var() -> TODO: Maybe rename .toVar() -> .var()
export '../core/varying_node.dart'; // varying(), vertexStage()
export '../display/color_space_node.dart'; // .toColorSpace()
export '../display/tone_mapping_node.dart'; // .toToneMapping()
export '../accessors/buffer_attribute_node.dart'; // .toAttribute()
export '../gpgpu/compute_node.dart'; // .compute()
export '../core/cache_node.dart'; // .cache()
export '../core/bypass_node.dart'; // .bypass()
export '../utils/remap_node.dart'; // .remap(), .remapClamp()
export '../code/expression_node.dart'; // expression()
export '../utils/discard.dart'; // Discard(), Return()
export '../display/render_output_node.dart'; // .renderOutput()
export '../utils/debug_node.dart'; // debug()
export '../core/sub_build_node.dart'; // subBuild()

addNodeElement( name/*, nodeElement*/ ) {
	console.warn( 'THREE.TSL: AddNodeElement has been removed in favor of tree-shaking. Trying add', name );
}
