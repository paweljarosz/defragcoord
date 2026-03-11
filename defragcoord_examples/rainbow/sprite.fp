#version 140

in mediump vec2 var_texcoord0;

out vec4 out_fragColor;

uniform mediump sampler2D texture_sampler;
uniform fs_uniforms
{
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
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 resolution = max(u_resolution, vec2(1.0));
    vec2 uv = fragCoord / resolution;

    float phase = 2.0 * u_time + 10.0 * uv.x + 6.0 * uv.y + 0.25 * u_scroll;
    vec3 flow = 0.5 + 0.5 * sin(phase + vec3(0.0, 2.094, 4.188));

    vec4 base = texture(texture_sampler, var_texcoord0);
    fragColor = vec4(base.rgb * flow, base.a);
}
