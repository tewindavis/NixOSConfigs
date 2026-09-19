// Cursor trail: when the cursor jumps (not ordinary typing), a smear in the
// cursor's color sweeps from where it was to where it landed and fades out.
//
// Coordinates (OpenGL, per Ghostty's renderer): fragCoord's origin is the
// bottom-left and y points up. iCurrentCursor/iPreviousCursor are
// (x, y, width, height) with (x, y) the cursor's top-left corner, so a
// cursor covers x..x+w horizontally and y-h..y vertically.

const float DURATION = 0.18; // seconds for the trail to catch up and fade
const float MAX_ALPHA = 0.6;

float sdBox(vec2 p, vec2 halfSize) {
    vec2 d = abs(p) - halfSize;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

vec2 cursorCenter(vec4 c) {
    return c.xy + vec2(c.z, -c.w) * 0.5;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);

    float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
    if (progress >= 1.0 || iPreviousCursor.z == 0.0) {
        return;
    }

    vec2 from = cursorCenter(iPreviousCursor);
    vec2 to = cursorCenter(iCurrentCursor);
    vec2 path = to - from;
    float len2 = dot(path, path);

    // Moves of under two cells are typing or arrowing; no trail for those.
    float minMove = iCurrentCursor.z * 2.0;
    if (len2 < minMove * minMove) {
        return;
    }

    // Position of this pixel along the path, 0 at the old cursor, 1 at the
    // new one. The tail eases toward the new cursor as the trail fades.
    float t = clamp(dot(fragCoord - from, path) / len2, 0.0, 1.0);
    float tail = 1.0 - pow(1.0 - progress, 3.0);
    if (t < tail) {
        return;
    }

    vec2 center = from + path * t;
    vec2 halfSize = mix(iPreviousCursor.zw, iCurrentCursor.zw, t) * 0.5;
    float inside = 1.0 - smoothstep(-1.0, 1.0, sdBox(fragCoord - center, halfSize));

    // Fainter toward the tail and as the whole trail ages.
    float alpha = inside * MAX_ALPHA * (1.0 - progress) * mix(0.25, 1.0, t);
    fragColor.rgb = mix(fragColor.rgb, iCurrentCursorColor.rgb, alpha);
}
