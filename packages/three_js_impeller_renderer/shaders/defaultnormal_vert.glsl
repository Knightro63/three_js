struct TransformedTN {
  vec3 normal;
  vec3 tangent;
};

TransformedTN defaultNormal(vec3 normal, vec3 tanget) {
  vec3 transformedNormal = normal;
  vec3 transformedTangent = tanget;

  bool use_tangent    = false;
  bool use_batching   = material.flags5.w > 0.5;
  bool use_instancing = material.flags5.w > 1.5;
  if(use_instancing){
    use_batching = false;
  }
  bool flip_sided     = false;

  // Batching transform
  if (use_batching) {
      mat3 bm = mat3(batch_info.batchingMatrix);
      transformedNormal /= vec3(dot(bm[0], bm[0]), dot(bm[1], bm[1]), dot(bm[2], bm[2]));
      transformedNormal = bm * transformedNormal;
      if (use_tangent) {
          transformedTangent = bm * transformedTangent;
      }
  }

  // Instancing transform
  if (use_instancing) {
      mat3 im = mat3(batch_info.instanceMatrix);
      transformedNormal /= vec3(dot(im[0], im[0]), dot(im[1], im[1]), dot(im[2], im[2]));
      transformedNormal = im * transformedNormal;
      if (use_tangent) {
          transformedTangent = im * transformedTangent;
      }
  }

  // Normal Matrix multiplication
  transformedNormal = frame_info.normalMatrix * transformedNormal;

  // Flip material sides if necessary
  if (flip_sided) {
      transformedNormal = -transformedNormal;
  }

  // Final Tangent space calculation
  if (use_tangent) {
      transformedTangent = (frame_info.modelViewMatrix * vec4(transformedTangent, 0.0)).xyz;
      if (flip_sided) {
          transformedTangent = -transformedTangent;
      }
  }

  return TransformedTN(transformedNormal,transformedTangent);
}

