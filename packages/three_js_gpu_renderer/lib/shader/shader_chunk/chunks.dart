import 'package:three_js_gpu_renderer/shader/shader_chunk/clipping_planes.dart';
import 'package:three_js_gpu_renderer/shader/shader_chunk/color.dart';
import 'package:three_js_gpu_renderer/shader/shader_chunk/flat_shading.dart';
import 'package:three_js_gpu_renderer/shader/shader_chunk/fog.dart';
import 'package:three_js_gpu_renderer/shader/shader_chunk/light.dart';
import 'package:three_js_gpu_renderer/shader/shader_chunk/normal.dart';
import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart';

const List<ShaderChunk> chunks = [
  colorChunk,
  fogChunk,
  normalChunk,
  lightsChunk,
  flatShading,
  clippingChunk
];