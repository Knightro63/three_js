import 'package:three_js_gpu_renderer/shader/shader_chunk_registry.dart';

const List<ShaderChunk> master = [
  ShaderChunk(
    name: 'material.master.vertex.input',
    stage: ShaderStageType.vertex,
    source: '''
struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) color: vec3<f32>,
    {{VERTEX_INPUT_EXTRA}}
}

struct MasterVertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec3<f32>,
    @location(1) worldPosition: vec3<f32>,
    @location(2) worldNormal: vec3<f32>,
    {{VERTEX_OUTPUT_EXTRA}}
}
''',
  ),
  ShaderChunk(
    name: 'material.master.vertex.main',
    stage: ShaderStageType.vertex,
    source: '''
#include <common.uniforms>
#include <material.master.vertex.input>

@vertex
fn vs_main(input: VertexInput) -> MasterVertexOutput {
    var output: MasterVertexOutput;
    var position = input.position;
    var normal = input.normal;
    var vertexColor = input.color;

    // Safety fallback for meshes without vertex colors assigned
    if (length(vertexColor) <= 0.0) {
        vertexColor = vec3<f32>(1.0);
    }

    {{VERTEX_ASSIGN_EXTRA}}

    // ========================================================
    // 1. TRANSFORM POSITION (WebGL: mvPosition = modelViewMatrix * vec4(position, 1.0))
    // ========================================================
    let worldPosition4 = uniforms.modelMatrix * vec4<f32>(position, 1.0);
    output.worldPosition = worldPosition4.xyz;

    let viewPosition = uniforms.scene.viewMatrix * worldPosition4;
    output.position = uniforms.scene.projectionMatrix * viewPosition;

    // ========================================================
    // 2. TRANSFORM NORMALS (WebGL Parity: transformDirection(normal, modelMatrix))
    // ========================================================
    // Setting W to 0.0 guarantees that spatial translations don't affect vector orientation.
    // We transform the normal into world space and normalize it immediately.
    let transformedNormal = (uniforms.modelMatrix * vec4<f32>(normal, 0.0)).xyz;
    output.worldNormal = normalize(transformedNormal);

    // ========================================================
    // 3. COLOR AND ALBEDO BOUNDS ASSIGNMENT
    // ========================================================
    let materialColor = uniforms.baseColor.rgb;
    output.color = materialColor * vertexColor;

    return output;
}
''',
  ),
  ShaderChunk(
    name: 'material.master.fragment.input',
    stage: ShaderStageType.fragment,
    source: '''
struct MasterFragmentInput {
    @location(0) color: vec3<f32>,
    @location(1) worldPosition: vec3<f32>,
    @location(2) worldNormal: vec3<f32>,
    {{FRAGMENT_INPUT_EXTRA}}
}
''',
  ),
  ShaderChunk(
    name: 'material.master.fragment.main',
    stage: ShaderStageType.fragment,
    source: '''
#include <common.uniforms>
#include <common.color>
#include <common.normal>
#include <common.fog>
#include <lights.pbr>
#include <material.master.fragment.input>

{{FRAGMENT_BINDINGS}}

@fragment
fn fs_main(input: MasterFragmentInput) -> @location(0) vec4<f32> {
    
    // ========================================================
    // 1. INITIALIZE DIFFUSE COLOR (Parity: vec4 diffuseColor = vec4(diffuse, opacity))
    // ========================================================
    // uniforms.baseColor.rgb holds your traditional WebGL 'diffuse' parameter vector
    let diffuse = uniforms.baseColor.rgb;
    let opacity = uniforms.baseColor.a;
    
    // Mix vertex coloring tracks matching WebGL's color_fragment block
    var diffuseColor: vec4<f32> = vec4<f32>(sRGBTransferEETF(vec4<f32>(diffuse * input.color, opacity)));

    {{FRAGMENT_INIT_EXTRA}}
    
    // Optional placeholder injection slot where your texture map snippets will sample
    // and modify diffuseColor dynamically: e.g., diffuseColor *= textureSample(...)
    {{FRAGMENT_EXTRA}}

    // Extract core feature matrix matrix branching toggles 
    let useFog         = uniforms.features[0][0] > 0.5;
    let isPhongMat     = uniforms.features[0][1] > 0.5;
    let isPBRMat       = uniforms.features[0][2] > 0.5;
    let isPhysicalMat  = uniforms.features[0][3] > 0.5;
    let isPremultAlpha = uniforms.features[1][0] > 0.5;

    // Execute alpha test discarding rules early matching WebGL's alphatest_fragment block
    if (uniforms.features[3][3] > 0.5) { // featUseAlphaTest token slot
        if (diffuseColor.a < uniforms.pbrParams.w) {
            discard;
        }
    }

    // ========================================================
    // 2. RESOLVE GEOMETRY NORMALS & VIEW MANIFOLDS
    // ========================================================
    let useNormalMap = uniforms.features[0][3] > 0.5;

    var normalMapBytes = vec3<f32>(0.5, 0.5, 1.0); // Neutral flat normal fallback bytes
    var uvCoords = vec2<f32>(0.0);

    let N = resolveNormal(input.worldNormal, input.worldPosition, uvCoords, normalMapBytes);
    let V = normalize(uniforms.scene.cameraPosition.xyz - input.worldPosition);
    let dotNV = max(dot(N, V), 0.0001);

    var outgoingLight: vec3<f32> = diffuseColor.rgb;

    // ========================================================
    // 3. PHYSICAL & STANDARD MATERIAL ACCUMULATION LOOPS
    // ========================================================
    if (isPBRMat || isPhysicalMat) {
        let roughness = clamp(uniforms.pbrParams.x, 0.04, 1.0);
        let metalness = uniforms.pbrParams.y;
        
        var F0 = mix(vec3<f32>(0.04), diffuseColor.rgb, metalness);
        var directDiffuse  = vec3<f32>(0.0);
        var directSpecular = vec3<f32>(0.0);
        
        // Base ambient environment baseline allocation
        var indirectDiffuse = uniforms.scene.ambientColor.rgb * diffuseColor.rgb;
        
        let totalLights = i32(uniforms.scene.cameraPosition.w);
        for (var i = 0; i < totalLights; i = i + 1) {
            let light = uniforms.scene.lights[i];
            let L = normalize(-light.positionOrDirection.xyz);
            let H = normalize(V + L);
            let dotNL = max(dot(N, L), 0.0);

            if (dotNL > 0.0) {
                let D = ndfGGX(max(dot(N, H), 0.0), roughness);
                let G = geometrySmith(dotNL, dotNV, roughness);
                let F = fresnelSchlick(max(dot(L, H), 0.0), F0);

                let specularBRDF = (D * G * F) / (4.0 * dotNV * dotNL + 0.0001);
                let kD = (vec3<f32>(1.0) - F) * (1.0 - metalness);
                
                let lightLuminance = light.colorAndIntensity.rgb * light.colorAndIntensity.a * dotNL;
                
                directDiffuse  += (kD * diffuseColor.rgb / 3.14159) * lightLuminance;
                directSpecular += specularBRDF * lightLuminance;
            }
        }
        
        outgoingLight = directDiffuse + indirectDiffuse + directSpecular;

        // ========================================================
        // 4. ADVANCED PHYSICAL PROPERTIES MODULATION (Sheen & Clearcoat)
        // ========================================================
        if (isPhysicalMat) {
            // A. USE_SHEEN Implementation with Energy Compensation Math
            let sheen = uniforms.sheenColorAndIntensity.a;
            if (sheen > 0.0) {
                let sheenColor = uniforms.sheenColorAndIntensity.rgb;
                let maxSheen = max(sheenColor.r, max(sheenColor.g, sheenColor.b));
                
                // Perfect WebGL match: float sheenEnergyComp = 1.0 - 0.157 * max3(material.sheenColor);
                let sheenEnergyComp = 1.0 - 0.157 * maxSheen;
                
                // Mix in rough micro-velvet sheen edges
                outgoingLight = (outgoingLight * sheenEnergyComp) + (sheenColor * sheen * 0.5);
            }

            // B. USE_CLEARCOAT Implementation with Schlick Layer Masking
            let clearcoat = uniforms.materialParams.y;
            if (clearcoat > 0.0) {
                let ccRoughness = clamp(uniforms.materialParams.z, 0.04, 1.0);
                
                // Re-evaluate specular reflection intensity across clearcoat boundaries
                let Fcc = fresnelSchlick(dotNV, vec3<f32>(0.04)) * clearcoat;
                
                // Attenuate standard base layer lighting by clearcoat reflection coefficients
                outgoingLight = outgoingLight * (1.0 - Fcc) + (vec3<f32>(1.0, 1.0, 1.0) * clearcoat * 0.25);
            }
        }
    } 
    else if (isPhongMat) {
        // Fallback to Phong Shading
        outgoingLight = calculatePhongLighting(N, V, input.worldPosition, diffuseColor.rgb);
    } 
    else {
        // Fallback to Unlit Ambient Shading
        outgoingLight = uniforms.scene.ambientColor.rgb * diffuseColor.rgb;
    }

    // ========================================================
    // 5. POST-PROCESSING ENGINES (Emissive, ColorSpace, Fog)
    // ========================================================
    // Replicates WebGL: outgoingLight + totalEmissiveRadiance
    var finalRadianceColor = outgoingLight + (uniforms.emissiveColor.rgb * uniforms.emissiveColor.a);
    var outColorVec = applyColor(vec4<f32>(finalRadianceColor, diffuseColor.a));

    if (useFog) {
      outColorVec = vec4<f32>(applyFog(outColorVec.rgb, input.worldPosition), outColorVec.a);
    }

    if (isPremultAlpha) {
      outColorVec = vec4<f32>(outColorVec.rgb * outColorVec.a, outColorVec.a);
    }

    return vec4<f32>(clamp(outColorVec.rgb, vec3<f32>(0.0), vec3<f32>(1.0)), outColorVec.a);
}
''',
  ),
];
