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

// SPDX-License-Identifier: CC0-1.0
// Copyright (c) Public domain
//[LICENSE] https://creativecommons.org/publicdomain/zero/1.0/

void main()
{
    //Normalized screen uvs [0, 1]
    vec2 uv = gl_FragCoord.xy / u_resolution;

    // uv is 0-1
    // left side of screen is 0.0, right side is 1.0
    // bottom is 0.0, top is 1.0
    // this is because gl_FragCoord.xy is the current pixel we are running on
    // uv is literally just currentPixelCoordinate / screenResolution

    // A vec3 has 3 components. RGB or XYZ
    vec3 theColorRed = vec3(1, 0, 0); // 1 in R (OR X) channel
    vec3 theColorBlue = vec3(0, 0, 1); // 1 in B (OR Z) channel
    vec3 theColorGreen = vec3(0, theColorRed.r, 0); // Inherit from the R channel of theColorRed

    // A vec is usually 2,3, or 4. The order goes as such: vec4(x,y,z,w) OR vec4(r,g,b,a)
    // You can access data from any channel in a vector in any order

    // Say you have:        R|X  G|Y  B|Z
    vec3 exampleVec3 = vec3(0.2, 0.4, 1.0);

    // You want to cast two components of that vec3 into a vec2
    vec2 exampleVec2 = exampleVec3.rb;
    // exampleVec2 is now the equivalent of vec2(exampleVec3.r, exampleVec3.b);
    // Which is the same as vec2(exampleVec3.x, exampleVec3.z);

    // We can put exampleVec3 inside of a vec4 because it has only 3 values and a vec4 takes 4
    // So to finish filling the data, we fit exampleVec3 which takes 3, then also a 1.0 which completes 4
    vec4 finalColor = vec4(exampleVec3, 1.0);

    vec3 theColorWhite = vec3(1, 1, 1); // OR vec3(1);

    // Try changing this to 0.5 or 2.0!
    float tryChangingMyValue = 1.0;

    // Mix function just mixes between two values of the same type. The mix factor is from 0.0 to 1.0
    //               vec4             also a vec4          mix factor
    finalColor = mix(finalColor, vec4(theColorWhite, 1.0), uv.y * tryChangingMyValue);

    //Output for demo
    fragColor = finalColor;
}