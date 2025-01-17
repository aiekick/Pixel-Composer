function Node_Grid_Tri(_x, _y, _group = noone) : Node_Processor(_x, _y, _group) constructor {
	name = "Triangle Grid";
	
	shader = sh_grid_tri;
	uniform_pos = shader_get_uniform(shader, "position");
	uniform_dim = shader_get_uniform(shader, "dimension");
	uniform_sca = shader_get_uniform(shader, "scale");
	uniform_wid = shader_get_uniform(shader, "width");
	uniform_ang = shader_get_uniform(shader, "angle");
	uniform_mod = shader_get_uniform(shader, "mode");
	uniform_sed = shader_get_uniform(shader, "seed");
	
	uniform_grad_blend	= shader_get_uniform(shader, "gradient_blend");
	uniform_grad		= shader_get_uniform(shader, "gradient_color");
	uniform_grad_time	= shader_get_uniform(shader, "gradient_time");
	uniform_grad_key	= shader_get_uniform(shader, "gradient_keys");
	uniform_col_gap		= shader_get_uniform(shader, "gapCol");
	
	inputs[| 0] = nodeValue("Dimension", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, DEF_SURF )
		.setDisplay(VALUE_DISPLAY.vector);
	
	inputs[| 1] = nodeValue("Position", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 0, 0 ])
		.setDisplay(VALUE_DISPLAY.vector)
		.setUnitRef(function(index) { return getDimension(index); });
	
	inputs[| 2] = nodeValue("Scale", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, [ 2, 2 ])
		.setDisplay(VALUE_DISPLAY.vector);
	
	inputs[| 3] = nodeValue("Gap", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0.1)
		.setDisplay(VALUE_DISPLAY.slider, { range: [0, 0.5, 0.01] });
	
	inputs[| 4] = nodeValue("Angle", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, 0)
		.setDisplay(VALUE_DISPLAY.rotation);
		
	inputs[| 5] = nodeValue("Tile color", self, JUNCTION_CONNECT.input, VALUE_TYPE.gradient, new gradientObject(c_white) );
		
	inputs[| 6] = nodeValue("Gap color",  self, JUNCTION_CONNECT.input, VALUE_TYPE.color, c_black);
	
	inputs[| 7] = nodeValue("Texture", self, JUNCTION_CONNECT.input, VALUE_TYPE.surface, 0);
	
	inputs[| 8] = nodeValue("Render type", self, JUNCTION_CONNECT.input, VALUE_TYPE.integer, 0)
		.setDisplay(VALUE_DISPLAY.enum_scroll, ["Colored tile", "Height map", "Texture grid", "Texture sample"]);
		
	inputs[| 9] = nodeValue("Seed", self, JUNCTION_CONNECT.input, VALUE_TYPE.float, irandom_range(10000, 99999));
	
	input_display_list = [
		["Output",  false], 0,
		["Pattern",	false], 1, 4, 2, 3, 
		["Render",	false], 8, 9, 5, 6, 7
	];
	
	outputs[| 0] = nodeValue("Surface out", self, JUNCTION_CONNECT.output, VALUE_TYPE.surface, noone);
	
	attribute_surface_depth();
	
	static drawOverlay = function(active, _x, _y, _s, _mx, _my, _snx, _sny) {
		inputs[| 1].drawOverlay(active, _x, _y, _s, _mx, _my, _snx, _sny);
	}
	
	static processData = function(_outSurf, _data, _output_index, _array_index) {
		var _dim  = _data[0];
		var _pos  = _data[1];
		var _sca  = _data[2];
		var _wid  = _data[3];
		var _ang  = _data[4];
		var _sam  = _data[7];
		var _mode = _data[8];
		var _sed  = _data[9];
		
		var _col_gap = _data[6];
		var _gra	 = _data[5];
		
		var _grad = _gra.toArray();
		var _grad_color = _grad[0];
		var _grad_time	= _grad[1];
		
		inputs[| 5].setVisible(_mode == 0);
		inputs[| 6].setVisible(_mode != 1);
		inputs[| 7].setVisible(_mode == 2 || _mode == 3);
		
		_outSurf = surface_verify(_outSurf, _dim[0], _dim[1], attrDepth());
		
		surface_set_target(_outSurf);
		DRAW_CLEAR
		shader_set(shader);
			shader_set_uniform_f(uniform_pos, _pos[0] / _dim[0], _pos[1] / _dim[1]);
			shader_set_uniform_f(uniform_dim, _dim[0], _dim[1]);
			shader_set_uniform_f_array_safe(uniform_sca, _sca);
			shader_set_uniform_f(uniform_wid, _wid);
			shader_set_uniform_f(uniform_ang, degtorad(_ang));
			shader_set_uniform_f(uniform_sed, _sed);
			shader_set_uniform_i(uniform_mod, _mode);
			
			shader_set_uniform_f_array_safe(uniform_col_gap, colToVec4(_col_gap));
			
			shader_set_uniform_i(uniform_grad_blend, _gra.type);
			shader_set_uniform_f_array_safe(uniform_grad, _grad_color);
			shader_set_uniform_f_array_safe(uniform_grad_time, _grad_time);
			shader_set_uniform_i(uniform_grad_key, array_length(_gra.keys));
			
			if(is_surface(_sam))
				draw_surface_stretched_safe(_sam, 0, 0, _dim[0], _dim[1]);
			else
				draw_sprite_ext(s_fx_pixel, 0, 0, 0, _dim[0], _dim[1], 0, c_white, 1);
		shader_reset();
		surface_reset_target();
		
		return _outSurf;
	}
}