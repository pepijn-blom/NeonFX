// Comet Smear — convex-quad trail with bloom, glitch, and chromatic aberration
// Adapted from sahaj-b/ghostty-cursor-shaders (MIT)

// Cyan cursor comet trail — adapted from sahaj-b/ghostty-cursor-shaders (MIT)
// With modular Trail Bloom, Trail Glitch, and Trail Chromatic Aberration passes

// sRGB -> Linear conversion (needed because Ghostty passes sRGB values but the shader pipeline operates in linear color space)
vec3 sRGBToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

// --- CONFIGURATION ---
vec4 TRAIL_COLOR = vec4(sRGBToLinear(vec3(1.0, 0.4706, 0.0)), 1.0); // #ff7800
const float DURATION = 0.36; // total animation time
const float TRAIL_SIZE = 1.0; // 0.0 = all corners move together. 1.0 = max smear (leading corners jump instantly)

const float THRESHOLD_MIN_DISTANCE = 1.5; // min distance to show trail (units of cursor height)
const float BLUR = 1.0; // blur size in pixels (for antialiasing)
const float TRAIL_THICKNESS = 1.0;  // 1.0 = full cursor height, 0.0 = zero height
const float TRAIL_THICKNESS_X = 0.9;

const float FADE_ENABLED = 0.0; // 1.0 to enable fade gradient along the trail, 0.0 to disable
const float FADE_EXPONENT = 5.0; // exponent for fade gradient along the trail

// --- TRAIL FX MODULES (Bloom, Glitch, Chromatic Aberration) ---
const float TRAIL_BLOOM_ENABLED = 1.0;
const float TRAIL_BLOOM_STRENGTH = 0.44;
const float TRAIL_BLOOM_RADIUS = 0.8;

const float TRAIL_GLITCH_ENABLED = 1.0;
const float TRAIL_GLITCH_STRENGTH = 0.013;
const float TRAIL_GLITCH_STATIC = 0.017;

const float TRAIL_ABERRATION_ENABLED = 1.0;
const float TRAIL_ABERRATION_STRENGTH = 0.0022;


// --- CONSTANTS for easing & hashes ---
const float PI = 3.14159265359;

float hash11(float p) {
    return fract(sin(p * 127.1) * 43758.5453123);
}

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// EaseOutCirc
float ease(float x) {
    return sqrt(1.0 - pow(x - 1.0, 2.0));
}

