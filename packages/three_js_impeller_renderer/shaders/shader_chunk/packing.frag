
/**
 * Converted from packingGlsl.
 * Utility functions for packing/unpacking depth, normals, and half-floats.
 */

vec3 packNormalToRGB(const in vec3 normal) {
    return normalize(normal) * 0.5 + 0.5;
}

vec3 unpackRGBToNormal(const in vec3 rgb) {
    return 2.0 * rgb - 1.0;
}

const float PackUpscale = 256.0 / 255.0;
const float UnpackDownscale = 255.0 / 256.0;
const vec3 PackFactors = vec3(256.0 * 256.0 * 256.0, 256.0 * 256.0, 256.0);
const vec4 UnpackFactors = UnpackDownscale / vec4(PackFactors, 1.0);
const float ShiftRight8 = 1.0 / 256.0;

vec4 packDepthToRGBA(const in float v) {
    vec4 r = vec4(fract(v * PackFactors), v);
    r.yzw -= r.xyz * ShiftRight8;
    return r * PackUpscale;
}

float unpackRGBAToDepth(const in vec4 v) {
    return dot(v, UnpackFactors);
}

vec2 packDepthToRG(in highp float v) {
    return packDepthToRGBA(v).yx;
}

float unpackRGToDepth(const in highp vec2 v) {
    return unpackRGBAToDepth(vec4(v.xy, 0.0, 0.0));
}

vec4 pack2HalfToRGBA(vec2 v) {
    vec4 r = vec4(v.x, fract(v.x * 255.0), v.y, fract(v.y * 255.0));
    return vec4(r.x - r.y / 255.0, r.y, r.z - r.w / 255.0, r.w);
}

vec2 unpackRGBATo2Half(vec4 v) {
    return vec2(v.x + (v.y / 255.0), v.z + (v.w / 255.0));
}

// Depth conversion helpers
float viewZToOrthographicDepth(const in float viewZ, const in float near, const in float far) {
    return (viewZ + near) / (near - far);
}

float orthographicDepthToViewZ(const in float depth, const in float near, const in float far) {
    return depth * (near - far) - near;
}

float viewZToPerspectiveDepth(const in float viewZ, const in float near, const in float far) {
    return ((near + viewZ) * far) / ((far - near) * viewZ);
}

float perspectiveDepthToViewZ(const in float depth, const in float near, const in float far) {
    return (near * far) / ((far - near) * depth - far);
}
