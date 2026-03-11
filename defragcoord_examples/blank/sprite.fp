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

void main()
{
    //Normalized screen uvs [0, 1]
    vec2 uv = gl_FragCoord.xy / u_resolution;
    //Centered, fit screen coordinates
    vec2 fit = 0.5 + (gl_FragCoord.xy - 0.5 * u_resolution) / min(u_resolution.x, u_resolution.y);

    //Output for demo
    fragColor = vec4(fit, 0, 1);
}