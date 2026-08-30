// Terminal CRT pass — authentic retro raster scanlines, chromatic aberration & vignette

const float SCANLINE_STRENGTH = 0.32;
const float SCANLINE_SPACING = 1.6;
const float ABERRATION = 0.0005;
const float VIGNETTE = 0.20;


void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 center = uv - 0.5;
    float edge = dot(center, center);

    // Subtle chromatic aberration
    vec2 offset = center * ABERRATION * (1.0 + edge * 2.5);
    vec3 color;
    color.r = texture(iChannel0, clamp(uv + offset, 0.0, 1.0)).r;
    color.g = texture(iChannel0, uv).g;
    color.b = texture(iChannel0, clamp(uv - offset, 0.0, 1.0)).b;

    // Authentic CRT raster beam profile
    float scan = 0.5 + 0.5 * sin((fragCoord.y / SCANLINE_SPACING) * 3.14159265 * 2.0);
    float beam = pow(scan, 1.3);
    color *= mix(1.0, beam * 0.95 + 0.05, SCANLINE_STRENGTH);

    // Corner vignette
    color *= 1.0 - VIGNETTE * edge * 2.0;

    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}

