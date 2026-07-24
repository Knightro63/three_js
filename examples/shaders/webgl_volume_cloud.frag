layout(std140, binding = 0) uniform WebglFragBlock {
  vec4 base;
  vec4 parms;
  vec4 parms1;
} sblock;

uniform sampler3D map;

in vec3 vOrigin;
in vec3 vDirection;

out vec4 frag_color;

uint wang_hash(uint seed){
  seed = (seed ^ 61u) ^ (seed >> 16u);
  seed *= 9u;
  seed = seed ^ (seed >> 4u);
  seed *= 0x27d4eb2du;
  seed = seed ^ (seed >> 15u);
  return seed;
}

float randomFloat(uint seed){
  return float(wang_hash(seed)) / 4294967296.;
}

vec2 hitBox( vec3 orig, vec3 dir ) {
  const vec3 box_min = vec3( - 0.5 );
  const vec3 box_max = vec3( 0.5 );
  vec3 inv_dir = 1.0 / dir;
  vec3 tmin_tmp = ( box_min - orig ) * inv_dir;
  vec3 tmax_tmp = ( box_max - orig ) * inv_dir;
  vec3 tmin = min( tmin_tmp, tmax_tmp );
  vec3 tmax = max( tmin_tmp, tmax_tmp );
  float t0 = max( tmin.x, max( tmin.y, tmin.z ) );
  float t1 = min( tmax.x, min( tmax.y, tmax.z ) );
  return vec2( t0, t1 );
}

float sample1( vec3 p ) {
  return texture( map, p ).r;
}

float shading( vec3 coord ) {
  float step = 0.01;
  return sample1( coord + vec3( - step ) ) - sample1( coord + vec3( step ) );
}

vec4 linearToSRGB(vec4 value ) {
  return vec4( mix( pow( value.rgb, vec3( 0.41666 ) ) * 1.055 - vec3( 0.055 ), value.rgb * 12.92, vec3( lessThanEqual( value.rgb, vec3( 0.0031308 ) ) ) ), value.a );
}

void main(){
  float threshold = sblock.parms.x;
  float range = sblock.parms.y;
  float opacity = sblock.parms.z;
  float steps = sblock.parms.w;
  float frame = sblock.parms1.x;

  vec3 rayDir = normalize( vDirection );
  vec2 bounds = hitBox( vOrigin, rayDir );

  if ( bounds.x > bounds.y ) discard;
  bounds.x = max( bounds.x, 0.0 );

  vec3 p = vOrigin + bounds.x * rayDir;
  vec3 inc = 1.0 / abs( rayDir );
  float delta = min( inc.x, min( inc.y, inc.z ) );
  delta /= steps;

  uint seed = uint( gl_FragCoord.x ) * uint( 1973 ) + uint( gl_FragCoord.y ) * uint( 9277 ) + uint( frame ) * uint( 26699 );
  vec3 size = vec3( textureSize( map, 0 ) );
  float randNum = randomFloat( seed ) * 2.0 - 1.0;
  p += rayDir * randNum * ( 1.0 / size );

  vec4 ac = sblock.base;

  for ( float t = bounds.x; t < bounds.y; t += delta ) {
    float d = sample1( p + 0.5 );
    d = smoothstep( threshold - range, threshold + range, d ) * opacity;
    float col = shading( p + 0.5 ) * 3.0 + ( ( p.x + p.y ) * 0.25 ) + 0.2;
    // ac = vec4(
    //   ac.rgb + (1.0 - ac.a) * d * col, // Updates RGB simultaneously using the current alpha
    //   ac.a   + (1.0 - ac.a) * d        // Updates Alpha
    // );
    if ( ac.a >= 0.95 ) break;
    p += rayDir * delta;
  }

  frag_color = linearToSRGB( ac );

  if ( frag_color.a == 0.0 ) discard;
}