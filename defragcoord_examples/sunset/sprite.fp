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
"Sunset" by @XorDev

Expanded and clarified version of my Sunset shader:
https://www.shadertoy.com/view/wXjSRt

Based on my tweet shader:
https://x.com/XorDev/status/1918764164153049480
*/

//Output image brightness
#define BRIGHTNESS 1.0  //[0.0, 2.0]

//Base brightness (higher = brighter, less saturated)
#define COLOR_BASE 1.5  //[0.5, 3.0]
//Color cycle speed (radians per second)
#define COLOR_SPEED 0.5  //[0.0, 2.0]
//RGB color phase shift (in radians)
#define RGB vec3(0.0, 1.0, 2.0)
//Color translucency strength
#define COLOR_WAVE 14.0  //[1.0, 30.0]
//Color direction and (magnitude = frequency)
#define COLOR_DOT vec3(1,-1,0)

//Wave iterations (higher = slower)
#define WAVE_STEPS 8.0  //[4.0, 16.0]
//Starting frequency
#define WAVE_FREQ 5.0  //[1.0, 20.0]
//Wave amplitude
#define WAVE_AMP 0.6  //[0.1, 2.0]
//Scaling exponent factor
#define WAVE_EXP 1.8  //[1.0, 3.0]
//Movement direction
#define WAVE_VELOCITY vec3(0.2)


//Cloud thickness (lower = denser)
#define PASSTHROUGH 0.2  //[0.0, 1.0]

//Cloud softness
#define SOFTNESS 0.005  //[0.001, 0.05]
//Raymarch step
#define STEPS 100.0  //[32.0, 256.0]
//Sky brightness factor (finicky)
#define SKY 10.0  //[1.0, 20.0]
//Camera fov ratio (tan(fov_y/2))
#define FOV 1.0  //[0.5, 2.0]

void main() {
    vec2 fragCoord = gl_FragCoord.xy;

    //Raymarch depth
    float z = 0.0;

    //Step distance
    float d = 0.0;
    //Signed distance
    float s = 0.0;

    //Ray direction
    vec3 dir = normalize( vec3(2.0*fragCoord - u_resolution.xy, - FOV * u_resolution.y));

    //Output color
    vec3 col = vec3(0);

    //Clear fragcolor and raymarch with 100 iterations
    for(float i = 0.0; i<STEPS; i++)
    {
        //Compute raymarch sample point
        vec3 p = z * dir;

        //Turbulence loop
        //https://www.shadertoy.com/view/3XXSWS
        for(float j = 0.0, f = WAVE_FREQ; j<WAVE_STEPS; j++, f *= WAVE_EXP)

        p += WAVE_AMP*sin(p*f - WAVE_VELOCITY*u_time).yzx / f;

        //Compute distance to top and bottom planes
        s = 0.3 - abs(p.y);
        //Soften and scale inside the clouds
        d = SOFTNESS + max(s, -s*PASSTHROUGH) / 4.0;
        //Step forward
        z += d;
        //Coloring with signed distance, position and cycle time
        float phase = COLOR_WAVE * s + dot(p,COLOR_DOT) + COLOR_SPEED*u_time;
        //Apply RGB phase shifts, add base brightness and correct for sky
        col += (cos(phase - RGB) + COLOR_BASE) * exp(s*SKY) / d;
    }
    //Tanh tonemapping
    //https://www.shadertoy.com/view/ms3BD7
    col *= SOFTNESS / STEPS * BRIGHTNESS;
    fragColor = vec4(tanh(col * col), 1.0);
}
