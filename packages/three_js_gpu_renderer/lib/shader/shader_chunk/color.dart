import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart';

const ShaderChunk colorChunk = ShaderChunk(
  name: 'common.color',
  source: '''
  const LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 = mat3x3<f32>(
      vec3<f32>(0.8224621, 0.0331941, 0.0170827),
      vec3<f32>(0.1775380, 0.9668058, 0.0723974),
      vec3<f32>(0.0000000, 0.0000000, 0.9105199)
  );

  const LINEAR_DISPLAY_P3_TO_LINEAR_SRGB = mat3x3<f32>(
      vec3<f32>(1.2249401, -0.0420569, -0.0196376),
      vec3<f32>(-0.2249404, 1.0420571, -0.0786361),
      vec3<f32>(0.0000000, 0.0000000, 1.0982735)
  );

  fn LinearSRGBToLinearDisplayP3(value: vec4<f32>) -> vec4<f32> {
      return vec4<f32>(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 * value.rgb, value.a);
  }

  fn LinearDisplayP3ToLinearSRGB(value: vec4<f32>) -> vec4<f32> {
      return vec4<f32>(LINEAR_DISPLAY_P3_TO_LINEAR_SRGB * value.rgb, value.a);
  }

  fn sRGBTransferEETF(value: vec4<f32>) -> vec4<f32> {
      var linearColor: vec3<f32>;
      linearColor.r = select(pow((value.r + 0.055) / 1.055, 2.4), value.r / 12.92, value.r <= 0.04045);
      linearColor.g = select(pow((value.g + 0.055) / 1.055, 2.4), value.g / 12.92, value.g <= 0.04045);
      linearColor.b = select(pow((value.b + 0.055) / 1.055, 2.4), value.b / 12.92, value.b <= 0.04045);
      return vec4<f32>(linearColor, value.a);
  }

  fn sRGBTransferOETF(value: vec4<f32>) -> vec4<f32> {
      var srgbColor: vec3<f32>;
      srgbColor.r = select(pow(value.r, 0.41666) * 1.055 - 0.055, value.r * 12.92, value.r <= 0.0031308);
      srgbColor.g = select(pow(value.g, 0.41666) * 1.055 - 0.055, value.g * 12.92, value.g <= 0.0031308);
      srgbColor.b = select(pow(value.b, 0.41666) * 1.055 - 0.055, value.b * 12.92, value.b <= 0.0031308);
      return vec4<f32>(srgbColor, value.a);
  }

  fn applyColor(value: vec4<f32>) -> vec4<f32> {
      let spaceIndex = i32(uniforms.lineExtendedParams.z + 0.1);
      
      if (spaceIndex == 1) {
          // 1: Linear pass-through
          return value;
      } else if (spaceIndex == 2) {
          // 2: sRGB output (Standard web mapping)
          return sRGBTransferOETF(value);
      } else if (spaceIndex == 3) {
          // 3: Display P3 color space with sRGB gamma correction curves
          let linearP3 = LinearSRGBToLinearDisplayP3(value);
          return sRGBTransferOETF(linearP3);
      } else if (spaceIndex == 4) {
          // 4: Linear Display P3 output
          return LinearSRGBToLinearDisplayP3(value);
      } else {
          // 0: Unmanaged raw output passthrough
          return value;
      }
  }
  ''',
);
