//Shard noise
//By ENDESGA

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform float seed;
uniform float progress;
uniform float sharpness;
uniform vec2  u_resolution;
uniform vec2  position;
uniform vec2  scale;

#define tau 6.283185307179586

vec3 hash(vec3 p) { return fract(sin(vec3(
										dot(p, vec3(127.1324, 311.7874, 829.3683)) * (152.6178612 + seed / 10000.), 
										dot(p, vec3(269.8355, 183.3961, 614.5965)) * (437.5453123 + seed / 10000.),
										dot(p, vec3(615.2689, 264.1657, 278.1687)) * (962.6718165 + seed / 10000.)
									)) * 43758.5453); }

float shard_noise(in vec3 p, in float sharpness) {
    vec3 ip = floor(p);
    vec3 fp = fract(p);

    float v = 0., t = 0.;
	
    for (int z = -1; z <= 1; z++)
    for (int y = -1; y <= 1; y++)
    for (int x = -1; x <= 1; x++) {
        vec3 o = vec3(x, y, z);
        vec3 io = ip + o;
        vec3 h = hash(io);
        vec3 r = fp - (o + h);

        float w = exp2(-tau*dot(r, r));
		
        // tanh deconstruction and optimization by @Xor
        float s = sharpness * dot(r, hash(io + vec3(11, 31, 47)) - 0.5);
        v += w * s * inversesqrt(1.0 + s * s);
        t += w;
    }
	
    return ((v / t) * .5) + .5;
}

void main() {
	vec2 pos    = v_vTexcoord;
	     pos.x *= (u_resolution.x / u_resolution.y);
         pos    = (pos + position) * scale / 16.;
	
	float prog = progress / 100.;
    vec3 uv    = vec3( pos + prog, prog * .5 );
    
    gl_FragColor = vec4( vec3(shard_noise(16.0 * uv, pow(sharpness, 2.) * 20.)), 1. );
}