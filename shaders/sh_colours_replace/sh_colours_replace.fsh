//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec4 colorFrom[64];
uniform int  colorFromAmount;

uniform vec4 colorTo[64];
uniform int  colorToAmount;

uniform int  useMask;
uniform sampler2D mask;

void main() {
	vec4 p = texture2D( gm_BaseTexture, v_vTexcoord );
	
	int index = 0;
	float minDist = 999.;
	
	for(int i = 0; i < colorFromAmount; i++ ) {
		float dist = distance(p.rgb, colorFrom[i].rgb);
		if(dist < minDist) {
			minDist = dist;
			index = i;
		}
	}
	
    gl_FragColor = vec4(colorTo[index].rgb, p.a);
}
