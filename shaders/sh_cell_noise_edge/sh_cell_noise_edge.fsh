//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 dimension;
uniform vec2 position;
uniform float scale;
uniform float time;
uniform float contrast;
uniform float middle;
uniform float radiusScale;
uniform float radiusShatter;
uniform int pattern;

#define TAU 6.283185307179586
#define PI 3.14159265359

vec2 random2( vec2 p ) { return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453); }

float random (in vec2 st) { return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123); }

void main() {
	vec2 pos = position / dimension;
    vec2 st = v_vTexcoord - pos;

    st *= scale;

    float md = 1.;
    vec2 mg, mr;

	if(pattern == 0) {
		vec2 i_st = floor(st);
	    vec2 f_st = fract(st);
	
	    for (int y = -1; y <= 1; y++) {
	        for (int x = -1; x <= 1; x++) {
	            vec2 neighbor = vec2(float(x), float(y));
	            vec2 point = random2(mod(i_st + neighbor, scale));
				point += 0.5 + 0.5 * sin(time + TAU * point);
			
	            vec2 _diff = neighbor + point - f_st;
	            float dist = length(_diff);

	            if(dist < md) {
					md = dist;
					mr = _diff;
					mg = neighbor;
				}
	        }
	    }
		
		md = 1.;
		for(int y = -2; y <= 2; y++)
		for(int x = -2; x <= 2; x++) {
			vec2 g = mg + vec2(float(x), float(y));
			vec2 point = random2(mod(i_st + g, scale));
			point += 0.5 + 0.5 * sin(time + TAU * point);
		
			vec2 r = g + point - f_st;
			if(dot(mr - r, mr - r) > .000001)
				md = min( md, dot( 0.5 * (mr + r), normalize(r - mr)) );
		}
	} else if(pattern == 1) {
		for (int j = 0; j <= int(scale / 2.); j++) {
			int _amo = int(scale) + int(float(j) * radiusShatter);
			for (int i = 0; i <= _amo; i++) {
				float ang = TAU / float(_amo) * float(i) + float(j) + time;
				float rad = pow(float(j) / scale, radiusScale) * scale * .5 + random(vec2(ang)) * 0.1;
				vec2 neighbor = vec2(cos(ang) * rad, sin(ang) * rad);
				vec2 point = neighbor + pos;
				
			    vec2 _diff = point - v_vTexcoord;
			    float dist = length(_diff);
			    
				if(dist < md) {
					md = dist;
					mr = _diff;
					mg = neighbor;
				}
			}
		}
		
		md = 1.;
		for (int j = 0; j <= int(scale / 2.); j++) {
			int _amo = int(scale) + int(float(j) * radiusShatter);
			for (int i = 0; i <= _amo; i++) {
				float ang = TAU / float(_amo) * float(i) + float(j) + random(vec2(0.684, 1.387)) + time;
				float rad = pow(float(j) / scale, radiusScale) * scale * .5 + random(vec2(ang)) * 0.1;
				vec2 neighbor = vec2(cos(ang) * rad, sin(ang) * rad);
				vec2 point = neighbor + pos;
			
			    vec2 r = point - v_vTexcoord;
				if(dot(mr - r, mr - r) > .0001)
					md = min( md, dot( 0.5 * (mr + r), normalize(r - mr)) );
			}
		}
	}
	
	float c = middle + (md - middle) * contrast;
    gl_FragColor = vec4(vec3(c), 1.0);
}
