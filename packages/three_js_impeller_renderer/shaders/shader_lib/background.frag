#version 460 core

// FLOATS & BOOLS LIST (Index order determined from top to bottom)
uniform ConfigUniforms {
  float backgroundIntensity; // Float Index 0
  bool decodeVideoTexture;   // Float Index 1 (Bools use 1.0/0.0 in Dart)
};

// TEXTURE SAMPLERS LIST
uniform sampler2D t2D;       // Sampler Index 0

// Inputs from vertex shader (Name must match vertex output)
in vec2 vUv;

// Explicit fragment pipeline output
layout(location = 0) out vec4 fragColor;

void main() {
  vec4 texColor = texture(t2D, vUv);

  // Replaced #ifdef macro with a runtime branch for Flutter compatibility
  if (decodeVideoTexture) {
    vec3 condition = vec3(lessThanEqual(texColor.rgb, vec3(0.04045)));
    vec3 trueBranch = texColor.rgb * 0.0773993808;
    vec3 falseBranch = pow(texColor.rgb * 0.9478672986 + vec3(0.0521327014), vec3(2.4));
    
    texColor = vec4(mix(falseBranch, trueBranch, condition), texColor.w);
  }

  texColor.rgb *= backgroundIntensity;
  fragColor = texColor;

  // Note: Ensure your local include paths are correct, or paste the raw GLSL 
  // contents of tonemapping and colorspace blocks directly here.
  #include "../shader_chunk/tonemapping.frag"
  #include "../shader_chunk/colorspace.frag"
}
