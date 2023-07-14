function shader_set_i(uniform, value) {
	var shader = shader_current();
	if(is_array(value)) {
		shader_set_i_array(shader, uniform, value);
		return;
	}
		
	if(argument_count > 2) {
		var array = [];
		for( var i = 1; i < argument_count; i++ )
			array_push(array, argument[i]);
		shader_set_i_array(shader, uniform, array)
		return;
	}
	
	shader_set_uniform_i(shader_get_uniform(shader, uniform), value);
}

function shader_set_i_array(shader, uniform, array) {
	shader_set_uniform_i_array(shader_get_uniform(shader, uniform), array);
}

function shader_set_f(uniform, value) {
	var shader = shader_current();
	if(is_array(value)) {
		shader_set_f_array(shader, uniform, value);
		return;
	}
		
	if(argument_count > 2) {
		var array = [];
		for( var i = 1; i < argument_count; i++ )
			array_push(array, argument[i]);
		shader_set_f_array(shader, uniform, array)
		return;
	}
	
	shader_set_uniform_f(shader_get_uniform(shader, uniform), value);
}

function shader_set_f_array(shader, uniform, array) {
	shader_set_uniform_f_array(shader_get_uniform(shader, uniform), array);
}

function shader_set_uniform_f_array_safe(uniform, array) {
	if(!is_array(array)) return;
	if(array_length(array) == 0) return;
	
	shader_set_uniform_f_array(uniform, array);
}

function shader_set_surface(sampler, surface) {
	var shader = shader_current();
	if(!is_surface(surface)) return;
	
	var t = shader_get_sampler_index(shader, sampler);
	texture_set_stage(t, surface_get_texture(surface));
}

function shader_set_surface_dimension(uniform, surface) {
	var shader = shader_current();
	if(!is_surface(surface)) return;
	
	var texture = surface_get_texture(surface);
	var tw = texture_get_texel_width(texture);
	var th = texture_get_texel_height(texture);
	
	tw = 2048;
	th = 2048;
	
	shader_set_uniform_f(shader_get_uniform(shader, uniform), tw, th);
}

#region prebuild
	enum BLEND {
		normal,
		add,
		over,
		alpha,
		alphamulp,
	}

	function shader_set_interpolation(surface) {
		var intp   = struct_try_get(attributes, "interpolation", 0);
		
		gpu_set_tex_filter(intp);
		shader_set_i("interpolation", intp);
		shader_set_f("sampleDimension", surface_get_width(surface), surface_get_height(surface));
	}
	
	function surface_set_shader(surface, shader = sh_sample, clear = true, blend = BLEND.over) {
		if(!is_surface(surface)) {
			__surface_set = false;
			return;
		}
		
		__surface_set = true;
		surface_set_target(surface);
		if(clear) DRAW_CLEAR;
		
		switch(blend) {
			case BLEND.add :		BLEND_ADD;			break;
			case BLEND.over:		BLEND_OVERRIDE;		break;
			case BLEND.alpha:		BLEND_ALPHA;		break;
			case BLEND.alphamulp:	BLEND_ALPHA_MULP;	break;
		}
		
		if(shader == noone)
			__shader_set = false;
		else {
			__shader_set = true;
			shader_set(shader);
		}
	}
	
	function surface_reset_shader() {
		if(!__surface_set) return;
		
		gpu_set_tex_filter(false);
		BLEND_NORMAL;
		surface_reset_target();
		
		if(__shader_set)
			shader_reset();
	}
#endregion