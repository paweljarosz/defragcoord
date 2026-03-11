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
//[LICENSE] https://opensource.org/licenses/MIT

/*
"GM Shaders: Voxels" by @Xor

Voxel ray tracing demo for my voxel tutorial:
https://mini.gmshaders.com/p/voxels-draft
*/

//Max number of voxel steps
#define MAX 255.0

void main()
{
    vec2 frag_coord = gl_FragCoord.xy;

    //View rotation matrix (pitch rotation)
    mat3 view = mat3(1, 0, 0, 0, 0.8, 0.6, 0, - 0.6, 0.8);
    //Resolution for scaling
    vec2 res = u_resolution.xy;
    //Ray direction
    vec3 dir = normalize(vec3(res * 0.5 - frag_coord, res.y * 0.5)) * view;
    //Prevent division by 0 errors
    dir += vec3(dir.x == 0.0, dir.y == 0.0, dir.z == 0.0) * 1e-5;

    //Camera position with mouse control
    vec3 pos = vec3(u_mouse.xy - res.xy * 0.5, 0.0) / res.y * view * 16.0;
    //Scroll forward
    pos.z += u_time / 0.1;

    //Sign direction for each axis
    vec3 sig = sign(dir);
    //Step size for each axis
    vec3 stp = sig / dir;

    //Voxel position
    vec3 vox = floor(pos);
    //Initial step sizes to the next axis faces
    vec3 dep = ((vox - pos + 0.5) * sig + 0.5) * stp;

    //Axis index
    vec3 axi;

    //Loop iterator
    float steps = 0.0;
    //Loop through voxels
    for(float i = 0.0; i < MAX; i++)
    {
        //Check map
        if (dot(sin(vox * 0.13), cos(vox.yzx * 0.17)) + vox.y * 0.1 > 1.6) break;
        //Increment steps
        steps++;

        //Select the closest voxel face axis
        axi = dep.x < dep.z?
        ( dep.x < dep.y? vec3(1, 0, 0) : vec3(0, 1, 0) ):
        ( dep.z < dep.y? vec3(0, 0, 1) : vec3(0, 1, 0) );

        //Step one voxel along this axis
        vox += sig * axi;
        //Set the length to the next voxel
        dep += stp * axi;
    }
    //Here's how to get the normal and intersection point:
    //vec3 nor = sig * axi;
    //vec3 hit = pos + dir*dot(dep-stp, axi);

    //Apply shading 
    vec3 shade = mix(vec3(0.2, 0.2, 0.4), vec3(1), dot(axi, vec3(0, 1, 0.5)));
    //Pick a pseudo-random number for each block
    float noise = fract(cos(vox.x * 7.7 + vox.y * 8.9 + vox.z * 9.3) * 4e4);
    //Stratified color blended with noise
    vec3 col = cos(vox.y * vox.y - vox.y + vec3(0, 1, 2)) * 0.4 + 0.2 * noise+0.4;
    //Increase contrast and shade
    col *= col * shade;
    //Sky gradient
    vec3 sky = 1.0 + (dir.y - 1.0) * vec3(0.8, 0.6, 0.3);
    //Fade color with fog
    float fog = steps / MAX;
    col = mix(col, sky, fog * fog);
    //Output with a gamma of 2.0
    fragColor = vec4(sqrt(col), 1);
}