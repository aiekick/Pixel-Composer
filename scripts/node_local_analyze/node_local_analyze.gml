function Node_Local_Analyze(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name = "Local Analyze";
	
	shader = sh_local_analyze;
	uniform_dim = shader_get_uniform(shader, "dimension");
	uniform_alg = shader_get_uniform(shader, "algorithm");
	uniform_siz = shader_get_uniform(shader, "size");
	uniform_sha = shader_get_uniform(shader, "shape");
	uniform_sam = shader_get_uniform(shader, "sampleMode");
	
	inputs[| 0] = nodeValue("Surface in", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 1] = nodeValue("Algorithm", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Average (Blur)", "Maximum", "Minimum" ]);
	
	inputs[| 2] = nodeValue("Size", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 1)
		.setDisplay(VALUE_DISPLAY.slider, { range: [ 1, 16, 1] });
	
	inputs[| 3] = nodeValue("Oversample mode", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0, "How to deal with pixel outside the surface.\n    - Empty: Use empty pixel\n    - Clamp: Repeat edge pixel\n    - Repeat: Repeat texture.")
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Empty", "Clamp", "Repeat" ]);
	
	inputs[| 4] = nodeValue("Shape", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_scroll, [ "Square", "Circle", "Diamond" ]);
		
	inputs[| 5] = nodeValue("Mask", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 6] = nodeValue("Mix", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 1)
		.setDisplay(VALUE_DISPLAY.slider);
	
	inputs[| 7] = nodeValue("Active", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, true);
		active_index = 7;
	
	inputs[| 8] = nodeValue("Channel", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0b1111)
		.setDisplay(VALUE_DISPLAY.toggle, { data: array_create(4, THEME.inspector_channel) });
		
	__init_mask_modifier(5); // inputs 9, 10
	
	outputs[| 0] = nodeValue("Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, noone);
	
	input_display_list = [ 7, 8, 
		["Surfaces", true],	0, 5, 6, 9, 10, 
		["Effect",	false],	1, 2, 4,
	];
	
	attribute_surface_depth();
	attribute_oversample();
	
	static step = function() { #region
		__step_mask_modifier();
	} #endregion
	
	static processData = function(_outSurf, _data, _output_index, _array_index) {
		var _alg = _data[1];
		var _siz = _data[2];
		var _sam = struct_try_get(attributes, "oversample");
		var _shp = _data[4];
		
		surface_set_target(_outSurf);
		DRAW_CLEAR
		BLEND_OVERRIDE;
		
		shader_set(shader);
			shader_set_uniform_f(uniform_dim, surface_get_width_safe(_data[0]), surface_get_height_safe(_data[0]));
			shader_set_uniform_i(uniform_alg, _alg);
			shader_set_uniform_i(uniform_sam, _sam);
			shader_set_uniform_i(uniform_sha, _shp);
			shader_set_uniform_f(uniform_siz, _siz);
			draw_surface_safe(_data[0], 0, 0);
		shader_reset();
		
		BLEND_NORMAL;
		surface_reset_target();
		
		__process_mask_modifier(_data);
		_outSurf = mask_apply(_data[0], _outSurf, _data[5], _data[6]);
		_outSurf = channel_apply(_data[0], _outSurf, _data[8]);
		
		return _outSurf;
	}
}