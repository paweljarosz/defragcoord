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

/*
"Nova" by @XorDev

I am starting a new series of mini, lightweight shaders
made for easy learning and high-performance applications
https://www.shadertoy.com/playlist/ccffz7

MIT license
Credit is appreciated, but not required!

The idea is simple
1) Normalize the screen coordinates and center vertically
2) Compute the distance to the circle edge
3) Calculate the coloring with an RGB sine wave
iq's Palettes: https://www.shadertoy.com/view/ll2GD3
4) Divide by the distance to the edge
5) Tonemap with tanh
Intro to tonemapping: https://mini.gmshaders.com/p/tonemaps

*/

//Circle radius
#define RADIUS 0.6 //[0.0, 1.0]
void main()
{
    //Horizontally centered and scaled coordinates
    vec2 p = (2.0*gl_FragCoord.xy-u_resolution.x) / min(u_resolution.x, u_resolution.y);
    //Centered version:
    //vec2 p = (2.0*gl_FragCoord.xy-u_resolution.xy) / min(u_resolution.x, u_resolution.y);

    //Distance to circle edge
    float l = RADIUS - length(p);

    //Tanh tonemapping
    //https://www.shadertoy.com/view/ms3BD7
    //Uses a sine wave with RGB phase shifting for coloring
    //The 1.2 makes the color range from 0.2 to 2.2
    //Then the lightness is divided by the distance to the edge
    //Uses a faster rate for the inside to create the eclipse
    fragColor = tanh((1.2 + sin(p.x+u_time+vec4(0,2,4,0))) * 0.1 / max(l/0.1,-l));
}
