
/**
 * Converts lightsPhongFragment logic.
 * Note: BlinnPhongMaterial struct should be defined in lights_phong_pars.frag.
 */
struct BlinnPhongMaterial {
    vec3 diffuseColor;
    vec3 specularColor;
    float specularShininess;
    float specularStrength;
};

BlinnPhongMaterial initializeBlinnPhongMaterial(
    vec4 diffuseColor, 
    vec3 specular, 
    float shininess, 
    float specularStrength
) {
    BlinnPhongMaterial material;
    
    material.diffuseColor = diffuseColor.rgb;
    material.specularColor = specular;
    material.specularShininess = shininess;
    material.specularStrength = specularStrength;
    
    return material;
}
