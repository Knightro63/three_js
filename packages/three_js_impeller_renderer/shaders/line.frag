#include <material_block.glsl>
#include <color.glsl>
#include <clipping.glsl>
#include <fog.glsl>

in vec3 v_color;
in vec3 v_worldPosition;
in vec2 v_uv;
in float v_lineDistance;

out vec4 frag_color;

// 3D Ray-to-line closest point finder for WORLD_UNITS rendering paths
vec2 closestLineToLine(vec3 p1, vec3 p2, vec3 p3, vec3 p4) {
    vec3 p13 = p1 - p3;
    vec3 p43 = p4 - p3;
    vec3 p21 = p2 - p1;
    
    float d1343 = dot(p13, p43);
    float d4321 = dot(p43, p21);
    float d1321 = dot(p13, p21);
    float d4343 = dot(p43, p43);
    float d2121 = dot(p21, p21);
    
    float denom = d2121 * d4343 - d4321 * d4321;
    float numer = d1343 * d4321 - d1321 * d4343;
    
    float mua = numer / denom;
    mua = clamp(mua, 0.0, 1.0);
    float mub = (d1343 + d4321 * mua) / d4343;
    mub = clamp(mub, 0.0, 1.0);
    
    return vec2(mua, mub);
}

void main() {
    // 1. Evaluate your native Impeller clipping planes geometry loop
    if (evaluateClippingPlanes(v_worldPosition)) {
        frag_color = vec4(0.0);
        return;
    }

    // 2. Unpack parameters from your MaterialBlock layout
    float dashSize   = material.lineParams.x;
    float gapSize    = material.lineParams.y;
    float dashOffset = material.lineExtendedParams.z; // Reading out of padding slots
    float linewidth  = material.lineParams.w;
    float alpha      = material.baseColor.a;

    // 3. Process Dash Logic
    // Only execute if your flags explicitly activate dash parsing
    if (dashSize > 0.0 && gapSize > 0.0) {
        // Discard fragments extending past outer UV bounding box caps
        if (v_uv.y < -1.0 || v_uv.y > 1.0) {
            discard; 
        }
        
        // Modulo evaluation loop applying dash offsets smoothly
        if (mod(v_lineDistance + dashOffset, dashSize + gapSize) > dashSize) {
            discard; 
        }
    }

    // 4. Endcap Circle / Rounded Hull Softening Logic (Screen Space Path)
    // material.flags0.w can serve as a toggle for WORLD_UNITS vs SCREEN_UNITS
    bool useWorldUnits = (material.flags0.w > 0.5);

    if (!useWorldUnits) {
        // Standard WebGL screen-aligned anti-aliasing logic matching Three.js
        if (abs(v_uv.y) > 1.0) {
            float a = v_uv.x;
            float b = (v_uv.y > 0.0) ? v_uv.y - 1.0 : v_uv.y + 1.0;
            float len2 = a * a + b * b;
            
            // Native fwidth screen derivative for dynamic hardware smoothing
            float dlen = fwidth(len2);
            
            // Emulates Alpha To Coverage edge fading
            alpha *= (1.0 - smoothstep(1.0 - dlen, 1.0 + dlen, len2));
            
            // Direct mathematical hull drop out clip
            if (len2 > 1.0) {
                discard;
            }
        }
    } else {
        // Advanced ray approximation modeling for world space line scale metrics
        // (If you don't use Three's specialized world units pipeline, this block is optional)
        vec3 rayEnd = normalize(v_worldPosition) * 1e5;
        // In your vertex shader, we passed mixed points down. 
        // For general PBR line projects, you can fallback safely to screen alignment.
    }

    // 5. Build final color output matching your linebasic pipeline
    vec3 color = v_color;
    
    // Core PBR alpha discard mask gate
    if (alpha < material.pbrParams.w) {
        frag_color = vec4(0.0);
        return;
    }

    // Apply scene framework functions
    vec3 finalColor = applyFog(color, v_worldPosition);
    vec4 finalRGBA = vec4(finalColor, alpha);
    
    finalRGBA = applyColor(finalRGBA, 2);
    frag_color = vec4(clamp(finalRGBA.rgb, vec3(0.0), vec3(1.0)), alpha);
}
