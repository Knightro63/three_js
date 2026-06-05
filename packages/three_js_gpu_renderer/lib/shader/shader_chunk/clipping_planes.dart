import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart';

const ShaderChunk clippingChunk = ShaderChunk(
  name: 'common.clipping',
  stage: ShaderStageType.fragment,
  source: '''
fn evaluateClippingPlanes(worldPosition: vec3<f32>) {
    // Extract the number of active planes from your uniforms block layout (Float index offset 52)
    let numPlanes = i32(uniforms.clippingPlaneCount); 
    
    for (var i = 0; i < numPlanes; i = i + 1) {
        // Look up the specific plane equation vector array
        let plane = uniforms.clippingPlanes[i];
        
        // 💡 THE CLIPPING MATHEMATICS:
        // Calculate the dot product of the pixel's position and the plane normal, plus the constant.
        // Signed Distance = (Pos.x * N.x) + (Pos.y * N.y) + (Pos.z * N.z) + Constant
        let distanceToPlane = dot(worldPosition, plane.xyz) + plane.w;
        
        // If the distance is less than 0.0, the pixel resides on the clipped side of the plane!
        if (distanceToPlane < 0.0) {
            // Discard completely stops processing, preventing color or depth writes!
            discard;
        }
    }
}
  ''',
);