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
"GM Shaders: DDA" by @Xor

A quick and dirty visualization of the DDA algorithm.
This was written for an upcoming tutorial on voxels:
mini.gmshaders.com

Cleaned up version of:
https://www.shadertoy.com/view/Mc3XD4
*/

//Max number of DDA steps
#define STEPS 30.0
//Scale with resolution
#define SCALE (10.0 / res.y)

//2D voxel bitmap
bool map(vec2 p)
{
    return dot(sin(p + vec2(1, 0)), cos(p.yx * 0.6)) > 0.8;
}

void main()
{
    //Resolution for scaling
    vec2 res = u_resolution.xy;
    //Scaled coordinates
    vec2 coord = gl_FragCoord.xy * SCALE;

    //Wandering target point
    vec2 wander = (cos(u_time / vec2(1, 0.7)) * 0.2 + 0.5) * res;
    //Start and end points that track the mouse
    vec2 p1 = wander * SCALE;
    vec2 p2 = u_mouse.xy * SCALE;

    //Ray direction
    vec2 dir = normalize(p2 - p1);
    //Prevent division by 0 errors
    dir += vec2(dir.x == 0.0, dir.y == 0.0) * 1e-5;

    //Sign direction for each axis
    vec2 sig = sign(dir);
    //Voxel step size for each axis
    vec2 stp = sig / dir;

    //Voxel position
    vec2 vox = floor(p1);
    //Initial step sizes to the next voxel
    vec2 dep = ((vox - p1 + 0.5) * sig + 0.5) * stp;
    //Adds small biases to minimize same depth conflicts (z-fighting)
    dep += vec2(0, 1) * 1e-4;

    //Voxel intersection point
    vec2 hit;
    //Axis selector (either vec2(1,0) or vec2(0,1))
    vec2 axi;
    //Output color, starting with map
    vec3 col = vec3(map(floor(coord))) * vec3(0.3, 0.3, 0.5);
    //Grid glow intensity
    vec2 edge = vec2(1);

    //Loop through voxels
    for(float i = 0.0; i < STEPS; i++)
    {
        //Stop if we hit a voxel
        if (map(vox)) break;
        //if (length(vox-floor(p2))<.5) break;

        //Select the next closest voxel axis
        axi = step(dep, dep.yx);
        //Compute intersection point
        hit = p1 + dot(dep, axi) * dir;
        //Step one voxel along this axis
        vox += sig * axi;
        //Set the length to the next voxel
        dep += stp * axi;

        //Draw glowing hit points
        col += vec3(axi, 0) * (clamp(0.5 * (0.1 - length(hit - coord)) / SCALE + 0.5, 0.0, 1.0)
        +0.2 * float(vox == floor(coord)));
        //Illuminate intersecting walls (ugly code!!)
        edge += axi * float(floor(coord - 0.5 * axi * sig) == floor(hit - 0.5 * axi * sig));

    }
    //Add glowing grid lines
    vec2 grid = max(edge-0.5 * abs(fract(coord + 0.5) - 0.5) / SCALE, 0.0);
    col.rg += grid;

    //Illuminate raycast line from p1 to hit point
    vec2 pa = coord - p1;
    vec2 ba = hit - p1;
    float line = length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
    col += vec3(0.3, 0.6, 1) * clamp(0.5 * (0.05 - line) / SCALE+0.5, 0.0, 1.0);
    col += clamp(0.5 * (0.15 - length(pa)) / SCALE+0.5, 0.0, 1.0);

    //Output with lazy color grading
    fragColor = vec4(col, 1);
}