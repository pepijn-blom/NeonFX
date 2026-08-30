// Cursor glitch — visible neon tear on typing edges + stronger burst on cursor mode changes.

const float GLITCH_DURATION = 0.34;
const float GLITCH_RADIUS = 0.11;
const float TEAR_STRENGTH = 0.031;

const float RGB_SPLIT_MAX = 0.0035;
const float STATIC_DENSITY = 0.018;
const float WIDTH_CHANGE_THRESHOLD = 0.5;

float hash11(float p) {
    return fract(sin(p * 127.1) * 43758.5453123);
}

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 getCursorCenter(vec4 rect) {
    return vec2(rect.x + rect.z * 0.5, rect.y - rect.w * 0.5);
}

float textCore(vec3 rgb) {
    return smoothstep(0.16, 0.46, dot(rgb, vec3(0.299, 0.587, 0.114)));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 original = texture(iChannel0, uv);

    // Leaving the window turns a bar cursor into a hollow block. That looks
    // like a mode change, so the tear would start at full strength and then
    // freeze on the last caret because unfocused surfaces stop animating.
    if (iFocus == 0) {
        fragColor = original;
        return;
    }

    float core = textCore(original.rgb);

    float cellWidth = max(iCurrentCursor.z, iPreviousCursor.z);
    float widthChange = abs(iCurrentCursor.z - iPreviousCursor.z);
    float modeChange = step(cellWidth * WIDTH_CHANGE_THRESHOLD, widthChange);

    float elapsed = iTime - iTimeCursorChange;
    float heat = smoothstep(GLITCH_DURATION, 0.0, elapsed);
    if (heat <= 0.0) {
        fragColor = original;
        return;
    }

    vec2 curPos = getCursorCenter(iCurrentCursor);
    float curDist = length(fragCoord - curPos) / iResolution.y;
    float zone = smoothstep(GLITCH_RADIUS, GLITCH_RADIUS * 0.12, curDist);

    // Mode changes hit harder; typing gets a softer edge-only glitch.
    float intensity = heat * zone * mix(0.38, 1.0, modeChange) * (1.0 - core * 0.88);
    if (intensity <= 0.008) {
        fragColor = original;
        return;
    }

    vec2 displaced = uv;

    float scanSeed = float(int(fragCoord.y) * 13 + iFrame / 4);
    float lineHash = hash11(scanSeed);
    if (lineHash < intensity * 0.42) {
        float tearDir = (lineHash < intensity * 0.2) ? 1.0 : -1.0;
        displaced.x += tearDir * intensity * TEAR_STRENGTH * (0.35 + lineHash * 1.8);
    }

    displaced = clamp(displaced, 0.0, 1.0);

    float split = intensity * RGB_SPLIT_MAX;
    vec3 color;
    color.r = texture(iChannel0, clamp(displaced + vec2(split, 0.0), 0.0, 1.0)).r;
    color.g = texture(iChannel0, displaced).g;
    color.b = texture(iChannel0, clamp(displaced - vec2(split, 0.0), 0.0, 1.0)).b;

    float noise = hash21(fragCoord + float(iFrame) * 0.173);
    if (noise > 1.0 - intensity * STATIC_DENSITY) {
        color = mix(color, vec3(0.0, 0.95, 1.0), 0.35 * intensity);
    }

    color = mix(color, original.rgb, core * 0.78);
    fragColor = vec4(color, 1.0);
}
