library three_shaders;

import 'package:three_js_core/three_js_core.dart';
import 'package:three_js_math/three_js_math.dart';
import 'shader_chunk/index.dart';

export './shader_lib/vsm_vert.glsl.dart';
export './shader_lib/vsm_frag.glsl.dart';

part './shader_lib.dart';
part 'uniforms_lib.dart';
part 'uniforms_utils.dart';
part './shader_chunk.dart';
