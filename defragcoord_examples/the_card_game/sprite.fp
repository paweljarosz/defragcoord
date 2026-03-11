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

#define PIXEL_SIZE_FAC 700.
#define SPIN_EASE 0.5

/* This example uses many custom uniforms, you can either define them in the material and use all of them as is:
uniform float spin_time; //0.68, [0, 1]
uniform float spin_amount; //0.385, [0, 1]
uniform float contrast; //3.5, [0, 10]
uniform vec4 colour_1; //0.8705882352941177, 0.26666666666666666, 0.23137254901960785, 1 [0, 1]
uniform vec4 colour_2; //0, 0.4196078431372549, 0.7019607843137254, 1 [0, 1]
uniform vec4 colour_3; //0.08627450980392157, 0.13725490196078433, 0.1411764705882353, 1 [0, 1]
uniform float lighting; //0.405, [0, 1]
*/

// But here, for simplicity, I just defined default values:
#define spin_time 0.68       // [0, 1]
#define spin_amount 0.385    // [0, 1]
#define contrast 3.5         // [0, 10]
#define colour_1 vec4(0.8705882352941177, 0.26666666666666666, 0.23137254901960785, 1) // [0, 1]
#define colour_2 vec4(0, 0.4196078431372549, 0.7019607843137254, 1)    // [0, 1]
#define colour_3 vec4(0.08627450980392157, 0.13725490196078433, 0.1411764705882353, 1) //[0, 1]
#define lighting 0.405       // [0, 1]

void main()
{
    // Convert to UV coords (0-1) and floor for pixel effect
    float pixel_size = length(u_resolution.xy) / PIXEL_SIZE_FAC;
    vec2 uv = (floor(gl_FragCoord.xy * (1. / pixel_size)) * pixel_size - 0.5 * u_resolution.xy) / length(u_resolution.xy);
    float uv_len = length(uv);

    // Adding in a center swirl, changes with time. Only applies meaningfully if the 'spin amount' is a non-zero number
    float speed = (spin_time * u_time * SPIN_EASE * 0.2) + 302.2;
    float new_pixel_angle = (atan(uv.y, uv.x)) + speed - SPIN_EASE * 20. * (1. * spin_amount * uv_len + (1. - 1. * spin_amount));
    vec2 mid = (u_resolution.xy / length(u_resolution.xy)) / 2.;
    uv = (vec2((uv_len * cos(new_pixel_angle) + mid.x), (uv_len * sin(new_pixel_angle) + mid.y)) - mid);

    // Now add the paint effect to the swirled UV
    uv *= 30.;
    speed = u_time * (2.);
    vec2 uv2 = vec2(uv.x + uv.y);

    for (int i = 0; i < 5; i++) {
        uv2 += sin(max(uv.x, uv.y)) + uv;
        uv  += 0.5 * vec2(cos(5.1123314 + 0.353 * uv2.y + speed * 0.131121), sin(uv2.x - 0.113 * speed));
        uv  -= 1.0 * cos(uv.x + uv.y) - 1.0 * sin(uv.x * 0.711 - uv.y);
    }

    // Make the paint amount range from 0 - 2
    float contrast_mod = (0.25 * contrast + 0.5 * spin_amount + 1.2);
    float paint_res = min(2., max(0., length(uv) * (0.035) * contrast_mod));
    float c1p = max(0., 1. - contrast_mod * abs(1. - paint_res));
    float c2p = max(0., 1. - contrast_mod * abs(paint_res));
    float c3p = 1. - min(1., c1p + c2p);
    float light = (lighting - 0.2) * max(c1p * 5. - 4., 0.) + lighting * max(c2p * 5. - 4., 0.);

    fragColor = (0.3 / contrast) * colour_1 + (1. - 0.3 / contrast) * (colour_1 * c1p + colour_2 * c2p + vec4(c3p * colour_3.rgb, c3p * colour_1.a)) + vec4(light);
}