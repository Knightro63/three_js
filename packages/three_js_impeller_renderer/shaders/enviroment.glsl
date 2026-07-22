envMap;

void applyEnvironmentMap(
    in vec3 normal, 
    in vec3 vWorldPosition, 
    in vec3 vReflect, 
    inout vec3 outgoingLight,
    in samplerCube envMap
) {
    // 1. Extract flags from the envMapParms 4th column matrix registers
    float useENVMAP      = scene.envMapParms[3][0]; 
    float useEnvWorldPos = scene.envMapParms[3][1];
    float envMapMR       = scene.envMapParms[3][2]; // reflection vs refraction mode
    
    // Quick exit branch if environment mapping is toggled off from Dart
    if (useENVMAP < 0.5) {
        return; 
    }

    // 2. Extract standard matrix/scalars from the top-left 3x3 of the mat4
    mat3 envMapRotation  = mat3(scene.envMapParms);
    float refractionRatio  = scene.envMapParms[0][3]; 
    float specularStrength = scene.envMapParms[1][3]; 
    float reflectivity     = scene.envMapParms[2][3]; 
    float flipEnvMap       = scene.envMapParms[3][3]; 

    // 3. Environment calculation
    vec3 reflectVec;
    bool isOrthographic = (material.cameraPosition.w > 0.5);

    if (useEnvWorldPos > 0.5) {
        vec3 cameraToFrag;
        if (isOrthographic) {
            cameraToFrag = normalize(vec3(-material.viewMatrix[0][2], -material.viewMatrix[1][2], -material.viewMatrix[2][2]));
        } else {
            cameraToFrag = normalize(vWorldPosition - material.cameraPosition.xyz);
        }
        
        // Manual direction inverse transform calculation
        vec3 worldNormal = normalize((material.viewMatrix * vec4(normal, 0.0)).xyz);

        if (envMapMR > 0.5) { // e.g. 1.0 = Reflection, 0.0 = Refraction
            reflectVec = reflect(cameraToFrag, worldNormal);
        } else {
            reflectVec = refract(cameraToFrag, worldNormal, refractionRatio);
        }
    } else {
        reflectVec = vReflect;
    }

    // 4. Sample using extracted envTypeCube flag from envParms.y
    vec4 envColor = vec4(0.0);
    float isCubeMap = scene.envParms.y; // 1.0 = Cube, 0.0 = None
    
    if (isCubeMap > 0.5) {
        vec3 sampleDir = vec3(flipEnvMap * reflectVec.x, reflectVec.yz);
        envColor = texture(envMap, envMapRotation * sampleDir);
    }

    // 5. Dynamic Blending Selection using envParms.z float values
    // (e.g., 1.0 = Multiply, 2.0 = Mix, 3.0 = Add)
    float blendingMode = scene.envParms.z;
    float factor = specularStrength * reflectivity;

    if (blendingMode > 2.5) { 
        outgoingLight += envColor.xyz * factor;
    } 
    else if (blendingMode > 1.5) { 
        outgoingLight = mix(outgoingLight, envColor.xyz, factor);
    } 
    else if (blendingMode > 0.5) { 
        outgoingLight = mix(outgoingLight, outgoingLight * envColor.xyz, factor);
    }
}
