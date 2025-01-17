function Node_Erode(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name = "Erode";
	
	shader = sh_erode;
	uniform_dim   = shader_get_uniform(shader, "dimension");
	uniform_size  = shader_get_uniform(shader, "size");
	uniform_bor   = shader_get_uniform(shader, "border");
	uniform_alp   = shader_get_uniform(shader, "alpha");
	
	inputs[| 0] = nodeValue("Surface in", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 1] = nodeValue("Width", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 1);
	
	inputs[| 2] = nodeValue("Preserve border",self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, false);
	
	inputs[| 3] = nodeValue("Use alpha", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, false);
	
	inputs[| 4] = nodeValue("Mask", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 5] = nodeValue("Mix", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 1)
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[| 6] = nodeValue("Active", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, true);
		active_index = 6;
	
	inputs[| 7] = nodeValue("Channel", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0b1111)
		.setDisplay(VALUE_DISPLAY.toggle, { data: array_create(4, THEME.inspector_channel) });
	
	__init_mask_modifier(4); // inputs 8, 9, 
	
	input_display_list = [ 6, 7,
		["Surfaces", true], 0, 4, 5, 8, 9, 
		["Erode",	false], 1, 2, 3, 
	]
	
	outputs[| 0] = nodeValue("Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, noone);
	
	attribute_surface_depth();
	
	static step = function() { #region
		__step_mask_modifier();
	} #endregion
	
	static processData = function(_outSurf, _data, _output_index, _array_index) {
		var wd = _data[1];
		
		surface_set_target(_outSurf);
		DRAW_CLEAR
		BLEND_OVERRIDE;
		
		shader_set(shader);
			shader_set_uniform_f_array_safe(uniform_dim, [surface_get_width_safe(_data[0]), surface_get_height_safe(_data[0])]);
			shader_set_uniform_f(uniform_size, wd);
			shader_set_uniform_i(uniform_bor, _data[2]? 1 : 0);
			shader_set_uniform_i(uniform_alp, _data[3]? 1 : 0);
			draw_surface_safe(_data[0], 0, 0);
		shader_reset();
		
		BLEND_NORMAL;
		surface_reset_target();
		
		__process_mask_modifier(_data);
		_outSurf = mask_apply(_data[0], _outSurf, _data[4], _data[5]);
		_outSurf = channel_apply(_data[0], _outSurf, _data[7]);
		
		return _outSurf;
	}
}