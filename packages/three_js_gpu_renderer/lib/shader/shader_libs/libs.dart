import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/basic.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/depth.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/distance.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/lambert.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/line_dashed.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/line_basic.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/matcap.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/normal.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/pbr.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/phong.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/points.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/shader.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/shadow.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/sprite.dart';
import 'package:three_js_gpu_renderer/shader/shader_libs/toon.dart';

const List<ShaderChunk> shaderLibs = [
  ...basic,
  ...customShader,
  ...lineDashed,
  ...sprite,
  ...depth,
  ...distance,
  ...lambert,
  ...lineBasic,
  ...matcap,
  ...normal,
  ...pbr,
  ...phong,
  ...points,
  ...shadow,
  ...toon,
  ...customShader,
];

/// .map -> MeshLambertMaterial,MeshBasicMaterial,SpriteMaterial,MeshToonMaterial,MeshPhongMaterial,MeshStandardMaterial
/// .normal -> MeshPhongMaterial, MeshStandardMaterial
/// specularMap -> MeshPhongMaterial
/// gradientMap -> MeshToonMaterial
/// matcap -> MeshMatcapMaterial
/// roughnessMap -> MeshStandardMaterial
/// metalnessMap -> MeshStandardMaterial
/// aoMap -> MeshStandardMaterial

///needed conversion
final List<String> wgslFocusChunks = [
  // --- Core Layout & Environment Matrices ---
  "common",                         // Convert to your master single-binding Uniforms block
  "color_pars_fragment",            // Keep for sRGB/Linear state setups
  "colorspace_fragment",            // Map index rules to your applyColor() engine
  "fog_vertex",                     // Reconstruct -viewPosition.z on the fly in Fragment instead
  "fog_fragment",                   // Convert to applyFogParity() logic block

  // --- Lighting Equations & Reflection Shards ---
  "bsdfs",                          // Core Bidirectional Scattering Distribution Functions
  "lights_pars_begin",              // Pack your dynamic multi-light array tracking
  "lights_phong_fragment",          // Your Blinn-Phong diffuse/specular evaluation loops
  "lights_physical_fragment",       // Your Cook-Torrance GGX PBR microfacet equations
  "clearcoat_normal_fragment_maps", // Clearcoat structural calculations
  "iridescence_fragment",           // Iridescence structural calculations
  "transmission_fragment",          // Advanced refraction/transmission light tracking

  // --- Map Coordinates & Sampling Configurations ---
  // Note: Group these into unified text injections via textureSample() functions
  "map_fragment",                   // Base diffuse albedo texture mapping
  "normal_fragment_maps",           // Normal map coordinate adjustments
  "bumpmap_pars_fragment",          // Bump map height evaluations
  "emissivemap_fragment",           // Additive emissive layer calculations
  "roughnessmap_fragment",          // Roughness map factor extractions
  "metalnessmap_fragment",          // Metalness map factor extractions
  "aomap_fragment",                 // Ambient Occlusion shadow masking
  "lightmap_fragment",              // Static pre-baked lighting additions
  "specularmap_fragment",           // Specular highlight tint color mappings
  "alphamap_fragment",              // Alpha map opacity masking transparency checks

  // --- Alpha Masking & Processing Blocks ---
  "alphatest_fragment",             // Fragment layout discard rules (alphaTest threshold check)
  "premultiplied_alpha_fragment",   // outColorVec.rgb * outColorVec.a alpha blending step

  // --- Vertex Structural Variations ---
  "morphtarget_vertex",             // Loop logic matching your 8 morph targets array tracking
  "skinning_vertex",                // Skinned skeletal mesh vertex shifting calculations

  // --- Specialized Primitives (If you support lines/particles in the master) ---
  "linedashed_frag",                // Dash segment evaluation math
  "points_vert",                    // Screenspace point particle size calculations
];
