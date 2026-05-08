
/**
 * Converted from lightsLambertFragment.
 * Defines properties specific to the Lambertian (diffuse) material model.
 */
struct LambertMaterial {
    vec3 diffuseColor;
    float specularStrength;
};

LambertMaterial initializeLambertMaterial(vec4 diffuseColor, float specularStrength) {
    LambertMaterial material;
    
    material.diffuseColor = diffuseColor.rgb;
    material.specularStrength = specularStrength;
    
    return material;
}
