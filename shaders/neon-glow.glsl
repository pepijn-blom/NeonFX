// Neon text glow for NeonFX — crisp glyph core + smooth ambient halo bloom
// Keeps letterforms razor-sharp while casting an elegant neon glow.

float f(float x) {
    if (x >= 0.0031308) {
        return 1.055 * pow(x, 1.0 / 2.4) - 0.055;
    }
    return 12.92 * x;
}

float f_inv(float x) {
    if (x >= 0.04045) {
        return pow((x + 0.055) / 1.055, 2.4);
    }
    return x / 12.92;
}

vec4 toOklab(vec4 rgb) {
    vec3 c = vec3(f_inv(rgb.r), f_inv(rgb.g), f_inv(rgb.b));
    float l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
    float m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
    float s = 0.0883024619 * c.r + 0.2817188376 * c.g + 0.6299787005 * c.b;
    float l_ = pow(max(l, 0.0), 1.0 / 3.0);
    float m_ = pow(max(m, 0.0), 1.0 / 3.0);
    float s_ = pow(max(s, 0.0), 1.0 / 3.0);
    return vec4(
        0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
        1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
        0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
        rgb.a
    );
}

vec4 toRgb(vec4 oklab) {
    vec3 c = oklab.rgb;
    float l_ = c.r + 0.3963377774 * c.g + 0.2158037573 * c.b;
    float m_ = c.r - 0.1055613458 * c.g - 0.0638541728 * c.b;
    float s_ = c.r - 0.0894841775 * c.g - 1.2914855480 * c.b;
    float l = l_ * l_ * l_;
    float m = m_ * m_ * m_;
    float s = s_ * s_ * s_;
    vec3 linear_srgb = vec3(
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    );
    return vec4(
        clamp(f(linear_srgb.r), 0.0, 1.0),
        clamp(f(linear_srgb.g), 0.0, 1.0),
        clamp(f(linear_srgb.b), 0.0, 1.0),
        oklab.a
    );
}

const float DIM_CUTOFF = 0.20;
const float BRIGHT_CUTOFF = 0.48;

const float BLOOM_STRENGTH = 1.45;
const float BLOOM_RADIUS = 3.2;
const float GLYPH_LIFT = 1.15;

const float TYPING_PULSE_DURATION = 0.45;

vec2 cursorCenter(vec4 rect) {
    return vec2(rect.x + rect.z * 0.5, rect.y - rect.w * 0.5);
}

float typingPulse(vec2 fragCoord) {
    float elapsed = iTime - iTimeCursorChange;
    float heat = smoothstep(TYPING_PULSE_DURATION, 0.0, elapsed);
    if (heat <= 0.0) {
        return 0.0;
    }

    float cell = max(iCurrentCursor.z, iCurrentCursor.w);
    if (cell <= 0.0) {
        return 0.0;
    }

    vec2 curCenter = cursorCenter(iCurrentCursor);
    vec2 prevCenter = cursorCenter(iPreviousCursor);
    vec2 typedCenter = curCenter - vec2(cell, 0.0);

    float zoneTyped = 1.0 - smoothstep(0.05, 1.35, length(fragCoord - typedCenter) / cell);
    float zonePrev = 1.0 - smoothstep(0.05, 1.35, length(fragCoord - prevCenter) / cell);
    float zoneCur = 1.0 - smoothstep(0.05, 1.15, length(fragCoord - curCenter) / cell);

    return heat * max(max(zoneTyped, zonePrev), zoneCur * 0.35);
}

// Golden angle spiral sampling — isotropic, smooth Gaussian falloff with zero grain/banding
vec3 sampleBloom(vec2 uv) {
    vec2 texel = vec2(1.0) / iResolution.xy;
    vec3 glow = vec3(0.0);
    float weightSum = 0.0;

    const int SAMPLES = 16;
    const float GOLDEN_ANGLE = 2.39996323;

    for (int i = 0; i < SAMPLES; i++) {
        float fi = float(i);
        float r = sqrt((fi + 0.5) / float(SAMPLES)) * BLOOM_RADIUS;
        float theta = fi * GOLDEN_ANGLE;
        vec2 offset = vec2(cos(theta), sin(theta)) * r * texel;

        vec4 tap = toOklab(texture(iChannel0, uv + offset));

        // Only bright glyph pixels emit glow:
        float emission = smoothstep(DIM_CUTOFF, BRIGHT_CUTOFF, tap.x);
        float weight = exp(-0.5 * (r * r) / (BLOOM_RADIUS * 0.40));

        if (emission > 0.0) {
            float chromaBoost = 1.25;
            glow += vec3(tap.x * emission * 0.85, tap.y * chromaBoost * emission, tap.z * chromaBoost * emission) * weight;
        }
        weightSum += weight;
    }

    return weightSum > 0.0 ? glow / weightSum : vec3(0.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 original = texture(iChannel0, uv);
    vec4 source = toOklab(original);
    float pulse = typingPulse(fragCoord);

    // Text core mask: detects glyph presence
    float textCore = smoothstep(0.18, 0.48, source.x);

    // Halo only illuminates the background void around letters, keeping glyph core unblurred
    float haloMask = 1.0 - textCore * 0.90;

    // Calculate smooth outer ambient halo
    vec3 bloomOklab = sampleBloom(uv);
    float bloomScale = BLOOM_STRENGTH * (1.0 + pulse * 1.3);

    vec4 haloColorOklab = vec4(
        bloomOklab.x * bloomScale * haloMask,
        bloomOklab.y * bloomScale * haloMask,
        bloomOklab.z * bloomScale * haloMask,
        1.0
    );

    // Convert halo to RGB
    vec4 haloRgb = toRgb(vec4(source.x + haloColorOklab.x, source.y + haloColorOklab.y, source.z + haloColorOklab.z, 1.0));
    vec3 haloDelta = max(vec3(0.0), haloRgb.rgb - toRgb(vec4(source.x, source.y, source.z, 1.0)).rgb);

    // Crisp text: lift glyph pixels, add glowing ambient halo around them
    vec3 result = original.rgb * mix(1.0, GLYPH_LIFT, textCore) + haloDelta;

    // Typing pulse flare on outer edges
    if (pulse > 0.0) {
        float edge = pulse * haloMask;
        result += original.rgb * edge * 0.30;
    }

    // Soft highlight protection
    result = result / (1.0 + result * 0.02);

    fragColor = vec4(clamp(result, 0.0, 1.0), 1.0);
}



