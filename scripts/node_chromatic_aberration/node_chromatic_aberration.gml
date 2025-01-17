function Node_Chromatic_Aberration(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name = "Chromatic Aberration";
	
	shader = sh_chromatic_aberration;
	uniform_dim = shader_get_uniform(shader, "dimension");
	uniform_cen = shader_get_uniform(shader, "center");
	uniform_str = shader_get_uniform(shader, "strength");
	
	inputs[| 0] = nodeValue("Surface in", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 1] = nodeValue("Center", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0.5, 0.5 ])
		.setDisplay(VALUE_DISPLAY.vector)
		.setUnitRef(function(index) { return getDimension(index); }, VALUE_UNIT.reference);
	
	inputs[| 2] = nodeValue("Strength", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 1)
		.setDisplay(VALUE_DISPLAY.slider, { range: [-16, 16, 0.01] });
	
	inputs[| 3] = nodeValue("Active", self, JUNCTION_CONNECT.input, VALUE_TYPE.boolean, true);
		active_index = 3;
	
	outputs[| 0] = nodeValue("Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, noone);
	
	attribute_surface_depth();
	attribute_interpolation();
	
	static drawOverlay = function(active, _x, _y, _s, _mx, _my, _snx, _sny) {
		var pos = getInputData(1);
		var px = _x + pos[0] * _s;
		var py = _y + pos[1] * _s;
		
		inputs[| 1].drawOverlay(active, _x, _y, _s, _mx, _my, _snx, _sny);
	}
	
	static processData = function(_outSurf, _data, _output_index, _array_index) {
		var center = _data[1];
		var stren  = _data[2];
		
		surface_set_shader(_outSurf, shader);
		shader_set_interpolation(_data[0]);
			shader_set_uniform_f_array_safe(uniform_dim, [ surface_get_width_safe(_data[0]), surface_get_height_safe(_data[0]) ]);
			shader_set_uniform_f_array_safe(uniform_cen, center);
			shader_set_uniform_f(uniform_str, stren);
			draw_surface_safe(_data[0], 0, 0);
		surface_reset_shader();
		
		return _outSurf;
	}
}