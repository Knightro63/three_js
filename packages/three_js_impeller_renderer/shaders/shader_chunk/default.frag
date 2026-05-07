#version 460 core

// Explicit output location for the final pixel color
layout(location = 0) out vec4 fragColor;

/**
 * Converts: gl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );
 * A standard red "error" or "default" shader.
 */
void main() {
    fragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
