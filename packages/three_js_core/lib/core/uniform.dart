import 'package:three_js_math/three_js_math.dart';

/// Uniforms are global GLSL variables. They are passed to shader programs.
/// 
/// Each uniform must have a `value` property. The type of the value must
/// correspond to the type of the uniform variable in the GLSL code as
/// specified for the primitive GLSL types in the table below. Uniform
/// structures and arrays are also supported. GLSL arrays of primitive type
/// must either be specified as an array of the corresponding THREE objects or
/// as a flat array containing the data of all the objects. In other words;
/// GLSL primitives in arrays must not be represented by arrays. This rule
/// does not apply transitively. An array of `vec2` arrays, each with a length
/// of five vectors, must be an array of arrays, of either five [Vector2]
/// objects or ten `number`s.
class Uniform {
  dynamic value;
  Float32Array? data;
  int? offset;

	Uniform(this.value);

  /// Returns a clone of this uniform.
  /// 
  /// If the uniform's value property is an [Object] with a clone() method,
  /// this is used, otherwise the value is copied by assignment. Array values
  /// are shared between cloned [Uniform]s.
	Uniform clone() {
		return Uniform(value?.clone() == null ?value :value.clone());
	}
}
