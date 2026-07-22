float saturate( float a ){ 
    return clamp( a, 0.0, 1.0 ); 
}

vec3 saturate( vec3 a ){ 
    return clamp( a, 0.0, 1.0 ); 
}

vec3 LinearToneMapping( vec3 color ) { 
    return saturate( scene.rendParms.y * color ); 
} 

vec3 ReinhardToneMapping( vec3 color ) { 
    vec3 col = color * scene.rendParms.y; 
    return saturate( col / ( vec3( 1.0 ) + col ) ); 
} 

vec3 OptimizedCineonToneMapping( vec3 color ) { 
    vec3 col = color * scene.rendParms.y; 
    col = max( vec3( 0.0 ), col - 0.004 ); 
    vec3 numerator = col * ( 6.2 * col + vec3(0.5) ); 
    vec3 denominator = col * ( 6.2 * col + vec3(1.7) ) + vec3(0.06); 
    return pow( max( vec3(0.0), numerator / denominator ), vec3( 2.2 ) ); 
} 

vec3 RRTAndODTFit( vec3 v ) { 
    vec3 a = v * ( v + vec3(0.0245786) ) - vec3(0.000090537); 
    vec3 b = v * ( vec3(0.983729) * v + vec3(0.4329510) ) + vec3(0.238081); 
    return a / b; 
} 

vec3 ACESFilmicToneMapping( vec3 color ) { 
    mat3 ACESInputMat = mat3( 
        vec3( 0.59719, 0.07600, 0.02840 ), 
        vec3( 0.35458, 0.90834, 0.13383 ), 
        vec3( 0.04823, 0.01566, 0.83777 ) 
    ); 
    mat3 ACESOutputMat = mat3( 
        vec3( 1.60475, -0.10208, -0.00327 ), 
        vec3( -0.53108, 1.10813, -0.07276 ), 
        vec3( -0.07367, -0.00605, 1.07602 ) 
    ); 
    vec3 col = color * ( scene.rendParms.y / 0.6 ); 
    col = ACESInputMat * col; 
    col = RRTAndODTFit( col ); 
    col = ACESOutputMat * col; 
    return saturate( col ); 
} 

vec3 agxDefaultContrastApprox( vec3 x ) { 
    vec3 x2 = x * x; 
    vec3 x4 = x2 * x2; 
    return vec3(15.5) * x4 * x2 - vec3(40.14) * x4 * x + vec3(31.96) * x4 - vec3(6.868) * x2 * x + vec3(0.4298) * x2 + vec3(0.1191) * x - vec3(0.00232); 
} 

vec3 AgXToneMapping( vec3 color ) { 
    mat3 LINEAR_REC2020_TO_LINEAR_SRGB = mat3( 
        vec3( 1.6605, -0.1246, -0.0182 ), 
        vec3( -0.5876, 1.1329, -0.1006 ), 
        vec3( -0.0728, -0.0083, 1.1187 ) 
    ); 
    mat3 LINEAR_SRGB_TO_LINEAR_REC2020 = mat3( 
        vec3( 0.6274, 0.0691, 0.0164 ), 
        vec3( 0.3293, 0.9195, 0.0880 ), 
        vec3( 0.0433, 0.0113, 0.8956 ) 
    ); 
    mat3 AgXInsetMatrix = mat3( 
        vec3( 0.856627153315983, 0.137318972929847, 0.11189821299995 ), 
        vec3( 0.0951212405381588, 0.761241990602591, 0.0767994186031903 ), 
        vec3( 0.0482516061458583, 0.101439036467562, 0.811302368396859 ) 
    ); 
    mat3 AgXOutsetMatrix = mat3( 
        vec3( 1.1271005818144368, -0.1413297634984383, -0.14132976349843826 ), 
        vec3( -0.11060664309660323, 1.157823702216272, -0.11060664309660294 ), 
        vec3( -0.016493938717834573, -0.016493938717834257, 1.2519364065950405 ) 
    ); 
    const float AgxMinEv = -12.47393; 
    const float AgxMaxEv = 4.026069; 
    vec3 col = color * scene.rendParms.y; 
    col = LINEAR_SRGB_TO_LINEAR_REC2020 * col; 
    col = AgXInsetMatrix * col; 
    col = max( col, vec3(1e-10) ); 
    col = log2( col ); 
    col = ( col - vec3(AgxMinEv) ) / vec3( AgxMaxEv - AgxMinEv ); 
    col = clamp( col, 0.0, 1.0 ); 
    col = agxDefaultContrastApprox( col ); 
    col = AgXOutsetMatrix * col; 
    col = pow( max( vec3( 0.0 ), col ), vec3( 2.2 ) ); 
    col = LINEAR_REC2020_TO_LINEAR_SRGB * col; 
    return clamp( col, 0.0, 1.0 ); 
} 

vec3 NeutralToneMapping( vec3 color ) { 
    const float StartCompression = 0.8 - 0.04; 
    const float Desaturation = 0.15; 
    vec3 col = color * scene.rendParms.y; 
    float x = min( col.r, min( col.g, col.b ) ); 
    float offset = x < 0.08 ? x - 6.25 * x * x : 0.04; 
    col -= offset; 
    float peak = max( col.r, max( col.g, col.b ) ); 
    if ( peak < StartCompression ) return col; 
    float d = 1. - StartCompression; 
    float newPeak = 1. - d * d / ( peak + d - StartCompression ); 
    col *= newPeak / peak; 
    float g = 1. - 1. / ( Desaturation * ( peak - newPeak ) + 1. ); 
    return mix( col, vec3( newPeak ), g ); 
} 

vec3 CustomToneMapping( vec3 color ) { 
    return color; 
} 

vec3 toneMapping( vec3 color ) { 
    int mode = int(floor(scene.rendParms.x + 0.5)); 
    if (mode == 1) return LinearToneMapping(color); 
    if (mode == 2) return ReinhardToneMapping(color); 
    if (mode == 3) return OptimizedCineonToneMapping(color); 
    if (mode == 4) return ACESFilmicToneMapping(color); 
    if (mode == 5) return AgXToneMapping(color); 
    if (mode == 6) return NeutralToneMapping(color); 
    if (mode == 7) return CustomToneMapping(color); 
    return color; 
}
