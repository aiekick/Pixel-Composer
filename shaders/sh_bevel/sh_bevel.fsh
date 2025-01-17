//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

#define TAU 6.283185307179586

uniform vec2  dimension;
uniform vec2  scale;
uniform vec2  shift;
uniform float height;
uniform int   slope;
uniform int   sampleMode;

float bright(in vec4 col) {
	return (col.r + col.g + col.b) / 3. * col.a;
}

vec4 sampleTexture(vec2 pos) {
	if(pos.x >= 0. && pos.y >= 0. && pos.x <= 1. && pos.y <= 1.)
		return texture2D(gm_BaseTexture, pos);
	
	if(sampleMode == 0) 
		return vec4(0.);
	if(sampleMode == 1) 
		return texture2D(gm_BaseTexture, clamp(pos, 0., 1.));
	if(sampleMode == 2) 
		return texture2D(gm_BaseTexture, fract(pos));
	
	return vec4(0.);
}

void main() {
	vec2 pixelStep = 1. / dimension;
    
    vec4 col = texture2D(gm_BaseTexture, v_vTexcoord);
	vec4 col1;
	gl_FragColor = col;
	bool done = false;
	
	vec2 shiftPx = -shift / dimension;
	float b0 = bright(col);
	float shift_angle    = atan(shiftPx.y, shiftPx.x);
	float shift_distance = length(shiftPx);
	float slope_distance = height * b0;
	float max_distance = height;
	
	if(b0 == 0.) return;
	
	float b1 = b0;
	float added_distance, _b1;
	vec2 shf, pxs;
	
	for(float i = 1.; i < height; i++) {
		float base = 1.;
		float top  = 0.;
		for(float j = 0.; j <= 64.; j++) {
			float ang = top / base * TAU;
			top += 2.;
			if(top >= base) {
				top = 1.;
				base *= 2.;
			}
			
			added_distance = 1. + cos(abs(shift_angle - ang)) * shift_distance;
				
			shf = vec2( cos(ang),  sin(ang)) * (i * added_distance) / scale;
			pxs = v_vTexcoord + shf * pixelStep;
				
			col1 = sampleTexture( pxs );
			_b1  = bright(col1);
				
			if(_b1 < b1) {
				slope_distance = min(slope_distance, i);
				max_distance = min(max_distance, (b0 - _b1) * height);
				b1 = min(b1, _b1);
				
				i = height;
				break;
			}
		}
	}
		
	if(max_distance == 0.)
		gl_FragColor = vec4(vec3(b0), col.a);
	else {
		float mx = slope_distance / max_distance;
		if(slope == 1)		mx = pow(mx, 3.) + 3. * mx * mx * (1. - mx);
		else if(slope == 2)	mx = sqrt(1. - pow(mx - 1., 2.));
		
		mx = clamp(mx, 0., 1.);
		float prg = mix(b1, b0, mx);
		gl_FragColor = vec4(vec3(prg), col.a);
	}
}
