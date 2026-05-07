#version 460 core

/**
 * Converts lightsToonFragment logic.
 * Defines properties specific to the Toon material model.
 */
struct ToonMaterial {
    vec3 diffuseColor;
};

ToonMaterial initializeToonMaterial(vec4 diffuseColor) {
    ToonMaterial material;
    material.diffuseColor = diffuseColor.rgb;
    return material;
}
