uniform MaterialSwitches {
    // Previous structural flags
    bool useAlphaHash;         // Float Index 32
    bool useAlphaMap;          // Float Index 33
    bool useAlphaTest;         // Float Index 34
    bool useAlphaToCoverage;   // Float Index 35
    float alphaTest;           // Float Index 36

    // NEW AO AND LIGHT SPECIFIC COUPLING SWITCHES
    bool useAoMap;             // Float Index 37
    bool useClearcoat;         // Float Index 38
    bool useSheen;             // Float Index 39
    bool useEnvMap;            // Float Index 40
    bool isStandardMaterial;   // Float Index 41

    bool useBatching;
};

void initMain(){
  if (useAlphaHash) {
    // getAlphaHashThreshold is pulled out of your standard pars chunk files
    if (diffuseColor.a < getAlphaHashThreshold(position)) {
      discard;
    }
  }

  if (useAlphaMap) {
    diffuseColor.a *= texture2D( alphaMap, vAlphaMapUv ).g;
  }

  if (useAlphaTest) {
    if(useAlphaToCoverage){
      diffuseColor.a = smoothstep( alphaTest, alphaTest + fwidth( diffuseColor.a ), diffuseColor.a );
      if ( diffuseColor.a == 0.0 ) discard;
    }
    else{
      if ( diffuseColor.a < alphaTest ) discard;
    }
  }

  if (useAoMap) {
      // Modern GLSL uses texture() instead of texture2D()
      // Reads channel R, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
      float ambientOcclusion = (texture(aoMap, vAoMapUv).r - 1.0) * aoMapIntensity + 1.0;
      
      reflectedLight.indirectDiffuse *= ambientOcclusion;

      if (useClearcoat) {
          clearcoatSpecularIndirect *= ambientOcclusion;
      }

      if (useSheen) {
          sheenSpecularIndirect *= ambientOcclusion;
      }

      if (useEnvMap && isStandardMaterial) {
          // WebGL 'saturate()' is replaced with standard GLSL 'clamp()'
          float dotNV = clamp(dot(geometryNormal, geometryViewDir), 0.0, 1.0);
          
          // computeSpecularOcclusion comes from envmap_physical_pars_fragment chunk
          reflectedLight.indirectSpecular *= computeSpecularOcclusion(dotNV, ambientOcclusion, materialRoughness);
      }
  }

  if(useBatching){
    attribute float batchId;
    uniform highp sampler2D batchingTexture;
    mat4 getBatchingMatrix( const in float i ) {
      int size = textureSize( batchingTexture, 0 ).x;
      int j = int( i ) * 4;
      int x = j % size;
      int y = j / size;
      vec4 v1 = texelFetch( batchingTexture, ivec2( x, y ), 0 );
      vec4 v2 = texelFetch( batchingTexture, ivec2( x + 1, y ), 0 );
      vec4 v3 = texelFetch( batchingTexture, ivec2( x + 2, y ), 0 );
      vec4 v4 = texelFetch( batchingTexture, ivec2( x + 3, y ), 0 );
      return mat4( v1, v2, v3, v4 );
    }
  }

  if(useBumpMap){

  }
}