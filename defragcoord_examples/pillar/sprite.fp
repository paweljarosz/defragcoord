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

//Pillar scale
#define SCALE 0.15 //[0.1, 0.5]

//Pi constant for trig
#define pi 3.14159265359

void main()
{
    //Scaled coordinates
    vec2 p = gl_FragCoord.xy / min(u_resolution.x, u_resolution.y);
    //Scrolling coordinates
    vec2 scroll = p / SCALE + u_time * vec2(2.0 / pi, 1);
    //Signed columns
    float x = mod(scroll.x, 2.0) - 1.0;
    //Circular curves (cos for alternating directions)
    float curves = sqrt(1.0 - x * x) * cos(ceil(scroll.x * 0.5) * pi);
    //Sinewave coloring
    fragColor = sin(scroll.y - curves + vec4(0, 1, 2, 0));
}
