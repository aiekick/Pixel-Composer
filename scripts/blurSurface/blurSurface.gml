globalvar GAUSSIAN_COEFF;
GAUSSIAN_COEFF = {};

function surface_blur_init() {
	__blur_hori = surface_create(1, 1);
	__blur_vert = surface_create(1, 1);
}

function __gaussian_get_kernel(size) {
	size = max(1, round(size));
	if(struct_has(GAUSSIAN_COEFF, size)) return GAUSSIAN_COEFF[$ size];
	
	var gau_array = array_create(size);
	var we = 0;
	var b  = 0.3 * ((size - 1) * 0.5 - 1) + 0.8;
	for(var i = 0; i < size; i++) {
		var _x = i * .5;
		
		gau_array[i] = (1 / sqrt(2 * pi * b)) * exp( -sqr(_x) / (2 * sqr(b)) );
		we += i? gau_array[i] * 2 : gau_array[i];
	}
	
	for(var i = 0; i < size; i++)
		gau_array[i] /= we;
	
	GAUSSIAN_COEFF[$ size] = gau_array;
	return gau_array;
}

function surface_apply_gaussian(surface, size, bg = false, bg_c = c_white, sampleMode = 0, overColor = noone) {
	static uni_bor = shader_get_uniform(sh_blur_gaussian, "sampleMode");
	static uni_dim = shader_get_uniform(sh_blur_gaussian, "dimension");
	static uni_hor = shader_get_uniform(sh_blur_gaussian, "horizontal");
	static uni_wei = shader_get_uniform(sh_blur_gaussian, "weight");
	static uni_sze = shader_get_uniform(sh_blur_gaussian, "size");
	static uni_ovr = shader_get_uniform(sh_blur_gaussian, "overrideColor");
	static uni_ovc = shader_get_uniform(sh_blur_gaussian, "overColor");
	
	var format = surface_get_format(surface)
	__blur_hori = surface_verify(__blur_hori, surface_get_width_safe(surface), surface_get_height_safe(surface), format);	
	__blur_vert = surface_verify(__blur_vert, surface_get_width_safe(surface), surface_get_height_safe(surface), format);	
	
	size = min(size, 128);
	var gau_array = __gaussian_get_kernel(size);
	
	BLEND_OVERRIDE;
	gpu_set_tex_filter(true);
	surface_set_target(__blur_hori);
		draw_clear_alpha(bg_c, bg);
		
		shader_set(sh_blur_gaussian);
		shader_set_uniform_f_array_safe(uni_dim, [ surface_get_width_safe(surface), surface_get_height_safe(surface) ]);
		shader_set_uniform_f_array_safe(uni_wei, gau_array);
		
		shader_set_uniform_i(uni_bor, sampleMode);
		shader_set_uniform_i(uni_sze, size);
		shader_set_uniform_i(uni_hor, 1);
		
		shader_set_uniform_i(uni_ovr, overColor != noone);
		shader_set_uniform_f_array_safe(uni_ovc, colToVec4(overColor));
		
		draw_surface_safe(surface, 0, 0);
		shader_reset();
	surface_reset_target();
	
	surface_set_target(__blur_vert);
		draw_clear_alpha(bg_c, bg);
		
		shader_set(sh_blur_gaussian);
		shader_set_uniform_i(uni_hor, 0);
		
		draw_surface_safe(__blur_hori, 0, 0);
		shader_reset();
	surface_reset_target();
	gpu_set_tex_filter(false);
	BLEND_NORMAL;
	
	return __blur_vert;
}