float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b) {
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

float getSdfConvexQuad(in vec2 p, in vec2 v1, in vec2 v2, in vec2 v3, in vec2 v4) {
    float s = 1.0;
    float d = dot(p - v1, p - v1);

    d = seg(p, v1, v2, s, d);
    d = seg(p, v2, v3, s, d);
    d = seg(p, v3, v4, s, d);
    d = seg(p, v4, v1, s, d);

    return s * sqrt(d);
}

vec2 normalizeCoord(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float antialising(float distance, float blurAmount) {
    return 1.0 - smoothstep(0.0, normalizeCoord(vec2(blurAmount, blurAmount), 0.0).x, distance);
}

float getDurationFromDot(float dot_val, float DURATION_LEAD, float DURATION_SIDE, float DURATION_TRAIL) {
    float isLead = step(0.5, dot_val);
    float isSide = step(-0.5, dot_val) * (1.0 - isLead);
    float duration = mix(DURATION_TRAIL, DURATION_SIDE, isSide);
    duration = mix(duration, DURATION_LEAD, isLead);
    return duration;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);

    vec2 vu = normalizeCoord(fragCoord, 1.0);
    vec2 offsetFactor = vec2(-0.5, 0.5);

    vec4 currentCursor = vec4(normalizeCoord(iCurrentCursor.xy, 1.0), normalizeCoord(iCurrentCursor.zw, 0.0));
    vec4 previousCursor = vec4(normalizeCoord(iPreviousCursor.xy, 1.0), normalizeCoord(iPreviousCursor.zw, 0.0));

    vec2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor);
    vec2 halfSizeCC = currentCursor.zw * 0.5;
    vec2 centerCP = previousCursor.xy - (previousCursor.zw * offsetFactor);
    vec2 halfSizeCP = previousCursor.zw * 0.5;

    float sdfCurrentCursor = getSdfRectangle(vu, centerCC, halfSizeCC);
    float lineLength = distance(centerCC, centerCP);
    float minDist = currentCursor.w * THRESHOLD_MIN_DISTANCE;

    vec4 newColor = vec4(fragColor);
    float baseProgress = iTime - iTimeCursorChange;

    if (lineLength > minDist && baseProgress < DURATION - 0.001) {
        float cc_half_height = currentCursor.w * 0.5;
        float cc_center_y = currentCursor.y - cc_half_height;
        float cc_new_half_height = cc_half_height * TRAIL_THICKNESS;
        float cc_new_top_y = cc_center_y + cc_new_half_height;
        float cc_new_bottom_y = cc_center_y - cc_new_half_height;

        float cc_half_width = currentCursor.z * 0.5;
        float cc_center_x = currentCursor.x + cc_half_width;
        float cc_new_half_width = cc_half_width * TRAIL_THICKNESS_X;
        float cc_new_left_x = cc_center_x - cc_new_half_width;
        float cc_new_right_x = cc_center_x + cc_new_half_width;

        vec2 cc_tl = vec2(cc_new_left_x, cc_new_top_y);
        vec2 cc_tr = vec2(cc_new_right_x, cc_new_top_y);
        vec2 cc_bl = vec2(cc_new_left_x, cc_new_bottom_y);
        vec2 cc_br = vec2(cc_new_right_x, cc_new_bottom_y);

        float cp_half_height = previousCursor.w * 0.5;
        float cp_center_y = previousCursor.y - cp_half_height;
        float cp_new_half_height = cp_half_height * TRAIL_THICKNESS;
        float cp_new_top_y = cp_center_y + cp_new_half_height;
        float cp_new_bottom_y = cp_center_y - cp_new_half_height;

        float cp_half_width = previousCursor.z * 0.5;
        float cp_center_x = previousCursor.x + cp_half_width;
        float cp_new_half_width = cp_half_width * TRAIL_THICKNESS_X;
        float cp_new_left_x = cp_center_x - cp_new_half_width;
        float cp_new_right_x = cp_center_x + cp_new_half_width;

        vec2 cp_tl = vec2(cp_new_left_x, cp_new_top_y);
        vec2 cp_tr = vec2(cp_new_right_x, cp_new_top_y);
        vec2 cp_bl = vec2(cp_new_left_x, cp_new_bottom_y);
        vec2 cp_br = vec2(cp_new_right_x, cp_new_bottom_y);

        const float DURATION_TRAIL = DURATION;
        const float DURATION_LEAD = DURATION * (1.0 - TRAIL_SIZE);
        const float DURATION_SIDE = (DURATION_LEAD + DURATION_TRAIL) / 2.0;

        vec2 moveVec = centerCC - centerCP;
        vec2 s = sign(moveVec);

        float dot_tl = dot(vec2(-1.0, 1.0), s);
        float dot_tr = dot(vec2(1.0, 1.0), s);
        float dot_bl = dot(vec2(-1.0, -1.0), s);
        float dot_br = dot(vec2(1.0, -1.0), s);

        float dur_tl = getDurationFromDot(dot_tl, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);
        float dur_tr = getDurationFromDot(dot_tr, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);
        float dur_bl = getDurationFromDot(dot_bl, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);
        float dur_br = getDurationFromDot(dot_br, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);

        float isMovingRight = step(0.5, s.x);
        float isMovingLeft = step(0.5, -s.x);

        float dot_right_edge = (dot_tr + dot_br) * 0.5;
        float dur_right_rail = getDurationFromDot(dot_right_edge, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);

        float dot_left_edge = (dot_tl + dot_bl) * 0.5;
        float dur_left_rail = getDurationFromDot(dot_left_edge, DURATION_LEAD, DURATION_SIDE, DURATION_TRAIL);

        float final_dur_tl = mix(dur_tl, dur_left_rail, isMovingLeft);
        float final_dur_bl = mix(dur_bl, dur_left_rail, isMovingLeft);
        float final_dur_tr = mix(dur_tr, dur_right_rail, isMovingRight);
        float final_dur_br = mix(dur_br, dur_right_rail, isMovingRight);

        float prog_tl = ease(clamp(baseProgress / final_dur_tl, 0.0, 1.0));
        float prog_tr = ease(clamp(baseProgress / final_dur_tr, 0.0, 1.0));
        float prog_bl = ease(clamp(baseProgress / final_dur_bl, 0.0, 1.0));
        float prog_br = ease(clamp(baseProgress / final_dur_br, 0.0, 1.0));

        vec2 v_tl = mix(cp_tl, cc_tl, prog_tl);
        vec2 v_tr = mix(cp_tr, cc_tr, prog_tr);
        vec2 v_br = mix(cp_br, cc_br, prog_br);
        vec2 v_bl = mix(cp_bl, cc_bl, prog_bl);

        // --- TRAIL GLITCH JITTER ---
        vec2 vu_sampled = vu;
        if (TRAIL_GLITCH_ENABLED > 0.5) {
            float scanSeed = float(int(fragCoord.y) * 19 + int(iTime * 60.0));
            float h = hash11(scanSeed);
            if (h < TRAIL_GLITCH_STRENGTH * 2.5) {
                float dir = (h < TRAIL_GLITCH_STRENGTH * 1.25) ? 1.0 : -1.0;
                vu_sampled.x += dir * TRAIL_GLITCH_STRENGTH * 0.04;
            }
        }

        // --- TRAIL CHROMATIC ABERRATION SPLIT ---
        vec2 split = vec2(0.0);
        if (TRAIL_ABERRATION_ENABLED > 0.5) {
            split = vec2(TRAIL_ABERRATION_STRENGTH * 0.5, 0.0);
        }

        float sdfCenter = getSdfConvexQuad(vu_sampled, v_tl, v_tr, v_br, v_bl);
        float sdfR = (TRAIL_ABERRATION_ENABLED > 0.5) ? getSdfConvexQuad(vu_sampled + split, v_tl, v_tr, v_br, v_bl) : sdfCenter;
        float sdfB = (TRAIL_ABERRATION_ENABLED > 0.5) ? getSdfConvexQuad(vu_sampled - split, v_tl, v_tr, v_br, v_bl) : sdfCenter;

        float effectiveBlur = BLUR;
        if (BLUR < 2.5) {
            float isDiagonal = abs(s.x) * abs(s.y);
            effectiveBlur = mix(0.0, BLUR, isDiagonal);
        }

        float shapeCenter = antialising(sdfCenter, effectiveBlur);
        float shapeR = antialising(sdfR, effectiveBlur);
        float shapeB = antialising(sdfB, effectiveBlur);

        // --- TRAIL BLOOM HALO ---
        float bloomCenter = 0.0;
        float bloomR = 0.0;
        float bloomB = 0.0;

        if (TRAIL_BLOOM_ENABLED > 0.5) {
            float bRadius = TRAIL_BLOOM_RADIUS * 0.012;
            bloomCenter = exp(-max(0.0, sdfCenter) / max(0.0005, bRadius)) * TRAIL_BLOOM_STRENGTH;
            if (TRAIL_ABERRATION_ENABLED > 0.5) {
                bloomR = exp(-max(0.0, sdfR) / max(0.0005, bRadius)) * TRAIL_BLOOM_STRENGTH;
                bloomB = exp(-max(0.0, sdfB) / max(0.0005, bRadius)) * TRAIL_BLOOM_STRENGTH;
            } else {
                bloomR = bloomCenter;
                bloomB = bloomCenter;
            }
        }

        vec4 trail = TRAIL_COLOR;
        if (FADE_ENABLED > 0.5) {
            vec2 fragVec = vu - centerCP;
            float fadeProgress = clamp(dot(fragVec, moveVec) / (dot(moveVec, moveVec) + 1e-6), 0.0, 1.0);
            trail.a *= pow(fadeProgress, FADE_EXPONENT);
        }

        float alphaG = clamp(trail.a * (shapeCenter + bloomCenter), 0.0, 1.0);
        float alphaR = clamp(trail.a * (shapeR + bloomR), 0.0, 1.0);
        float alphaB = clamp(trail.a * (shapeB + bloomB), 0.0, 1.0);

        vec3 trailRgb = trail.rgb;
        if (TRAIL_GLITCH_ENABLED > 0.5) {
            float noise = hash21(fragCoord + float(int(iTime * 45.0)));
            if (noise > 1.0 - TRAIL_GLITCH_STATIC * 2.0 && (shapeCenter + bloomCenter) > 0.01) {
                trailRgb = mix(trailRgb, vec3(1.0), 0.85);
                float sparkAlpha = 0.40;
                alphaR = max(alphaR, sparkAlpha);
                alphaG = max(alphaG, sparkAlpha);
                alphaB = max(alphaB, sparkAlpha);
            }
        }


        // Composite channels with chromatic separation
        vec3 finalColor = fragColor.rgb;
        finalColor.r = mix(finalColor.r, trailRgb.r, alphaR);
        finalColor.g = mix(finalColor.g, trailRgb.g, alphaG);
        finalColor.b = mix(finalColor.b, trailRgb.b, alphaB);

        // Punch hole for current cursor
        finalColor = mix(finalColor, fragColor.rgb, step(sdfCurrentCursor, 0.0));
        newColor = vec4(finalColor, fragColor.a);
    }

    fragColor = newColor;
}
