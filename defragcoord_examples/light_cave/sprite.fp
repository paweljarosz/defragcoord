#version 140

in mediump vec2 var_texcoord0;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;
uniform fs_uniforms
{
    mediump vec4 tint;
    mediump vec4 time_res_scroll;
    mediump vec4 mouse;
};

#define u_time time_res_scroll.x
#define u_resolution time_res_scroll.yz
#define u_scroll time_res_scroll.w
#define u_mouse mouse
#define fragColor out_fragColor

// ------------------------------------------------------
// Put your FragCoord.xyz shader below:
// ------------------------------------------------------

// SPDX-License-Identifier: CC-BY-4.0
// Copyright (c) 2026 @altunenes
//[LICENSE] https://creativecommons.org/licenses/by/4.0/

#define T u_time
#define R u_resolution.xy
#define rot(a) mat2(cos(a), cos((a)+11.0), cos((a)+33.0), cos(a))
#define P(x, y) pow(abs(x), y)
#define X(a, b) max(dot(a, b), 0.0)
#define fk(w) (1.0+0.1*(sin(T*25.0+(w)*93.1)*cos(T*14.0+(w)*17.4)))
#define n(p) (sin((p).x*3.0+sin((p).y*2.7))*cos((p).y*1.1+cos((p).x*2.3)))

float f(vec3 p)
{
    float v = 0.0, a = 1.0;
    for (int i = 0; i++ < 7; p *= 2.0, a *= 0.5)
    {
        v += n(p.xy + p.z * 0.5) * a;
    }
    return v;
}

float m(vec3 p)
{
    p.xy *= rot(p.z * 1.1);
    return 0.2 * (1.0 - length(p.xy)) - f(p + T * 0.1) * 0.06;
}

vec4 gb(float z)
{
    float i = floor((z + 2.5) * 0.2);
    return vec4(cos(i * 2.4) * 0.6, sin(i * 2.4) * 0.6, i * 5.0, i);
}

vec3 bc(float i)
{
    float h = fract(sin(i * 13.54) * 453.21);
    return h < 0.33 ? vec3(1, 8, 9) * 0.1 : (h < 0.66 ? vec3(9, 2, 6) * 0.1 : vec3(10, 6, 1) * 0.1);
}

void main()
{
    vec2 U = gl_FragCoord.xy;

    vec3 d = normalize(vec3((U - 0.5 * R) / R.y, 1.0)),
    o = vec3(sin(T * 0.3) * 0.2, cos(T * 0.2) * 0.2, T * 1.2),
    p, c, g2 = vec3(0), nn, l, b;

    d.xy *= rot(T * 0.15);
    bool ht = false;
    float t = 0.0, w, hi, g1 = 0.0, dc, db;
    vec4 bi;

    for (int i = 0; i++ < 250;)
    {
        p = o + d * t;
        dc = m(p);
        bi = gb(p.z);
        db = length(p - bi.xyz) - 0.03;

        w = min(dc, db);
        g1 += 0.002 / (0.01 + abs(dc));
        g2 += (vec3(0.0003 / (0.001 + db * db)) + bc(bi.w) * 0.005 / (0.02 + abs(db))) * fk(bi.w);

        if (abs(w) < 0.001 + t / 1000.0 || t > 25.0)
        {
            if (db < dc)
            {
                ht = true;
                hi = bi.w;
            }
            break;
        }
        t += w * 0.8;
    }

    if (t <= 25.0)
    {
        if (ht) c = vec3(12) + bc(hi) * 5.0;
        else
        {
            vec2 e = vec2(0.001 + t / 1000.0, 0);
            nn = normalize(vec3(m(p + e.xyy) - m(p - e.xyy), m(p + e.yxy) - m(p - e.yxy), m(p + e.yyx) - m(p - e.yyx)));

            vec3 q = p;
            q.xy *= rot(q.z * 1.1);
            c = mix(vec3(1, 3, 8) * 0.05, vec3(9, 4, 1) * 0.1, P(max(min(f(q + T * 0.1) + 0.5, 1.0), 0.0), 2.0));

            l = o + vec3(0, 0, 5) - p;
            float d1 = length(l);
            l /= d1;

            c = c * 0.03 + (c * X(nn, l) * 1.5 + vec3(1, 0.8, 0.6) * P(X(nn, normalize(l - d)), 24.0) * smoothstep(20.0, 5.0, t) * 1.5) / (1.0 + d1 * d1 * 0.08);

            bi = gb(p.z);
            l = bi.xyz - p;
            float d2 = length(l);
            l /= d2;
            b = bc(bi.w);

            c += ((c * X(nn, l) * 2.5) + (b * P(X(nn, normalize(l - d)), 16.0) * 4.0)) * b * fk(bi.w) * (0.5 + 0.5 * fract(sin(bi.w * 88.1) * 12.3)) / (1.0 + d2 * d2 * 1.5);

            float oa = 0.0, s = 1.0;
            for (int i = 1; i++ < 5; s *= 0.9)
            {
                float h = 0.01 + 0.03 * float(i);
                oa += (h - m(p + h * nn)) * s;
                if (oa > 0.33) break;
            }

            c = (c + vec3(5, 3, 8) * 0.1 * P(1.0 - X(nn, -d), 4.0) * 0.6 / (1.0 + d1 * d1 * 0.08)) * max(1.0 - 3.0 * oa, 0.0);
        }
    }

    c = mix(vec3(2, 0, 5) * 0.01, c, 1.0 / exp(0.12 * t))
    + vec3(9, 3, 1) * 0.1 * g1 * 0.02 / exp(0.05 * t)
    + g2 / exp(0.03 * t);

    c = c * (2.51 * c + 0.03) / (c * (2.43 * c + 0.59) + 0.14);

    U /= R;
    U *= 1.0 - U;
    fragColor = vec4(P(c * P(16.0 * U.x * U.y, 0.25), vec3(2.5)), 1);
}