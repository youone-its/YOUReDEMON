shader_type canvas_item;

uniform vec4 color : source_color = vec4(0.5, 0.02, 0.02, 1.0); // Dark Rusty Red (Silent Hill style)
uniform float intensity = 0.0; // Controlled by script (0.0 to 1.0)
uniform float time_scale = 0.2;

// Simple pseudo-random noise
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    f = f * f * (3.0 - 2.0 * f);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 uv) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.50)));
    for (int i = 0; i < 5; ++i) {
        v += a * noise(uv);
        uv = rot * uv * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    
    // 1. Foggy Noise Texture
    // Slower, more "cloud-like" movement
    float fog_noise = fbm(UV * 4.0 + vec2(TIME * time_scale));
    
    // 2. Determine Coverage based on Intensity
    // Threshold moves towards center as intensity increases
    // Range: 0.8 (Corners only) -> 0.1 (Almost full screen)
    float coverage_threshold = 0.8 - (intensity * 0.6);
    
    // 3. Combine Distance and Noise
    // The "shape" of the vignette is distorted by the fog noise
    float shape = dist + (fog_noise * 0.3);
    
    // 4. Calculate Alpha
    // Soft edge transition
    float alpha = smoothstep(coverage_threshold, coverage_threshold + 0.5, shape);
    
    // Boost opacity of the noise within the vignette area for texture
    alpha *= (0.5 + 0.5 * fog_noise);
    
    // Final Opacity Scaling
    // Even at max intensity, we don't want it 100% solid, just heavy fog
    alpha *= 0.3 + (intensity * 0.7); 
    
    COLOR = vec4(color.rgb, alpha);
}
