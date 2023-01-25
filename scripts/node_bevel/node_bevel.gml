function Node_Bevel(_x, _y, _group = -1) : Node_Processor(_x, _y, _group) constructor {
	name = "Bevel";
	
	shader = sh_bevel;
	uniform_dim = shader_get_uniform(shader, "dimension");
	uniform_shf = shader_get_uniform(shader, "shift");
	uniform_sca = shader_get_uniform(shader, "scale");
	uniform_hei = shader_get_uniform(shader, "height");
	uniform_slp = shader_get_uniform(shader, "slope");
	
	inputs[| 0] = nodeValue(0, "Surface in", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	inputs[| 1] = nodeValue(1, "Height", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 4);
	
	inputs[| 2] = nodeValue(2, "Shift", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, 0 ])
		.setDisplay(VALUE_DISPLAY.vector);
	
	inputs[| 3] = nodeValue(3, "Scale", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 1, 1 ] )
		.setDisplay(VALUE_DISPLAY.vector);
	
	inputs[| 4] = nodeValue(4, "Slope", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Linear", "Smooth", "Circular" ]);
	
	outputs[| 0] = nodeValue(0, "Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, PIXEL_SURFACE);
	
	input_display_list = [
		["Surface",		 true], 0, 
		["Bevel",		false], 4, 1, 
		["Transform",	false], 2, 3, 
	];
	
	static process_data = function(_outSurf, _data, _output_index, _array_index) {
		var _hei = _data[1];
		var _shf = _data[2];
		var _sca = _data[3];
		var _slp = _data[4];
		
		surface_set_target(_outSurf);
			draw_clear_alpha(0, 0);
			BLEND_OVERRIDE
		
			shader_set(shader);
			shader_set_uniform_f(uniform_hei, _hei);
			shader_set_uniform_f_array(uniform_shf, _shf);
			shader_set_uniform_f_array(uniform_sca, _sca);
			shader_set_uniform_i(uniform_slp, _slp);
			shader_set_uniform_f_array(uniform_dim, [ surface_get_width(_data[0]), surface_get_height(_data[0]) ]);
			
			draw_surface_safe(_data[0], 0, 0);
			shader_reset();
			
			BLEND_NORMAL
		surface_reset_target();
		
		return _outSurf;
	}
}