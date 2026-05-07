#version 460 core

// Constants
#define PI 3.141592653589793
#define PI2 6.283185307179586
#define PI_HALF 1.5707963267948966
#define RECIPROCAL_PI 0.3183098861837907
#define RECIPROCAL_PI2 0.15915494309189535
#define EPSILON 1e-6

// Helpers
#define saturate(a) clamp(a, 0.0, 1.0)
#define whiteComplement(a) (1.0 - saturate(a))

// Math Functions
float pow2(const in float x) { return x*x; }
vec3 pow2(const in vec3 x) { return x*x; }
float pow3(const in float x) { return x*x*x; }
float pow4(const in float x) { float x2 = x*x; return x2*x2; }
float max3(const in vec3 v) { return max(max(v.x, v.y), v.z); }
float average(const in vec3 v) { return dot(v, vec3(0.3333333)); }

highp float rand(const in vec2 uv) {
    const highp float a = 12.9898, b = 78.233, c = 43758.5453;
    highp float dt = dot(uv.xy, vec2(a, b)), sn = mod(dt, PI);
    return fract(sin(sn) * c);
}

float precisionSafeLength(vec3 v) {
    // Defaulting to high precision logic for Flutter GPU
    return length(v);
}

// Lighting Structs
struct IncidentLight {
    vec3 color;
    vec3 direction;
    bool visible;
};

struct ReflectedLight {
    vec3 directDiffuse;
    vec3 directSpecular;
    vec3 indirectDiffuse;
    vec3 indirectSpecular;
};

// Varyings (Mapped to Location 0 per Master List)
layout(location = 0) in vec3 vPosition;

// Directional Transformations
vec3 transformDirection(in vec3 dir, in mat4 matrix) {
    return normalize((matrix * vec4(dir, 0.0)).xyz);
}

vec3 inverseTransformDirection(in vec3 dir, in mat4 matrix) {
    return normalize((vec4(dir, 0.0) * matrix).xyz);
}

// Native transpose in 4.60
mat3 transposeMat3(const in mat3 m) { return transpose(m); }

float luminance(const in vec3 rgb) {
    const vec3 weights = vec3(0.2126729, 0.7151522, 0.0721750);
    return dot(weights, rgb);
}

bool isPerspectiveMatrix(mat4 m) {
    return m[2][3] == -1.0;
}

vec2 equirectUv(in vec3 dir) {
    float u = atan(dir.z, dir.x) * RECIPROCAL_PI2 + 0.5;
    float v = asin(clamp(dir.y, -1.0, 1.0)) * RECIPROCAL_PI + 0.5;
    return vec2(u, v);
}

// BRDF Components
vec3 BRDF_Lambert(const in vec3 diffuseColor) {
    return RECIPROCAL_PI * diffuseColor;
}

// Fresnel Schlick - Optimized variant
vec3 F_Schlick(const in vec3 f0, const in float f90, const in float dotVH) {
    float fresnel = exp2((-5.55473 * dotVH - 6.98316) * dotVH);
    return f0 * (1.0 - fresnel) + (f90 * fresnel);
}

float F_Schlick(const in float f0, const in float f90, const in float dotVH) {
    float fresnel = exp2((-5.55473 * dotVH - 6.98316) * dotVH);
    return f0 * (1.0 - fresnel) + (f90 * fresnel);
}
