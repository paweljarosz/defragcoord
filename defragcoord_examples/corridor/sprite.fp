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

// SPDX-License-Identifier: CC-BY-4.0
// Copyright (c) 2026 @altunenes
//[LICENSE] https://creativecommons.org/licenses/by/4.0/

//shading tricks/insights:
//for point lighting/attenuation: Shane (shadertoy)
//tanh approx mrrange (shadertoy)

#define T u_time
#define R u_resolution.xy
#define M(a) mat2(cos(a), cos((a)+11.), cos((a)+33.), cos(a))
#define P(x,y) pow(abs(x),y)
#define X(a,b) max(dot(a,b),0.)
#define n(p) (sin((p).x*4.+sin((p).y*3.1))*cos((p).y*1.3+cos((p).x*2.7)))

float map(vec3 p, out float mID) {
    p.xy *= M(p.z*.2 + sin(T*.1)*.5);
    float N = n(p.xy + .2);

    vec3 f = abs(fract(p) - .5);
    float d1 = length(f.xy) - .08 + N*.04,
    d2 = length(f.xz) - .12 + N*.03,
    d3 = max(f.x, f.y) - .15 + sin(N)*.1,
    d  = min(d1, min(d2, d3));

    mID = d==d1 ? 1. : (d==d2 ? 2. : 3.);
    return d * .6; 
}

float map(vec3 p) { float d; return map(p,d); }

vec3 N(vec3 p, float t) {
    vec2 e = vec2(1e-3 + t*1e-4, 0); 
    return normalize(vec3(map(p+e.xyy)-map(p-e.xyy), map(p+e.yxy)-map(p-e.yxy), map(p+e.yyx)-map(p-e.yyx)));
}

float AO(vec3 p, vec3 n) {
    float o=0., s=1., h;
    for(float i=0.; i++<5.; s*=.75) {
        h = .01 + .05*i; 
        o += (h - map(p + h*n)) * s;
    }
    return max(1. - 3.*o, 0.);
}

float SH(vec3 ro, vec3 rd, float mx) {
    float r=1., t=.05, h;
    for(int i=0; i++<48;) {
        h = map(ro + rd*t);
        r = min(r, max(64.*h/t, 0.));
        t += max(.01, abs(h)); 
        if(r<1e-3 || t>mx) break; 
    }
    return max(r, .1);
}

void main() {
    vec2 C = gl_FragCoord.xy;

    vec2 uv = (C - .5*R) / R.y;
    vec3 ro = vec3(0, 0, T*1.2), rd = normalize(vec3(uv, 1.)),
    bg = vec3(1,2,3)*.01, col = bg,
    p, al;

    float t=0., d, mID, gl=0.;
    for(int i=0; i++<150;) {
        p = ro + rd*t;
        d = map(p, mID);
        gl += 2e-3 / (.01 + abs(d)); 
        if(abs(d)<1e-3 || t>25.) break;
        t += d;
    }

    if(t < 25.) {
        vec3 nn = N(p, t), v = -rd, q = p;
        q.xy *= M(q.z*.2 + sin(T*.1)*.5);
        //tanh approximation: mrange ("Saturday Torus" - https://www.shadertoy.com/view/fd33zn)
        float nv = n(q.xy + T*.15),
        sh = clamp(nv*(27.+nv*nv)/(27.+9.*nv*nv), -1., 1.) * .5 + .5,
        go, sm;

        if (mID == 1.) {
            al = mix(vec3(2,10,20)*.01, .5+.5*cos(vec3(0,1.5,2.5)+X(nn,v)*4.-T*.5), sh*.8);
            go = mix(20., 80., sh); sm = 1.5;
        } else if (mID == 2.) {
            al = mix(vec3(30,2,5)*.01, vec3(100,40,15)*.01, sh);
            go = mix(64., 256., sh); sm = 4.;
        } else {
            al = mix(vec3(5,4,2)*.01, vec3(50,40,20)*.01, sh);
            go = mix(8., 24., sh); sm = .4;
        }
        // point lighting/attenuation: Shane               
        // I don't remember the exact shader :-(, but I saved it on my notes as from Shane
            vec3 lp1 = ro + vec3(sin(T*1.2)*.2, cos(T*.9)*.2, 3.5),
            lp2 = ro + vec3(0, 0, .5),
            ld1 = lp1 - p, ld2 = lp2 - p;

            float lD1 = max(length(ld1), 1e-3), lD2 = max(length(ld2), 1e-3);
            ld1 /= lD1; ld2 /= lD2;

            float at1 = 1. / (1. + lD1*.125 + lD1*lD1*.05),
            at2 = 1. / (1. + lD2*.1   + lD2*lD2*.05),
            ao = AO(p, nn),
            shd = SH(p, ld1, lD1);

            vec3 lc1 = vec3(1.2, .9, .6), lc2 = vec3(0),
            sub = al * lc1 * smoothstep(0., 1., map(p + ld1*.2)*5.) * (mID==2. ? 1. : .2) * at1 * (1. - shd*.5);

            col = al * vec3(15,20,25)*.01 * ao 
            + (al * (X(nn, ld1)*.7+.7) + vec3(.8,.9,1) * P(X(reflect(-ld1, nn), v), go) * sm) * lc1 * shd * at1 
            + al * (dot(nn, ld2)*.5+.5) * lc2 * at2 * 4. 
            + sub 
            + al * lc2 * P(clamp(1.-dot(nn, v), 0., 1.), 4.) * ao * 1.5;
        }

        col += vec3(1,3,5)*.01 * gl * .015;
        col = mix(col, bg, 1. - 1./exp(t*t * .0096));

        col = P(clamp((col*(2.51*col+.03))/(col*(2.43*col+.59)+.14), 0., 1.), vec3(.4545));

        uv = C / R;
        fragColor = vec4(col * (.5 + .5 * P(16.*uv.x*uv.y*(1.-uv.x)*(1.-uv.y), .25)), 1);
    }
