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

// SPDX-License-Identifier: MIT
// Copyright (c) 2026 @munrocket
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#define PI         3.14159265359
#define TAU        6.28318530718
#define HPI        1.57079632679
#define SQRT_HALF  0.70710678118
#define SQRT2      1.41421356237
#define SQRT_THIRD 0.57735026919

/* quaternions */

vec4 qmult(vec4 p, vec4 q)
{
    vec3 pv = p.xyz,
    qv = q.xyz;
    return vec4(p.w * qv + q.w * pv + cross(pv, qv), p.w * q.w - dot(pv, qv));
}

vec4 qrotor(vec3 axis, float phi)
{
    return vec4(sin(phi * 0.5) * axis, cos(phi * 0.5));
}

vec4 qmouse(vec4 mouse_input, vec2 resolution, float time_value, float init_rotation)
{
    vec2 init = vec2(0.5 + 0.25 * init_rotation * sin(time_value), 0.5 + init_rotation * cos(time_value));
    vec2 mouse = mix(init, mouse_input.xy / resolution.xy, step(0.0027, clamp(mouse_input.x, 0.0, 1.0)));
    vec4 rot_y = qrotor(vec3(0.0, 1.0, 0.0), PI - TAU * mouse.x);
    vec4 rot_x = qrotor(vec3(1.0, 0.0, 0.0), PI * mouse.y - HPI);
    return qmult(rot_y, rot_x);
}

vec3 rotate(vec3 point, vec4 qrotor)
{
    vec3 rv = qrotor.xyz;
    return qmult(qrotor, vec4(point * qrotor.w - cross(point, rv), dot(point, rv))).xyz;
}

/* SDF functions */

float op_union(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h ) - k * h*(1.0 - h);
}

float op_substr(float d2, float d1, float k)
{
    float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
    return mix(d2, - d1, h ) + k * h*(1.0 - h);
}

#define MAX_STEPS 80.0
#define MAX_DIST 15.0
#define DIFF_EPS 0.0001
#define SHAD_EPS 0.01

float map(vec3 pos)
{
    float k = 0.1;
    float d = length(vec3(abs(pos.x), pos.yz) - vec3(0.55, - 0.15, 0.0)) - 0.48;
    float d2 = op_union(d, length(pos - vec3(0.0, - 0.18, 0.0)) - 0.45, k);
    float d3 = op_union(d2, length(pos - vec3( - 0.28, 0.18, 0.0)) - 0.4, k);
    float d4 = op_union(d3, length(pos - vec3(0.25, 0.35, 0.0)) - 0.4, k);
    return op_substr(d4, max(0.05 + pos.x, - abs(0.04 * pos.y * pos.y + 0.0175) + abs(0.04 - 0.1 * fract(0.16 + pos.x / 0.16))), 0.01);
    //return length(pos) - .5;
}

vec3 normal(vec3 pos)
{
    const vec2 e = vec2(SHAD_EPS, 0.0);
    return normalize(vec3( map(pos + e.xyy) - map(pos - e.xyy),
    map(pos + e.yxy) - map(pos - e.yxy),
    map(pos + e.yyx) - map(pos - e.yyx)));
}

vec3 get_colors(vec3 p)
{
    float a = atan(p.y, p.x) + 5.0;
    float r = length(p.xy);
    float s = r / (r * r + 0.3);
    return sqrt(sin(vec3(a, a + 1.0, a + 3.0)) * 0.5 * s + 0.5);
}

vec4 march(vec3 camera, vec3 dir)
{
    float I,
    dt,
    t = 0.0;
    vec3 pos = camera + t * dir;
    vec3 col;
    for(float i = 0.0; i < MAX_STEPS; i++)
    {
        pos = camera + t * dir;
        dt = 0.9 * map(pos);
        t += dt;
        col += get_colors(pos - 8.0 * dt);
        I = i;
        if(dt < DIFF_EPS || t > MAX_DIST) break;
    }
    col /= I;
    float k = dot(normal(pos), dir);
    I -= clamp(log2(abs(dt)), - 8.0, 8.0);
    float outside = I / 20.0;
    float inside = (1.7 + k) * log2(I) / log2(80.0);

    return vec4(col, mix(inside, outside, step(MAX_DIST, t)));
}

void main()
{
    vec2 frag_coord = gl_FragCoord.xy;

    vec2 uv = (2.0 * frag_coord - u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    vec3 dir = normalize(vec3(uv, - 2.0));
    vec3 camera = vec3(0.0, 0.00, 2.2);

    vec4 mouse_rot = qmouse(u_mouse, u_resolution, u_time + 1.9, 0.18);
    dir = rotate(dir, mouse_rot);
    camera = rotate(camera, mouse_rot);

    //vec3 col = mix(vec3(1., 0.57, 0.), vec3(0.93, 0.14, 0.), 1. - fragCoord.y / u_resolution.y);
    vec4 m = march(camera, dir);
    fragColor = vec4(pow(m.xyz * m.w, vec3(1.3)), 1.0);
}
