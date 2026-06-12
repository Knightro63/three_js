// GLSL matrix columns are specified as vec3 elements back-to-back
const mat3 LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 = mat3(
    vec3(0.8224621, 0.0331941, 0.0170827),
    vec3(0.1775380, 0.9668058, 0.0723974),
    vec3(0.0000000, 0.0000000, 0.9105199)
);

const mat3 LINEAR_DISPLAY_P3_TO_LINEAR_SRGB = mat3(
    vec3(1.2249401, -0.0420569, -0.0196376),
    vec3(-0.2249404, 1.0420571, -0.0786361),
    vec3(0.0000000, 0.0000000, 1.0982735)
);

vec4 LinearSRGBToLinearDisplayP3(vec4 value) {
    return vec4(LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 * value.rgb, value.a);
}

vec4 LinearDisplayP3ToLinearSRGB(vec4 value) {
    return vec4(LINEAR_DISPLAY_P3_TO_LINEAR_SRGB * value.rgb, value.a);
}

vec4 sRGBTransferEETF(vec4 value) {
    vec3 linearColor;
    // WGSL select(false_val, true_val, condition) converts directly to GLSL mix() or ternary ?: operators
    linearColor.r = (value.r <= 0.04045) ? (value.r / 12.92) : pow((value.r + 0.055) / 1.055, 2.4);
    linearColor.g = (value.g <= 0.04045) ? (value.g / 12.92) : pow((value.g + 0.055) / 1.055, 2.4);
    linearColor.b = (value.b <= 0.04045) ? (value.b / 12.92) : pow((value.b + 0.055) / 1.055, 2.4);
    return vec4(linearColor, value.a);
}

vec4 sRGBTransferOETF(vec4 value) {
    vec3 srgbColor;
    srgbColor.r = (value.r <= 0.0031308) ? (value.r * 12.92) : (pow(value.r, 0.41666) * 1.055 - 0.055);
    srgbColor.g = (value.g <= 0.0031308) ? (value.g * 12.92) : (pow(value.g, 0.41666) * 1.055 - 0.055);
    srgbColor.b = (value.b <= 0.0031308) ? (value.b * 12.92) : (pow(value.b, 0.41666) * 1.055 - 0.055);
    return vec4(srgbColor, value.a);
}

vec4 applyColor(vec4 value) {
    // Note: Ensure your uniform interface block definition defines "uniforms" matching your Dart emplace data
    int spaceIndex = int(material.lineExtendedParams.z + 0.1);
    
    if (spaceIndex == 1) {
        // 1: Linear pass-through
        return value;
    } else if (spaceIndex == 2) {
        // 2: sRGB output (Standard web mapping)
        return sRGBTransferOETF(value);
    } else if (spaceIndex == 3) {
        // 3: Display P3 color space with sRGB gamma correction curves
        vec4 linearP3 = LinearSRGBToLinearDisplayP3(value);
        return sRGBTransferOETF(linearP3);
    } else if (spaceIndex == 4) {
        // 4: Linear Display P3 output
        return LinearSRGBToLinearDisplayP3(value);
    } else {
        // 0: Unmanaged raw output passthrough
        return value;
    }
}
