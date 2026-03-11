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
// Copyright (c) 2026 @Xor
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

/*
"GM Shaders: Antialiasing" by @Xor

Often shaders introduce hard edges (aliasing) unintentionally.
Aliasing is fine if you're going for pixelated style, but aliasing
rarely occurs in nature and it often makes shaders look fake.

This is an extension of my Circle Anti-aliasing example:
https://www.shadertoy.com/view/XcKcWh

Here is how you can use derivatives to apply anti-aliasing on more
complicated scenarios where you don't necessarily no the distance to edges.

More on this in the full tutorial:
https://mini.gmshaders.com/p/antialiasing
*/

#define SCALE 0.5
//Cycle through demo modes:
#define MODE u_time / 3.0
//0 - Noise
//1 - Checkerboard
//2 - Dots
//3 - Ring noise

//Gamma used for correction
#define GAMMA 2.2

//L1 approximate antialiasing for continuous functions
float antialias_l1(float d)
{
    //Get gradient width
    float width = fwidth(d);
    //Calculate reciprocal scale (avoid division by 0!)
    float scale = width > 0.0? 1.0 / width : 1e7;
    //Normalize the gradient d with it's scale
    return clamp(0.5 + scale * d, 0.0, 1.0);
}

//L2 Approximate antialiasing for continuous functions
float antialias_l2(float d)
{
    //x and y derivatives
    vec2 dxy = vec2(dFdx(d), dFdy(d));
    //Get gradient width
    float width = length(dxy);
    //Calculate reciprocal scale (avoid division by 0!)
    float scale = width > 0.0? 1.0 / width : 1e7;
    //Normalize the gradient d with it's scale
    return clamp(0.5 + 0.7 * scale * d, 0.0, 1.0);
}
//For when the derivatives must be manually calculated
float antialias_l2_dxy(float d, vec2 dxy)
{
    //Get gradient width
    float width = length(dxy);
    //Calculate reciprocal scale (avoid division by 0!)
    float scale = width > 0.0? 1.0 / width : 1e7;
    //Normalize the gradient d with it's scale
    return clamp(0.5 + 0.7 * scale * d, 0.0, 1.0);
}

//Simple 2D cubic value noise function
float value(vec2 p)
{
    vec4 f = floor(vec4(p, 1.0 + p));
    vec4 s = vec4(f.zw - p, p - f.xy);
    s *= s * (3.0 - 2.0 * s);

    vec4 r = fract(sin(f.xzxz * 12.9898 + f.yyww * 78.233) * 43758.5453);
    return dot(r, s.xzxz * s.yyww);
}
//Distance function for demonstration
float grad(vec2 p)
{
    //Rotate and apply perspective
    p *= mat2(cos(u_time * 0.1 + vec4(0, 11, 33, 0))) / (1.0 - p.y * 0.005);

    //Four distance modes
    float noise = (value(p * 0.1) + value(p * 0.14)) * 10.0 - 10.0;
    float checker = sin(p.x * 0.2) * sin(p.y * 0.2) * 10.0;
    float dots = dot(sin(p * 0.5), sin(p * 0.618)) * 2.0 - 1.0;
    float rings = sin(value(p * 0.07) * 20.0 + value(p * 0.13) * 10.0);

    //Cycle through modes
    float mode = mod(float(MODE), 4.0);
    float g = noise;
    if (mode >= 1.0) g = checker;
    if (mode >= 2.0) g = dots;
    if (mode >= 3.0) g = rings;
    return g;
}

void main()
{
    //Screen centering and mouse
    vec2 center = u_resolution.xy * 0.5;
    vec2 mouse = SCALE * float(u_mouse.z > 0.0) * (center - u_mouse.xy);
    vec2 pos = SCALE * floor(gl_FragCoord.xy - center);

    //Get gradient (neighbors for manual derivatives) 
    float grad00 = grad(pos);
    float grad10 = grad(pos + vec2(1, 0));
    float grad01 = grad(pos + vec2(0, 1));
    //Compute the xy derivatives
    vec2 dxy = vec2(grad10, grad01) - grad00;

    //Alpha hard cut
    float cut = float(grad00 > 0.0);
    //Linear blending
    float lin = clamp(grad00 + 0.5, 0.0, 1.0);
    //L1 approximation
    float l1 = antialias_l1(grad00);
    //L2 with manual derivatives
    float l2 = antialias_l2_dxy(grad00, dxy);

    //Mouse to shift dividers
    pos += round(mouse);
    //Select alpha blending with dividers
    float alpha = pos.y < 0.0? (pos.x < 0.0? l1: l2) : (pos.x < 0.0? cut: lin);

    //Pick background color depending on quadrant
    vec2 quad = sign(pos);
    vec3 bac = cos(atan(quad.y, quad.x) + vec3(0, 2, 4)) * 0.1 + 0.1;

    //Blend shapes with background
    vec3 col = mix(bac, vec3(1.0), alpha);
    //Apply dividers
    col *= min(abs(pos.x), 1.0);
    col *= min(abs(pos.y), 1.0);

    //Output with gamma correction
    fragColor = vec4(pow(col, vec3(1.0 / GAMMA)), 1.0);
}