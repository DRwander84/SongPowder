#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    vec2 resolution;   // pixels
    float radius;      // window corner radius, pixels
    vec4 base0;        // gradient top
    vec4 base1;        // gradient bottom
    vec4 colA;         // liquid colour 1
    vec4 colB;         // liquid colour 2
    vec4 colC;         // glossy highlight colour
    vec4 params;       // x: strength of colA, y: strength of colB, z: strength of colC
} ubuf;

float sdRoundBox(vec2 p, vec2 b, float r)
{
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main()
{
    vec2 px = qt_TexCoord0 * ubuf.resolution;

    // rounded window corners (anti-aliased), replaces an offscreen mask
    float d = sdRoundBox(px - ubuf.resolution * 0.5, ubuf.resolution * 0.5, ubuf.radius);
    float mask = clamp(0.5 - d, 0.0, 1.0);

    vec2 uv = px / max(ubuf.resolution.x, ubuf.resolution.y) * 1.7;
    float t = ubuf.time;

    // domain-warped flow: a few cheap sine folds give smooth, liquid-like movement
    vec2 p = uv;
    p += 0.55 * vec2(sin(p.y * 2.1 + t * 0.30), cos(p.x * 2.3 - t * 0.26));
    p += 0.28 * vec2(sin(p.y * 4.0 - t * 0.37 + 1.7), cos(p.x * 3.7 + t * 0.33 + 0.6));
    p += 0.12 * vec2(sin(p.y * 7.3 + t * 0.45), cos(p.x * 6.9 - t * 0.41));

    float f1 = 0.5 + 0.5 * sin(p.x * 1.9 + p.y * 1.4 + t * 0.18);
    float f2 = 0.5 + 0.5 * sin(p.y * 2.2 - p.x * 1.0 - t * 0.22 + 1.5);
    float f3 = 0.5 + 0.5 * sin(length(p - vec2(0.9, 0.5)) * 2.4 - t * 0.28);

    vec3 col = mix(ubuf.base0.rgb, ubuf.base1.rgb, smoothstep(0.0, 1.0, qt_TexCoord0.y * 0.85 + 0.15 * f3));
    col = mix(col, ubuf.colA.rgb, smoothstep(0.30, 0.95, f1) * ubuf.params.x);
    col = mix(col, ubuf.colB.rgb, smoothstep(0.35, 0.95, f2) * ubuf.params.y);

    // glossy liquid ridges: thin bright lines where the two flows meet, plus a broad soft sheen
    float ridge = abs(f1 - f2);
    col += ubuf.colC.rgb * ubuf.params.z * ((1.0 - smoothstep(0.0, 0.05, ridge)) * 0.55 + pow(f3, 7.0) * 0.45);

    // faint dithering against gradient banding
    col += (hash(px + fract(t)) - 0.5) / 255.0;

    fragColor = vec4(col, 1.0) * mask * ubuf.qt_Opacity;
}
