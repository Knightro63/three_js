const vertex_shader = """
#version 300 es
precision mediump float;

in vec4 Position;
in vec2 TextureCoords;
out vec2 TextureCoordsVarying;

uniform mat4 matrix;

void main (void) {
    gl_Position = matrix * Position;
    TextureCoordsVarying = TextureCoords;
}

""";
    
const fragment_shader = """
#version 300 es
precision mediump float;

uniform sampler2D Texture0;
in vec2 TextureCoordsVarying;

out vec4 fragColor;

void main (void) {
    vec4 mask = texture(Texture0, TextureCoordsVarying);
    fragColor = vec4(mask.rgb, mask.a);
}
""";

//#version 300 es must be at first line
const vertex_shader_android = """
#version 300 es
precision mediump float;

layout (location = 0) in vec4 Position;
layout (location = 1) in vec2 TextureCoords;
out vec2 TextureCoordsVarying;
uniform mat4 matrix;

void main () {
    gl_Position = matrix * Position;
    TextureCoordsVarying = TextureCoords;
}
""";


const oes_vertex_shader = """
#version 300 es
precision mediump float;

layout (location = 0) in vec4 Position;
layout (location = 1) in vec2 TextureCoords;
out vec2 TextureCoordsVarying;

void main () {
    gl_Position = Position;
    TextureCoordsVarying = TextureCoords;
}
""";

const oes_fragment_shader  = """
#version 300 es
#extension GL_OES_EGL_image_external_essl3 : enable

precision mediump float;
uniform samplerExternalOES Texture0;
in vec2 TextureCoordsVarying;

out vec4 fragColor;

void main (void) {
  vec4 mask = texture(Texture0, TextureCoordsVarying);
  fragColor = mask;
}
""";


const fxaa_vertex_shader = """
#version 300 es
layout (location = 0) in vec4 Position;
layout (location = 1) in vec2 TextureCoords;
out vec2 TextureCoordsVarying;

void main () {
    gl_Position = Position;
    TextureCoordsVarying = TextureCoords;
}
""";

const fxaa_fragment_shader = """
#version 300 es
precision mediump float;
uniform sampler2D Texture0;
uniform vec2 frameBufSize;
in vec2 TextureCoordsVarying;

out vec4 fragColor;

void main( void ) {
    float FXAA_SPAN_MAX = 8.0;
    float FXAA_REDUCE_MUL = 1.0/8.0;
    float FXAA_REDUCE_MIN = 1.0/128.0;

    vec3 rgbNW=texture(Texture0,TextureCoordsVarying+(vec2(-1.0,-1.0)/frameBufSize)).xyz;
    vec3 rgbNE=texture(Texture0,TextureCoordsVarying+(vec2(1.0,-1.0)/frameBufSize)).xyz;
    vec3 rgbSW=texture(Texture0,TextureCoordsVarying+(vec2(-1.0,1.0)/frameBufSize)).xyz;
    vec3 rgbSE=texture(Texture0,TextureCoordsVarying+(vec2(1.0,1.0)/frameBufSize)).xyz;
    vec3 rgbM=texture(Texture0,TextureCoordsVarying).xyz;

    vec3 luma= vec3(0.299, 0.587, 0.114);
    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM  = dot(rgbM,  luma);

    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    float dirReduce = max(
        (lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL),
        FXAA_REDUCE_MIN);

    float rcpDirMin = 1.0/(min(abs(dir.x), abs(dir.y)) + dirReduce);

    dir = min(vec2( FXAA_SPAN_MAX,  FXAA_SPAN_MAX),
          max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
          dir * rcpDirMin)) / frameBufSize;

    vec3 rgbA = (1.0/2.0) * (
        texture(Texture0, TextureCoordsVarying.xy + dir * (1.0/3.0 - 0.5)).xyz +
        texture(Texture0, TextureCoordsVarying.xy + dir * (2.0/3.0 - 0.5)).xyz);
    vec3 rgbB = rgbA * (1.0/2.0) + (1.0/4.0) * (
        texture(Texture0, TextureCoordsVarying.xy + dir * (0.0/3.0 - 0.5)).xyz +
        texture(Texture0, TextureCoordsVarying.xy + dir * (3.0/3.0 - 0.5)).xyz);
    float lumaB = dot(rgbB, luma);

    if((lumaB < lumaMin) || (lumaB > lumaMax)){
        fragColor.xyz=rgbA;
    }else{
        fragColor.xyz=rgbB;
    }
}
""";